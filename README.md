# AWS Infrastructure Automation

[![CI Pipeline](https://github.com/harsharaju1314-hash/AWS-Infrastructure-Automation/actions/workflows/ci.yml/badge.svg)](https://github.com/harsharaju1314-hash/AWS-Infrastructure-Automation/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade, reproducible DevOps pipeline that provisions secure AWS cloud infrastructure using **Terraform (IaC)**, configures the Linux application environment automatically with **Ansible**, validates service health using a custom **Python CLI utility**, and automates end-to-end execution via **GitHub Actions CI/CD**.

---

## Architecture Overview

```
GitHub (Code Repository)
   │
   ▼
GitHub Actions (CI/CD Pipeline)
   │
   ▼
Terraform (Infrastructure as Code)
   │
   ▼
AWS Cloud (Custom VPC: 10.0.0.0/16)
   │
   └── Internet Gateway & Route Table
         │
         └── Public Subnet (10.0.1.0/24)
               │
               └── Security Group (HTTP 80, SSH 22)
                     │
                     └── EC2 Instance (Ubuntu 22.04 LTS + SSM Role)
                           │
                           ▼
                        Ansible (Configuration Management)
                           │
                           ▼
                     Nginx Web Application + Health Endpoint (/healthz)
                           │
                           ▲
                     Python Validator (TCP & HTTP Health Checks)
```

---

## Tech Stack & Tools

| Tool / Technology | Purpose | Key Concept / Implementation |
| :--- | :--- | :--- |
| **AWS** | Cloud Provider | Custom VPC, Public Subnet, Internet Gateway, EC2, IAM, Security Groups |
| **Terraform** | Infrastructure as Code | Modular IaC, parameterization via `variables.tf`, state management, outputs |
| **Ansible** | Configuration Management | Agentless orchestration, idempotency, Jinja2 dynamic templating, service handlers |
| **Python** | Health Validation | Custom CLI utility using standard library (`socket`, `urllib`) with exit codes for CI/CD |
| **GitHub Actions** | CI/CD Automation | Multi-stage pipeline (Lint, Validate, Plan, Apply, Destroy), OIDC authentication |
| **Linux & Nginx** | Host OS & Web Server | Ubuntu 22.04 LTS, systemd service management, UFW firewall configuration |
| **Bash & PowerShell**| Local Automation | Cross-platform orchestration scripts for single-command deploy and destroy |

---

## Repository Structure

```
AWS-Infrastructure-Automation/
├── .github/
│   └── workflows/
│       ├── ci.yml                  # PR & branch validation (Terraform fmt/validate, Ansible syntax, Python tests)
│       └── deploy.yml              # Automated provisioning, configuration, and verification pipeline
├── terraform/
│   ├── providers.tf                # AWS provider and version constraints
│   ├── variables.tf                # Input variables with types and defaults
│   ├── main.tf                     # Core infrastructure (VPC, Subnet, IGW, SG, IAM, EC2)
│   ├── outputs.tf                  # Infrastructure outputs (IP, DNS, connection strings)
│   └── terraform.tfvars.example    # Template variable values
├── ansible/
│   ├── ansible.cfg                 # Ansible runtime settings (host key checking, timeouts)
│   ├── inventory.ini.example       # Sample inventory structure
│   ├── playbook.yml                # Configuration playbook (Nginx, templating, health check)
│   └── templates/
│       └── index.html.j2           # Dynamic Jinja2 web page template
├── scripts/
│   ├── validate.py                 # Python CLI validation utility
│   ├── deploy.sh                   # Linux/macOS single-command deployment script
│   ├── deploy.ps1                  # Windows PowerShell deployment script
│   ├── destroy.sh                  # Linux/macOS teardown script
│   └── destroy.ps1                 # Windows PowerShell teardown script
├── tests/
│   └── test_validate.py            # Unit tests for the Python validation utility
├── .gitignore                      # Excludes credentials, state files, and cache
└── README.md                       # Complete project documentation
```

---

## Prerequisites

Before deploying, ensure you have installed:

1. **AWS CLI** (configured with `aws configure`): [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. **Terraform** (>= 1.5.0): [Install Terraform](https://developer.hashicorp.com/terraform/install)
3. **Ansible** (>= 2.15): [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
4. **Python 3.9+**: [Install Python](https://www.python.org/downloads/)
5. An existing **AWS EC2 Key Pair** in your target region.

---

## Quick Start (Local Deployment)

### 1. Clone the Repository

```bash
git clone https://github.com/harsharaju1314-hash/AWS-Infrastructure-Automation.git
cd AWS-Infrastructure-Automation
```

### 2. Configure Terraform Variables

Create your `terraform.tfvars` from the example:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` with your AWS Key Pair name and region:

```hcl
aws_region   = "us-east-1"
key_name     = "my-aws-keypair"
environment  = "dev"
```

### 3. Deploy Everything in One Command

**On Linux / macOS:**
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

**On Windows (PowerShell):**
```powershell
.\scripts\deploy.ps1
```

The script automatically:
1. Provisions AWS infrastructure via Terraform.
2. Captures the EC2 public IP.
3. Generates the dynamic Ansible inventory (`ansible/inventory.ini`).
4. Executes the Ansible playbook to install and configure Nginx.
5. Runs the Python validation script against the live server.

---

## Step-by-Step Manual Execution

If you prefer to execute each phase manually:

### Phase 1: Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

Capture the outputted public IP:
```bash
export EC2_IP=$(terraform output -raw public_ip)
echo "Instance Public IP: $EC2_IP"
```

### Phase 2: Configure Server with Ansible

```bash
cd ../ansible

# Create inventory file
cat <<EOF > inventory.ini
[webservers]
web_server_1 ansible_host=${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-key.pem

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# Run playbook
ansible-playbook -i inventory.ini playbook.yml
```

### Phase 3: Validate Deployment with Python

```bash
cd ..
python scripts/validate.py --host "${EC2_IP}" --port 80
```

Sample validation output:
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

## CI/CD Pipeline (GitHub Actions)

The repository includes two automated workflows:

### 1. Continuous Integration (`.github/workflows/ci.yml`)
- **Triggers**: Pull requests to `main` and branch pushes.
- **Checks**:
  - `terraform fmt -check` (checks formatting standards).
  - `terraform validate` (validates syntax and resource schemas).
  - `ansible-playbook --syntax-check` (verifies Ansible YAML and task syntax).
  - `python -m unittest` (executes unit test suite for the validation script).
  - `terraform plan` (dry-run plan output on pull requests).

### 2. Automated Deployment (`.github/workflows/deploy.yml`)
- **Triggers**: Push to `main` or manual trigger via `workflow_dispatch`.
- **Options**: `apply` (provisions & configures) or `destroy` (cleans up).
- **Authentication**: Supports AWS OIDC Role assumption (recommended) or encrypted GitHub Secrets.

### Required GitHub Secrets & Variables

To run the pipeline in GitHub Actions, configure the following secrets under **Settings > Secrets and variables > Actions**:

| Secret Name | Description | Example |
| :--- | :--- | :--- |
| `AWS_ROLE_TO_ASSUME` | IAM Role ARN for GitHub OIDC (Recommended) | `arn:aws:iam::123456789012:role/GitHubActionsDeployRole` |
| `AWS_ACCESS_KEY_ID` | IAM User Access Key (Alternative to OIDC) | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY`| IAM User Secret Key (Alternative to OIDC) | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS Target Region | `us-east-1` |
| `SSH_PRIVATE_KEY` | Private SSH key matching the EC2 Key Pair | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

---

## Security Best Practices Implemented

1. **Least Privilege IAM**:
   - The EC2 instance is attached to an IAM Instance Profile with the managed policy `AmazonSSMManagedInstanceCore`.
   - Enables AWS Systems Manager Session Manager access without requiring port 22 to remain open to the public internet.
2. **Encrypted Storage**:
   - The EC2 root EBS volume is configured with `encrypted = true` using AWS KMS default keys.
3. **IMDSv2 Enforcement**:
   - `http_tokens = "required"` is configured in `metadata_options` to prevent Server-Side Request Forgery (SSRF) metadata credential theft.
4. **Zero Hardcoded Secrets**:
   - `.gitignore` prevents private keys, `.tfstate`, and credentials from being committed to source control.
5. **Idempotent Ansible Automation**:
   - State checks guarantee that re-running the playbook causes no unintended side effects.

---

## Interview Talking Points & Architecture Decisions

| Decision | Why was this choice made? |
| :--- | :--- |
| **Why separate Terraform and Ansible?** | Terraform excels at provisioning infrastructure lifecycle (VPC, Subnets, EC2), while Ansible excels at OS configuration, package lifecycle, and application state. Mixing both in `user_data` makes configuration drift hard to maintain. |
| **Why use a custom Python validator?** | Simple `curl` commands in bash lack robust error handling, exit code mapping, and response body JSON parsing. A standalone Python CLI allows automated integration in both local environments and CI/CD runners. |
| **Why use AWS SSM alongside SSH?** | Session Manager eliminates the security vulnerability of exposing SSH port 22 to `0.0.0.0/0` and provides complete session logging in AWS CloudTrail. |
| **How is state managed in CI/CD?** | For team environments, Terraform S3 Remote Backend with DynamoDB state locking is configured in `providers.tf` to prevent concurrent write collisions. |

---

## Troubleshooting Guide

### 1. `dpkg / apt-get lock` error in Ansible
- **Cause**: Ubuntu automatically runs `unattended-upgrades` immediately on boot.
- **Resolution**: The Ansible playbook includes `wait_for_connection` and retry mechanisms to allow cloud-init to finish.

### 2. Python validation timeout or connection refused
- **Cause**: The EC2 security group has not allowed inbound port 80 or the Nginx service failed to start.
- **Resolution**: Check the AWS Security Group rules and verify Nginx status using `systemctl status nginx` or SSM Session Manager.

### 3. SSH Connection Timed Out
- **Cause**: Missing Internet Gateway, public IP not assigned, or incorrect route table association.
- **Resolution**: Verify `aws_route_table_association.public` is attached to the public subnet and `map_public_ip_on_launch = true`.

---

## Resource Teardown / Cleanup

To avoid unnecessary AWS cloud charges, always destroy the infrastructure when finished:

**Using Script:**
```bash
# Linux/macOS
./scripts/destroy.sh

# Windows (PowerShell)
.\scripts\destroy.ps1
```

**Using Terraform directly:**
```bash
cd terraform
terraform destroy -auto-approve
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
