#!/usr/bin/env bash
# ==============================================================================
# End-to-End Local Deployment Script (Bash)
# Steps:
# 1. Initialize & Apply Terraform configuration
# 2. Extract EC2 Public IP address
# 3. Generate dynamic Ansible inventory
# 4. Execute Ansible Playbook
# 5. Run Python Health Validation
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"
ANSIBLE_DIR="${ROOT_DIR}/ansible"
INVENTORY_FILE="${ANSIBLE_DIR}/inventory.ini"

echo "============================================================"
echo " AWS Infrastructure Automation - Local Deployment Pipeline"
echo "============================================================"

# 1. Provision Infrastructure via Terraform
echo -e "\n[Step 1/4] Provisioning AWS Infrastructure with Terraform..."
cd "${TERRAFORM_DIR}"
terraform init
terraform apply -auto-approve

# 2. Extract Outputs
PUBLIC_IP=$(terraform output -raw public_ip)
echo -e "\n[Info] Provisioned EC2 Public IP: ${PUBLIC_IP}"

# 3. Generate Ansible Inventory
echo -e "\n[Step 2/4] Generating Ansible Inventory..."
cat <<EOF > "${INVENTORY_FILE}"
[webservers]
web_server_1 ansible_host=${PUBLIC_IP} ansible_user=ubuntu

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
echo "[Info] Inventory created at ${INVENTORY_FILE}"

# 4. Run Ansible Playbook
echo -e "\n[Step 3/4] Configuring Web Server with Ansible..."
cd "${ANSIBLE_DIR}"
ansible-playbook -i inventory.ini playbook.yml

# 5. Run Validation
echo -e "\n[Step 4/4] Validating Deployment with Python Utility..."
python3 "${SCRIPT_DIR}/validate.py" --host "${PUBLIC_IP}" --port 80

echo -e "\n============================================================"
echo " [SUCCESS] Deployment completed and validated successfully!"
echo " Application URL: http://${PUBLIC_IP}"
echo " Health Endpoint: http://${PUBLIC_IP}/healthz"
echo "============================================================"
