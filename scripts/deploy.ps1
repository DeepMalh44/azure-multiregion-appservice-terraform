# Azure App Service Multi-Region Deployment Script (PowerShell)
# This script deploys the Terraform infrastructure for staging or production

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("staging", "production")]
    [string]$Environment = "staging",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove,
    
    [Parameter(Mandatory=$false)]
    [switch]$Destroy,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\deploy.ps1 [OPTIONS]" -ForegroundColor Cyan
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Environment ENV     Environment to deploy (staging|production) [default: staging]" -ForegroundColor White
    Write-Host "  -AutoApprove         Auto approve Terraform plan" -ForegroundColor White
    Write-Host "  -Destroy             Destroy infrastructure instead of creating" -ForegroundColor White
    Write-Host "  -Help                Display this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\deploy.ps1 -Environment staging -AutoApprove" -ForegroundColor White
    Write-Host "  .\deploy.ps1 -Environment production" -ForegroundColor White
    Write-Host "  .\deploy.ps1 -Environment staging -Destroy -AutoApprove" -ForegroundColor White
    exit 0
}

if ($Help) {
    Show-Usage
}

Write-Host "[INFO] Starting Azure App Service deployment..." -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Check if Azure CLI is installed and user is logged in
try {
    $null = Get-Command az -ErrorAction Stop
    Write-Host "[OK] Azure CLI is available" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in to Azure
try {
    $null = az account show --output none 2>$null
    Write-Host "[OK] You are logged in to Azure" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] You are not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Check if Terraform is installed
try {
    $null = Get-Command terraform -ErrorAction Stop
    Write-Host "[OK] Terraform is available" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Initialize Terraform
Write-Host "[INFO] Initializing Terraform..." -ForegroundColor Cyan
try {
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform initialization failed"
    }
    Write-Host "[OK] Terraform initialized successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform initialization failed" -ForegroundColor Red
    exit 1
}

# Validate Terraform configuration
Write-Host "[INFO] Validating Terraform configuration..." -ForegroundColor Cyan
try {
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validation failed"
    }
    Write-Host "[OK] Terraform configuration is valid" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform validation failed" -ForegroundColor Red
    exit 1
}

# Plan the deployment
Write-Host "[INFO] Creating Terraform plan..." -ForegroundColor Cyan
$PlanFile = "tfplan-$Environment"

try {
    if ($Destroy) {
        terraform plan -destroy -var-file="environments\$Environment\terraform.tfvars" -out="$PlanFile"
        Write-Host "[INFO] Destroy plan created. Review the plan above." -ForegroundColor Yellow
    } else {
        terraform plan -var-file="environments\$Environment\terraform.tfvars" -out="$PlanFile"
        Write-Host "[INFO] Deployment plan created. Review the plan above." -ForegroundColor Yellow
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform planning failed"
    }
} catch {
    Write-Host "[ERROR] Terraform planning failed" -ForegroundColor Red
    exit 1
}

# Apply the plan
if ($AutoApprove) {
    Write-Host "[INFO] Applying Terraform plan automatically..." -ForegroundColor Cyan
    try {
        terraform apply "$PlanFile"
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
    } catch {
        Write-Host "[ERROR] Terraform apply failed" -ForegroundColor Red
        Remove-Item "$PlanFile" -ErrorAction SilentlyContinue
        exit 1
    }
} else {
    $Confirm = Read-Host "[PROMPT] Do you want to apply this plan? (y/N)"
    if ($Confirm -eq "y" -or $Confirm -eq "Y") {
        Write-Host "[INFO] Applying Terraform plan..." -ForegroundColor Cyan
        try {
            terraform apply "$PlanFile"
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform apply failed"
            }
        } catch {
            Write-Host "[ERROR] Terraform apply failed" -ForegroundColor Red
            Remove-Item "$PlanFile" -ErrorAction SilentlyContinue
            exit 1
        }
    } else {
        Write-Host "[INFO] Deployment cancelled by user" -ForegroundColor Red
        Remove-Item "$PlanFile" -ErrorAction SilentlyContinue
        exit 1
    }
}

# Clean up plan file
Remove-Item "$PlanFile" -ErrorAction SilentlyContinue

Write-Host ""
if ($Destroy) {
    Write-Host "[SUCCESS] Infrastructure destroyed successfully!" -ForegroundColor Green
} else {
    Write-Host "[SUCCESS] Deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Deployment information:" -ForegroundColor Cyan
    terraform output
}

Write-Host ""
Write-Host "[SUCCESS] Script completed successfully!" -ForegroundColor Green