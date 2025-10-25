#!/bin/bash

# Azure App Service Multi-Region Deployment Script
# This script deploys the Terraform infrastructure for staging or production

set -e

# Default values
ENVIRONMENT="staging"
AUTO_APPROVE=false
DESTROY=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -e, --environment ENV    Environment to deploy (staging|production) [default: staging]"
    echo "  -a, --auto-approve       Auto approve Terraform plan"
    echo "  -d, --destroy           Destroy infrastructure instead of creating"
    echo "  -h, --help              Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -d|--destroy)
            DESTROY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "Error: Environment must be either 'staging' or 'production'"
    exit 1
fi

echo "🚀 Starting Azure App Service deployment..."
echo "Environment: $ENVIRONMENT"
echo "Working directory: $(pwd)"

# Check if Azure CLI is installed and user is logged in
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ You are not logged in to Azure. Please run 'az login' first."
    exit 1
fi

echo "✅ Azure CLI is available and you are logged in"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi

echo "✅ Terraform is available"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Creating Terraform plan..."
PLAN_FILE="tfplan-$ENVIRONMENT"

if [[ "$DESTROY" == "true" ]]; then
    terraform plan -destroy -var-file="environments/$ENVIRONMENT/terraform.tfvars" -out="$PLAN_FILE"
    echo "📋 Destroy plan created. Review the plan above."
else
    terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars" -out="$PLAN_FILE"
    echo "📋 Deployment plan created. Review the plan above."
fi

# Apply the plan
if [[ "$AUTO_APPROVE" == "true" ]]; then
    echo "🚀 Applying Terraform plan automatically..."
    terraform apply "$PLAN_FILE"
else
    echo "❓ Do you want to apply this plan? (y/N)"
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "🚀 Applying Terraform plan..."
        terraform apply "$PLAN_FILE"
    else
        echo "❌ Deployment cancelled by user"
        rm -f "$PLAN_FILE"
        exit 1
    fi
fi

# Clean up plan file
rm -f "$PLAN_FILE"

if [[ "$DESTROY" == "true" ]]; then
    echo "💥 Infrastructure destroyed successfully!"
else
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Deployment information:"
    terraform output -json | jq -r '
        "Application Gateway URL: " + .application_urls.value.application_gateway_url,
        "Primary App Service: " + .primary_app_service.value.default_hostname,
        "Secondary App Service: " + .secondary_app_service.value.default_hostname
    '
fi