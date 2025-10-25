@echo off
REM Azure App Service Multi-Region Deployment Script for Windows
REM This script deploys the Terraform infrastructure for staging or production

setlocal enabledelayedexpansion

REM Default values
set ENVIRONMENT=staging
set AUTO_APPROVE=false
set DESTROY=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto validate_args
if "%~1"=="-e" (
    set ENVIRONMENT=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--environment" (
    set ENVIRONMENT=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="-a" (
    set AUTO_APPROVE=true
    shift
    goto parse_args
)
if "%~1"=="--auto-approve" (
    set AUTO_APPROVE=true
    shift
    goto parse_args
)
if "%~1"=="-d" (
    set DESTROY=true
    shift
    goto parse_args
)
if "%~1"=="--destroy" (
    set DESTROY=true
    shift
    goto parse_args
)
if "%~1"=="-h" goto usage
if "%~1"=="--help" goto usage

echo Unknown option: %~1
goto usage

:usage
echo Usage: %0 [OPTIONS]
echo Options:
echo   -e, --environment ENV    Environment to deploy (staging^|production) [default: staging]
echo   -a, --auto-approve       Auto approve Terraform plan
echo   -d, --destroy           Destroy infrastructure instead of creating
echo   -h, --help              Display this help message
exit /b 1

:validate_args
REM Validate environment
if not "%ENVIRONMENT%"=="staging" if not "%ENVIRONMENT%"=="production" (
    echo Error: Environment must be either 'staging' or 'production'
    exit /b 1
)

echo 🚀 Starting Azure App Service deployment...
echo Environment: %ENVIRONMENT%
echo Working directory: %CD%

REM Check if Azure CLI is installed and user is logged in
where az >nul 2>nul
if errorlevel 1 (
    echo ❌ Azure CLI is not installed. Please install it first.
    exit /b 1
)

REM Check if user is logged in to Azure
az account show >nul 2>nul
if errorlevel 1 (
    echo ❌ You are not logged in to Azure. Please run 'az login' first.
    exit /b 1
)

echo ✅ Azure CLI is available and you are logged in

REM Check if Terraform is installed
where terraform >nul 2>nul
if errorlevel 1 (
    echo ❌ Terraform is not installed. Please install it first.
    exit /b 1
)

echo ✅ Terraform is available

REM Initialize Terraform
echo 🔧 Initializing Terraform...
terraform init
if errorlevel 1 (
    echo ❌ Terraform initialization failed
    exit /b 1
)

REM Validate Terraform configuration
echo 🔍 Validating Terraform configuration...
terraform validate
if errorlevel 1 (
    echo ❌ Terraform validation failed
    exit /b 1
)

REM Plan the deployment
echo 📋 Creating Terraform plan...
set PLAN_FILE=tfplan-%ENVIRONMENT%

if "%DESTROY%"=="true" (
    terraform plan -destroy -var-file="environments\%ENVIRONMENT%\terraform.tfvars" -out="%PLAN_FILE%"
    echo 📋 Destroy plan created. Review the plan above.
) else (
    terraform plan -var-file="environments\%ENVIRONMENT%\terraform.tfvars" -out="%PLAN_FILE%"
    echo 📋 Deployment plan created. Review the plan above.
)

if errorlevel 1 (
    echo ❌ Terraform planning failed
    exit /b 1
)

REM Apply the plan
if "%AUTO_APPROVE%"=="true" (
    echo 🚀 Applying Terraform plan automatically...
    terraform apply "%PLAN_FILE%"
) else (
    echo ❓ Do you want to apply this plan? (y/N)
    set /p CONFIRM=
    if /i "!CONFIRM!"=="y" (
        echo 🚀 Applying Terraform plan...
        terraform apply "%PLAN_FILE%"
    ) else (
        echo ❌ Deployment cancelled by user
        del "%PLAN_FILE%" 2>nul
        exit /b 1
    )
)

if errorlevel 1 (
    echo ❌ Terraform apply failed
    del "%PLAN_FILE%" 2>nul
    exit /b 1
)

REM Clean up plan file
del "%PLAN_FILE%" 2>nul

if "%DESTROY%"=="true" (
    echo 💥 Infrastructure destroyed successfully!
) else (
    echo 🎉 Deployment completed successfully!
    echo.
    echo 📋 Deployment information:
    terraform output
)

endlocal