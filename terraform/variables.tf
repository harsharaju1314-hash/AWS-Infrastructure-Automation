# Input Variables for AWS Infrastructure Provisioning

variable "aws_region" {
  description = "The AWS Region where all resources will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Prefix used for naming resources across this project."
  type        = string
  default     = "aws-infra-automation"
}

variable "vpc_cidr" {
  description = "The CIDR block for the custom VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet."
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance size for the web application host."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing AWS Key Pair for SSH access. Leave empty if using SSM Session Manager or auto-generated keys."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block permitted for SSH access. In production, restrict this to your specific IP (e.g. '203.0.113.4/32')."
  type        = string
  default     = "0.0.0.0/0"
}
