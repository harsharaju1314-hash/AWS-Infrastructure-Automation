# Output Definitions for Provisioned AWS Infrastructure

output "vpc_id" {
  description = "The ID of the custom VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the public subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "The ID of the web security group."
  value       = aws_security_group.web_sg.id
}

output "instance_id" {
  description = "The EC2 instance ID."
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IPv4 address of the deployed EC2 web server."
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance."
  value       = aws_instance.web.public_dns
}

output "app_url" {
  description = "Direct HTTP URL to access the deployed web application."
  value       = "http://${aws_instance.web.public_ip}"
}

output "ssh_connection_command" {
  description = "Sample SSH command to connect to the instance."
  value       = "ssh -i <path-to-private-key.pem> ubuntu@${aws_instance.web.public_ip}"
}

output "ansible_inventory_line" {
  description = "Line ready to be added into Ansible inventory file."
  value       = "${aws_instance.web.public_ip} ansible_user=ubuntu"
}
