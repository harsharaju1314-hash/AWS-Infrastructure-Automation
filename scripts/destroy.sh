#!/usr/bin/env bash
# ==============================================================================
# Teardown Script (Bash)
# Destroys all provisioned AWS resources to prevent unexpected cloud costs.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
INVENTORY_FILE="${SCRIPT_DIR}/../ansible/inventory.ini"

echo "============================================================"
echo " AWS Infrastructure Automation - Resource Teardown"
echo "============================================================"

echo -e "\n[*] Destroying AWS resources via Terraform..."
cd "${TERRAFORM_DIR}"
terraform destroy -auto-approve

# Clean up generated inventory
if [ -f "${INVENTORY_FILE}" ]; then
    rm -f "${INVENTORY_FILE}"
    echo "[*] Removed generated Ansible inventory."
fi

echo -e "\n[SUCCESS] All infrastructure resources have been destroyed."
