# ==============================================================================
# Teardown Script (PowerShell)
# Destroys all provisioned AWS resources to prevent unexpected cloud costs.
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$TerraformDir = Join-Path $RootDir "terraform"
$InventoryFile = Join-Path $RootDir "ansible\inventory.ini"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AWS Infrastructure Automation - Resource Teardown" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "`n[*] Destroying AWS resources via Terraform..." -ForegroundColor Yellow
Push-Location $TerraformDir
try {
    terraform destroy -auto-approve
}
finally {
    Pop-Location
}

if (Test-Path $InventoryFile) {
    Remove-Item -Path $InventoryFile -Force
    Write-Host "[*] Removed generated Ansible inventory." -ForegroundColor Green
}

Write-Host "`n[SUCCESS] All infrastructure resources have been destroyed." -ForegroundColor Green
