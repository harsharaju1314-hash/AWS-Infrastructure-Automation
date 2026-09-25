import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# Add parent directory to path to import validate
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts")))
import validate


class TestValidateScript(unittest.TestCase):

    @patch("socket.create_connection")
    def test_check_tcp_reachability_success(self, mock_create_connection):
        mock_sock = MagicMock()
        mock_create_connection.return_value.__enter__.return_value = mock_sock

        result = validate.check_tcp_reachability("127.0.0.1", 80, timeout=2)
        self.assertTrue(result)

    @patch("socket.create_connection", side_effect=OSError("Connection refused"))
    def test_check_tcp_reachability_failure(self, mock_create_connection):
        result = validate.check_tcp_reachability("127.0.0.1", 80, timeout=2)
        self.assertFalse(result)

    @patch("urllib.request.urlopen")
    def test_check_http_endpoint_success(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = b"<html>AWS Infrastructure Automation</html>"
        mock_urlopen.return_value.__enter__.return_value = mock_response

        success, status, body = validate.check_http_endpoint(
            url="http://127.0.0.1/",
            expected_status=200,
            expected_keyword="AWS Infrastructure Automation",
        )
        self.assertTrue(success)
        self.assertEqual(status, 200)
        self.assertIn("AWS Infrastructure Automation", body)

    @patch("urllib.request.urlopen")
    def test_check_http_endpoint_keyword_missing(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.getcode.return_value = 200
        mock_response.read.return_value = b"<html>Welcome to Nginx</html>"
        mock_urlopen.return_value.__enter__.return_value = mock_response

        success, status, msg = validate.check_http_endpoint(
            url="http://127.0.0.1/",
            expected_status=200,
            expected_keyword="AWS Infrastructure Automation",
        )
        self.assertFalse(success)
        self.assertIn("Keyword", msg)

    @patch("validate.check_http_endpoint")
    @patch("validate.check_tcp_reachability")
    def test_run_validation_all_pass(self, mock_tcp, mock_http):
        mock_tcp.return_value = True
        mock_http.side_effect = [
            (True, 200, "AWS Infrastructure Automation"),
            (True, 200, '{"status": "UP"}'),
        ]

        exit_code = validate.run_validation(
            host="127.0.0.1",
            port=80,
            retries=1,
            delay=0,
            timeout=1,
        )
        self.assertEqual(exit_code, 0)


if __name__ == "__main__":
    unittest.main()
