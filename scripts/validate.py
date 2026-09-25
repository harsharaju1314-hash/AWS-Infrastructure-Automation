#!/usr/bin/env python3
"""
Infrastructure & Application Health Validation Utility

This script validates that an AWS EC2 instance is reachable, its web server
is operational, and the deployed application responds with the expected HTTP status
and content payload.

Features:
  - Zero external dependencies (uses standard library: socket, urllib, argparse)
  - Configurable retries and timeouts for post-provisioning stabilization
  - Clear, human-readable terminal output
  - Standardized exit codes for CI/CD automation

Exit Codes:
  0: All checks passed successfully
  1: Network / Socket connection failure (Port unreachable)
  2: HTTP Status Code mismatch (e.g. 500 or 404 instead of 200)
  3: Payload / Body content validation failure
  4: Invalid arguments or general runtime error
"""

import argparse
import json
import socket
import sys
import time
import urllib.error
import urllib.request


def print_banner():
    print("=" * 60)
    print(" AWS Infrastructure Automation - Deployment Validator")
    print("=" * 60)


def check_tcp_reachability(host: str, port: int, timeout: int = 5) -> bool:
    """Check if the given host and port are accepting TCP connections."""
    print(f"[*] Checking TCP reachability on {host}:{port} ...", end=" ", flush=True)
    try:
        with socket.create_connection((host, port), timeout=timeout):
            print("[PASS]")
            return True
    except (socket.timeout, socket.error, OSError) as err:
        print(f"[FAIL] ({err})")
        return False


def check_http_endpoint(
    url: str,
    expected_status: int = 200,
    expected_keyword: str = None,
    timeout: int = 5,
) -> tuple[bool, int, str]:
    """
    Perform an HTTP GET request to validate status code and expected response body.
    Returns: (is_success, status_code, response_body)
    """
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "DevOps-Validator/1.0"},
    )

    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            status = response.getcode()
            body = response.read().decode("utf-8", errors="replace")

            if status != expected_status:
                return False, status, f"Expected HTTP {expected_status}, received {status}"

            if expected_keyword and expected_keyword not in body:
                return (
                    False,
                    status,
                    f"Keyword '{expected_keyword}' not found in response body",
                )

            return True, status, body

    except urllib.error.HTTPError as err:
        return False, err.code, f"HTTP Error {err.code}: {err.reason}"
    except urllib.error.URLError as err:
        return False, 0, f"URL Error: {err.reason}"
    except Exception as err:
        return False, 0, f"Unexpected error: {err}"


def run_validation(
    host: str,
    port: int = 80,
    endpoint: str = "/",
    health_endpoint: str = "/healthz",
    expected_status: int = 200,
    expected_keyword: str = None,
    retries: int = 6,
    delay: int = 5,
    timeout: int = 5,
) -> int:
    """
    Orchestrate full validation suite with retry mechanisms.
    Returns the appropriate exit code.
    """
    print_banner()
    print(f" Target Host:       {host}")
    print(f" Target Port:       {port}")
    print(f" Main Endpoint:     http://{host}:{port}{endpoint}")
    print(f" Health Endpoint:   http://{host}:{port}{health_endpoint}")
    print(f" Max Retries:       {retries} (Interval: {delay}s, Timeout: {timeout}s)")
    print("-" * 60)

    # 1. TCP Connectivity Check with Retries
    tcp_ok = False
    for attempt in range(1, retries + 1):
        if check_tcp_reachability(host, port, timeout):
            tcp_ok = True
            break
        if attempt < retries:
            print(f"    -> Retrying connection in {delay} seconds (attempt {attempt}/{retries})...")
            time.sleep(delay)

    if not tcp_ok:
        print("\n[ERROR] TCP connection failed. Ensure Security Group rules and EC2 instance are active.")
        return 1

    # 2. Main Web Page Check
    main_url = f"http://{host}:{port}{endpoint}"
    print(f"\n[*] Validating Main Web Application ({main_url}) ...")
    main_ok, status, details = check_http_endpoint(
        url=main_url,
        expected_status=expected_status,
        expected_keyword=expected_keyword,
        timeout=timeout,
    )

    if not main_ok:
        print(f"[FAIL] Main application validation failed: {details}")
        if status != expected_status:
            return 2
        return 3

    print(f"[PASS] Main application returned HTTP {status} successfully.")

    # 3. Dedicated Health Endpoint Check
    health_url = f"http://{host}:{port}{health_endpoint}"
    print(f"\n[*] Validating Health Endpoint ({health_url}) ...")
    health_ok, health_status, health_body = check_http_endpoint(
        url=health_url,
        expected_status=200,
        expected_keyword="UP",
        timeout=timeout,
    )

    if not health_ok:
        print(f"[FAIL] Health endpoint check failed: {health_body}")
        return 2

    print(f"[PASS] Health endpoint responded with HTTP {health_status}.")
    try:
        parsed_json = json.loads(health_body)
        print("    -> Parsed Health JSON Payload:")
        for k, v in parsed_json.items():
            print(f"       - {k}: {v}")
    except json.JSONDecodeError:
        print(f"    -> Raw Health Response: {health_body.strip()}")

    print("\n" + "=" * 60)
    print(" [SUCCESS] Infrastructure and Application Deployment Validated!")
    print("=" * 60)
    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Validate AWS Infrastructure & Web Application Deployment",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-H", "--host",
        required=True,
        help="Public IP address or domain name of the EC2 instance",
    )
    parser.add_argument(
        "-p", "--port",
        type=int,
        default=80,
        help="Target port for HTTP connection",
    )
    parser.add_argument(
        "-e", "--endpoint",
        default="/",
        help="Application web root endpoint",
    )
    parser.add_argument(
        "--health-endpoint",
        default="/healthz",
        help="Dedicated healthcheck endpoint path",
    )
    parser.add_argument(
        "-s", "--expected-status",
        type=int,
        default=200,
        help="Expected HTTP status code",
    )
    parser.add_argument(
        "-k", "--expected-keyword",
        default="AWS Infrastructure Automation",
        help="Expected keyword/string present in application HTML",
    )
    parser.add_argument(
        "-r", "--retries",
        type=int,
        default=6,
        help="Number of retry attempts before giving up",
    )
    parser.add_argument(
        "-d", "--delay",
        type=int,
        default=5,
        help="Delay in seconds between retry attempts",
    )
    parser.add_argument(
        "-t", "--timeout",
        type=int,
        default=5,
        help="Socket and HTTP timeout in seconds",
    )

    args = parser.parse_args()

    exit_code = run_validation(
        host=args.host,
        port=args.port,
        endpoint=args.endpoint,
        health_endpoint=args.health_endpoint,
        expected_status=args.expected_status,
        expected_keyword=args.expected_keyword,
        retries=args.retries,
        delay=args.delay,
        timeout=args.timeout,
    )
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
