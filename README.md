# AWS Infrastructure Automation

## Overview

This project provides an automated, reproducible pipeline to provision, configure, and validate an AWS-hosted Linux web application environment. It uses Terraform for Infrastructure as Code (IaC), Ansible for configuration management, a custom Python CLI utility for post-deployment health validation, and GitHub Actions for continuous integration and deployment.

---

## Problem Statement

Manual cloud resource provisioning and server configuration introduce human error, configuration drift, and inconsistent environments across development and production stages. Setting up servers by hand also slows down deployments and makes troubleshooting difficult.

This project solves these issues by:
- Defining repeatable AWS infrastructure using declarative Terraform code.
- Automating OS-level package installation, service setup, and firewall configuration using Ansible.
- Programmatically verifying network reachability and application health using a dedicated Python validation tool.
- Automating syntax checks, linting, planning, and deployment through a CI/CD pipeline.

---

## Key Features

- **Automated VPC & Network Setup**: Creates a dedicated Virtual Private Cloud (VPC), public subnet, Internet Gateway, and route table associations.
- **Security-First EC2 Provisioning**: Deploys an Ubuntu 22.04 LTS instance with IMDSv2 enforced, encrypted root EBS storage, and an IAM role attached for AWS Systems Manager (SSM).
- **Idempotent Server Configuration**: Uses an Ansible playbook to install Nginx, deploy an application status page via Jinja2 templates, configure a JSON health check endpoint, and manage service state.
- **Independent Validation Utility**: Custom Python script using only standard library modules to test TCP socket connectivity, HTTP status codes, and JSON response payload assertions.
- **Automated CI/CD Pipeline**: GitHub Actions workflows to validate Terraform code formatting, run unit tests, check Ansible syntax, and automate cloud deployments.

---

## Tech Stack

| Technology | Purpose |
| :--- | :--- |
| **AWS** | Cloud hosting (VPC, Subnet, Route Table, IGW, Security Group, EC2, IAM) |
| **Terraform** | Infrastructure as Code for AWS resource lifecycle management |
| **Ansible** | Agentless configuration management and service orchestration |
| **Python 3** | Post-deployment validation script and unit tests |
| **GitHub Actions** | CI/CD automation (linting, validation, test execution, deployment) |
| **Nginx** | Lightweight web server hosting the sample application |
| **Linux (Ubuntu 22.04 LTS)** | Target operating system for the compute instance |
| **Bash / PowerShell** | Local execution scripts for cross-platform automation |

---

## System Architecture & Workflow

### Workflow

```
Developer (Git Push / PR)
   │
   ▼
GitHub Actions (CI/CD)
   │ (Runs fmt, validate, syntax-checks, unit tests)
   ▼
Terraform
   │ (Provisions VPC, Subnet, Security Group, IAM, EC2)
   ▼
Ansible
   │ (Installs Nginx, deploys template, starts service)
   ▼
Nginx Web Server (/ and /healthz)
   │
   ▲
Python CLI Validator (Checks TCP connectivity & HTTP 200)
```

---

## Project Structure

```
AWS-Infrastructure-Automation/
├── .github/
│   └── workflows/
│       ├── ci.yml                  # Linting, Terraform validation, Ansible syntax, Python tests
│       └── deploy.yml              # Automated provisioning, configuration, and teardown
├── ansible/
│   ├── templates/
│   │   └── index.html.j2           # Jinja2 template rendering system facts
│   ├── ansible.cfg                 # Ansible configuration file
│   ├── inventory.ini.example       # Example static inventory template
│   └── playbook.yml                # Configuration playbook for Nginx and health endpoint
├── scripts/
│   ├── deploy.ps1                  # Windows PowerShell deployment automation script
│   ├── deploy.sh                   # Linux/macOS Bash deployment automation script
│   ├── destroy.ps1                 # Windows PowerShell resource teardown script
│   ├── destroy.sh                  # Linux/macOS Bash resource teardown script
│   └── validate.py                 # Standalone Python deployment health validation utility
├── terraform/
│   ├── main.tf                     # Core AWS infrastructure definitions
│   ├── outputs.tf                  # Infrastructure outputs (IP, DNS, connection strings)
│   ├── providers.tf                # AWS provider and version constraints
│   ├── terraform.tfvars.example    # Example variable input file
│   └── variables.tf                # Input variable declarations and defaults
├── tests/
│   └── test_validate.py            # Unit tests for the Python validation CLI
├── .gitignore                      # Git ignore file for secrets and state
├── LICENSE                         # MIT License
└── README.md                       # Project documentation
```

---

## How It Works

1. **Infrastructure Provisioning**: Terraform initializes the AWS provider, reads variables, and creates a VPC with a public subnet and an Internet Gateway. It provisions an EC2 instance with an attached IAM role (`AmazonSSMManagedInstanceCore`) and an encrypted root EBS volume.
2. **Configuration Management**: The deployment script captures the EC2 public IP from Terraform outputs and generates an Ansible inventory. Ansible connects via SSH, installs Nginx, configures the firewall (UFW), deploys the web application template, and sets up `/healthz`.
3. **Validation**: The Python script `scripts/validate.py` connects to the instance over TCP port 80, sends an HTTP GET request to `/` and `/healthz`, and confirms the expected HTTP status code and response body.
4. **CI/CD Execution**: GitHub Actions executes static analysis on pull requests and handles automated deployment on pushes to `main`.

---

## Endpoints

