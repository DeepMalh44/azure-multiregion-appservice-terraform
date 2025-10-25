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
    [switch]$SkipAppDeployment,
    
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
    Write-Host "  -SkipAppDeployment   Deploy only infrastructure, skip application deployment" -ForegroundColor White
    Write-Host "  -Help                Display this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\deploy.ps1 -Environment staging -AutoApprove" -ForegroundColor White
    Write-Host "  .\deploy.ps1 -Environment production" -ForegroundColor White
    Write-Host "  .\deploy.ps1 -Environment staging -SkipAppDeployment" -ForegroundColor White
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
    Write-Host "[SUCCESS] Infrastructure deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Deployment information:" -ForegroundColor Cyan
    terraform output
    
    # Deploy application to App Services
    if ($SkipAppDeployment) {
        Write-Host ""
        Write-Host "[INFO] Skipping application deployment as requested" -ForegroundColor Yellow
        Write-Host "[INFO] Infrastructure deployment completed. Use TESTING.md for manual app deployment." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "[INFO] Starting application deployment to App Services..." -ForegroundColor Cyan
    
    # Get the app service names from Terraform output
    try {
        $TerraformOutput = terraform output -json | ConvertFrom-Json
        $PrimaryAppName = $TerraformOutput.primary_app_service.value.name
        $SecondaryAppName = $TerraformOutput.secondary_app_service.value.name
        $PrimaryResourceGroup = $TerraformOutput.primary_resource_group.value.name
        $SecondaryResourceGroup = $TerraformOutput.secondary_resource_group.value.name
        
        Write-Host "[INFO] Primary App Service: $PrimaryAppName" -ForegroundColor Yellow
        Write-Host "[INFO] Secondary App Service: $SecondaryAppName" -ForegroundColor Yellow
        
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
            
        } finally {
            # Return to original location
            Set-Location $OriginalLocation
        }
        
    } catch {
        Write-Host "[ERROR] Application deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[INFO] Infrastructure was deployed successfully, but application deployment failed." -ForegroundColor Yellow
        Write-Host "[INFO] You can manually deploy the application using the commands in TESTING.md" -ForegroundColor Yellow
        exit 1
    }
    } # End of SkipAppDeployment else block
}

Write-Host ""
Write-Host "[SUCCESS] Script completed successfully!" -ForegroundColor Green