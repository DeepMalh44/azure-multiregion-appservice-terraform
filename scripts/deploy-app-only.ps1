# Deploy Application Only Script
# This script deploys only the Node.js application to existing App Services

param(
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

function Show-Usage {
    Write-Host "Usage: .\deploy-app-only.ps1" -ForegroundColor Cyan
    Write-Host "Description: Deploys the Node.js application to existing App Services" -ForegroundColor White
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Cyan
    Write-Host "  - Infrastructure must be already deployed via deploy.ps1" -ForegroundColor White
    Write-Host "  - Azure CLI must be installed and logged in" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Help                Display this help message" -ForegroundColor White
    exit 0
}

if ($Help) {
    Show-Usage
}

Write-Host "[INFO] Starting application-only deployment..." -ForegroundColor Green
Write-Host ""

# Check if Azure CLI is installed and user is logged in
try {
    $null = Get-Command az -ErrorAction Stop
    Write-Host "[OK] Azure CLI is available" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

try {
    $null = az account show --output none 2>$null
    Write-Host "[OK] You are logged in to Azure" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] You are not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Check if Terraform output is available
if (-not (Test-Path "terraform.tfstate")) {
    Write-Host "[ERROR] Terraform state file not found. Please deploy infrastructure first using deploy.ps1" -ForegroundColor Red
    exit 1
}

# Get the app service names from Terraform output
Write-Host "[INFO] Getting deployment information from Terraform..." -ForegroundColor Cyan
try {
    $TerraformOutput = terraform output -json | ConvertFrom-Json
    $PrimaryAppName = $TerraformOutput.primary_app_service.value.name
    $SecondaryAppName = $TerraformOutput.secondary_app_service.value.name
    $PrimaryResourceGroup = $TerraformOutput.primary_resource_group.value.name
    $SecondaryResourceGroup = $TerraformOutput.secondary_resource_group.value.name
    
    Write-Host "[INFO] Primary App Service: $PrimaryAppName" -ForegroundColor Yellow
    Write-Host "[INFO] Secondary App Service: $SecondaryAppName" -ForegroundColor Yellow
} catch {
    Write-Host "[ERROR] Failed to get Terraform output. Please ensure infrastructure is deployed." -ForegroundColor Red
    exit 1
}

# Check if app directory exists
$AppDir = Join-Path $PSScriptRoot "..\app"
if (-not (Test-Path $AppDir)) {
    Write-Host "[ERROR] App directory not found at: $AppDir" -ForegroundColor Red
    exit 1
}

# Change to app directory
$OriginalLocation = Get-Location
Set-Location $AppDir

try {
    Write-Host "[INFO] Starting application deployment..." -ForegroundColor Cyan
    
    # Clear any existing Azure CLI defaults
    az configure --scope local --defaults group="" location="" web="" plan=""
    
    # Deploy to primary app service (East US)
    Write-Host "[INFO] Deploying to primary app service ($PrimaryAppName)..." -ForegroundColor Cyan
    az webapp up --name $PrimaryAppName --resource-group $PrimaryResourceGroup --runtime "node:20-lts" --os-type Linux --plan "asp-hello-world-app-eastus-6e716b99"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Primary app service deployment failed"
    }
    Write-Host "[OK] Primary app service deployed successfully" -ForegroundColor Green
    
    # Clear defaults again
    az configure --scope local --defaults group="" location="" web="" plan=""
    
    # Deploy to secondary app service (West US 2)
    Write-Host "[INFO] Deploying to secondary app service ($SecondaryAppName)..." -ForegroundColor Cyan
    az webapp up --name $SecondaryAppName --resource-group $SecondaryResourceGroup --runtime "node:20-lts" --os-type Linux --plan "asp-hello-world-app-westus2-6e716b99"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Secondary app service deployment failed"
    }
    Write-Host "[OK] Secondary app service deployed successfully" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "[SUCCESS] Application deployed to both regions!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Your application is now accessible at:" -ForegroundColor Cyan
    $ApplicationGatewayFQDN = $TerraformOutput.application_gateway.value.fqdn
    Write-Host "  Main URL: http://$ApplicationGatewayFQDN/wishes" -ForegroundColor White
    Write-Host "  Health Check: http://$ApplicationGatewayFQDN/health" -ForegroundColor White
    Write-Host "  API Info: http://$ApplicationGatewayFQDN/api/info" -ForegroundColor White
    Write-Host ""
    Write-Host "  Direct URLs:" -ForegroundColor Yellow
    Write-Host "    East US: https://$PrimaryAppName.azurewebsites.net/wishes" -ForegroundColor White
    Write-Host "    West US 2: https://$SecondaryAppName.azurewebsites.net/wishes" -ForegroundColor White
    
} catch {
    Write-Host "[ERROR] Application deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Return to original location
    Set-Location $OriginalLocation
}

Write-Host ""
Write-Host "[SUCCESS] Application deployment completed successfully!" -ForegroundColor Green