The deployed Nginx service exposes the following HTTP endpoints:

| Method | Endpoint | Purpose |
| :--- | :--- | :--- |
| `GET` | `/` | Web application status page displaying server metadata (hostname, IP, OS, timestamp). |
| `GET` | `/healthz` | JSON health check endpoint returning service operational status (`{"status": "UP"}`). |

---

## Installation & Prerequisites

Ensure the following tools are installed locally:

- **AWS CLI** (configured with valid credentials: `aws configure`)
- **Terraform** (>= 1.5.0)
- **Ansible** (>= 2.15)
- **Python** (>= 3.9)
- **Git**

---

## Configuration

1. Clone the repository:
   ```bash
   git clone https://github.com/harsharaju1314-hash/AWS-Infrastructure-Automation.git
   cd AWS-Infrastructure-Automation
   ```

2. Create a `terraform.tfvars` file inside the `terraform/` directory:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

3. Update the variables as needed:
   ```hcl
   aws_region   = "us-east-1"
   environment  = "dev"
   key_name     = "your-ec2-key-pair-name" # Must exist in your AWS region
   instance_type = "t3.micro"
   ```

---

## Running the Application

### Option A: Automated Single-Command Execution

**On Linux / macOS:**
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

**On Windows (PowerShell):**
```powershell
.\scripts\deploy.ps1
```

### Option B: Step-by-Step Manual Execution

1. **Provision Infrastructure with Terraform:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

2. **Retrieve Instance Public IP:**
   ```bash
   export EC2_IP=$(terraform output -raw public_ip)
   echo "Deployed IP: $EC2_IP"
   ```

3. **Configure the Server with Ansible:**
   ```bash
   cd ../ansible

   # Create inventory
   cat <<EOF > inventory.ini
   [webservers]
   web_server_1 ansible_host=${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem

   [webservers:vars]
   ansible_python_interpreter=/usr/bin/python3
   ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
   EOF

   ansible-playbook -i inventory.ini playbook.yml
   ```

4. **Validate the Deployment with Python:**
   ```bash
   cd ..
   python scripts/validate.py --host "${EC2_IP}" --port 80
   ```

---

## Testing

### Unit Testing (Python Validation Script)

Unit tests mock socket connections and HTTP responses to verify the behavior of `scripts/validate.py` without requiring active cloud infrastructure.

Run the test suite:
```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

### Static Analysis & Syntax Checks

Run formatting and syntax validation checks locally:
```bash
# Terraform formatting and syntax validation
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate

# Ansible playbook syntax check
ansible-playbook -i ansible/inventory.ini.example ansible/playbook.yml --syntax-check
```

---

## Sample Usage & Output

### Python Validation CLI Output

```text
============================================================
 AWS Infrastructure Automation - Deployment Validator
============================================================
 Target Host:       54.210.12.34
 Target Port:       80
 Main Endpoint:     http://54.210.12.34:80/
 Health Endpoint:   http://54.210.12.34:80/healthz
 Max Retries:       6 (Interval: 5s, Timeout: 5s)
------------------------------------------------------------
[*] Checking TCP reachability on 54.210.12.34:80 ... [PASS]

[*] Validating Main Web Application (http://54.210.12.34:80/) ...
[PASS] Main application returned HTTP 200 successfully.

[*] Validating Health Endpoint (http://54.210.12.34:80/healthz) ...
[PASS] Health endpoint responded with HTTP 200.
    -> Parsed Health JSON Payload:
       - status: UP
       - service: aws-infrastructure-automation
       - timestamp: 2026-09-25T13:20:00Z

============================================================
 [SUCCESS] Infrastructure and Application Deployment Validated!
============================================================
```

---

## Cleanup / Teardown

To avoid incurring cloud charges, destroy all provisioned AWS resources when finished:

**Using Script:**
```bash
# Linux / macOS
./scripts/destroy.sh

# Windows (PowerShell)
.\scripts\destroy.ps1
```

**Using Terraform Directly:**
```bash
cd terraform
terraform destroy -auto-approve
```

---

## What I Learned

- Structuring reusable Terraform configurations using input variables (`variables.tf`), outputs (`outputs.tf`), and tags instead of hardcoded values.
- Separating cloud infrastructure lifecycle (Terraform) from operating system configuration (Ansible) rather than relying exclusively on monolithic `user_data` scripts.
- Writing idempotent Ansible playbooks with handlers and Jinja2 dynamic templating.
- Implementing an independent health verification tool using Python's standard library (`socket`, `urllib.request`) and designing standard exit codes (`0`-`4`) for CI/CD integration.
- Building multi-stage GitHub Actions workflows for automated linting, dry-run planning, and deployment.
- Applying AWS security practices: enforcing IMDSv2, enabling EBS volume encryption, and attaching an IAM role for AWS Systems Manager (SSM) Session Manager access.

---

## Future Improvements

- Add Terraform remote state management using an Amazon S3 bucket with DynamoDB state locking.
- Add an Application Load Balancer (ALB) and Auto Scaling Group (ASG) across multiple Availability Zones for high availability.
- Introduce HTTPS support with automated SSL/TLS certificate provisioning via Let's Encrypt or AWS Certificate Manager.

---

## Author

**Harsha Raju**
- GitHub: [@harsharaju1314-hash](https://github.com/harsharaju1314-hash)
- Repository: [AWS-Infrastructure-Automation](https://github.com/harsharaju1314-hash/AWS-Infrastructure-Automation)
