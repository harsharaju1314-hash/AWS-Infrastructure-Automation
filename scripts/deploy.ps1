# ==============================================================================
# End-to-End Local Deployment Script (PowerShell)
# Steps:
# 1. Initialize & Apply Terraform configuration
# 2. Extract EC2 Public IP address
# 3. Generate dynamic Ansible inventory
# 4. Run Ansible Playbook (via WSL / Linux runner if available)
# 5. Run Python Health Validation
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$TerraformDir = Join-Path $RootDir "terraform"
$AnsibleDir = Join-Path $RootDir "ansible"
$InventoryFile = Join-Path $AnsibleDir "inventory.ini"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AWS Infrastructure Automation - Local Deployment Pipeline" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Provision Infrastructure via Terraform
Write-Host "`n[Step 1/4] Provisioning AWS Infrastructure with Terraform..." -ForegroundColor Yellow
Push-Location $TerraformDir
try {
    terraform init
    terraform apply -auto-approve
    $PublicIP = (terraform output -raw public_ip).Trim()
}
finally {
    Pop-Location
}

Write-Host "`n[Info] Provisioned EC2 Public IP: $PublicIP" -ForegroundColor Green

# 2. Generate Ansible Inventory
Write-Host "`n[Step 2/4] Generating Ansible Inventory..." -ForegroundColor Yellow
$InventoryContent = @"
[webservers]
web_server_1 ansible_host=$PublicIP ansible_user=ubuntu

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
"@

Set-Content -Path $InventoryFile -Value $InventoryContent -Encoding utf8
Write-Host "[Info] Inventory created at $InventoryFile" -ForegroundColor Green

# 3. Run Ansible Playbook (if ansible-playbook or wsl is available)
Write-Host "`n[Step 3/4] Configuring Web Server with Ansible..." -ForegroundColor Yellow
if (Get-Command "ansible-playbook" -ErrorAction SilentlyContinue) {
    Push-Location $AnsibleDir
    try {
        ansible-playbook -i inventory.ini playbook.yml
    }
    finally {
        Pop-Location
    }
} elseif (Get-Command "wsl" -ErrorAction SilentlyContinue) {
    Write-Host "[Notice] Running Ansible via WSL..." -ForegroundColor Cyan
    $WslAnsibleDir = (wsl wslpath -u ($AnsibleDir -replace '\\', '/')).Trim()
    wsl bash -c "cd '$WslAnsibleDir' && ansible-playbook -i inventory.ini playbook.yml"
} else {
    Write-Host "[Warning] Neither native ansible-playbook nor WSL was found." -ForegroundColor DarkYellow
    Write-Host "Please execute the playbook from a Linux environment or GitHub Actions." -ForegroundColor DarkYellow
}

# 4. Run Validation
Write-Host "`n[Step 4/4] Validating Deployment with Python Utility..." -ForegroundColor Yellow
$ValidatorScript = Join-Path $ScriptDir "validate.py"
python $ValidatorScript --host $PublicIP --port 80

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Deployment completed and validated successfully!" -ForegroundColor Green
Write-Host " Application URL: http://$PublicIP" -ForegroundColor Green
Write-Host " Health Endpoint: http://$PublicIP/healthz" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
