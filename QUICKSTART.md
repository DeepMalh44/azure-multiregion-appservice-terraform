# Quick Start Guide

This guide will help you deploy the multi-region Azure App Service infrastructure quickly.

## Prerequisites

Before you begin, ensure you have:

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure subscription** with appropriate permissions
4. **PowerShell** (Windows) or **Bash** (Linux/macOS)

## Quick Deployment Steps

### 1. Login to Azure
```bash
az login
az account set --subscription "your-subscription-id"
```

### 2. Clone and Navigate to Project
```bash
git clone <your-repo>
cd AppServiceTerraform
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Deploy to Staging (Recommended for first deployment)

#### Windows (PowerShell)
```powershell
.\scripts\deploy.ps1 -Environment staging -AutoApprove
```

#### Linux/macOS (Bash)
```bash
./scripts/deploy.sh -e staging -a
```

### 5. Deploy to Production (After testing staging)

#### Windows (PowerShell)
```powershell
.\scripts\deploy.ps1 -Environment production
```

#### Linux/macOS (Bash)
```bash
./scripts/deploy.sh -e production
```

## What Gets Deployed

- ✅ **2 Resource Groups** (Primary and Secondary regions)
- ✅ **2 Virtual Networks** with proper subnetting
- ✅ **2 App Service Plans** with zone redundancy (Premium v3)
- ✅ **2 App Services** with the Hello World application
- ✅ **1 Application Gateway** for load balancing
- ✅ **Network Security Groups** for security
- ✅ **Application Insights** for monitoring

## After Deployment

### Access Your Application
After successful deployment, you'll see output similar to:
```
application_urls = {
  "application_gateway_url" = "https://agw-hello-world-app-12345678.eastus.cloudapp.azure.com"
  "primary_app_direct_url" = "https://app-hello-world-app-eastus-12345678.azurewebsites.net"
  "secondary_app_direct_url" = "https://app-hello-world-app-westus2-12345678.azurewebsites.net"
}
```

### Test Your Deployment
1. **Main Application**: Visit the `application_gateway_url`
2. **Health Check**: Add `/health` to the URL
3. **API Info**: Add `/api/info` to the URL

### Monitor Your Application
- **Application Insights**: Check the Azure portal for performance metrics
- **App Service Logs**: View logs in the Azure portal
- **Application Gateway Metrics**: Monitor load balancing performance

## Cleanup

To destroy the infrastructure:

#### Windows (PowerShell)
```powershell
.\scripts\deploy.ps1 -Environment staging -Destroy -AutoApprove
```

#### Linux/macOS (Bash)
```bash
./scripts/deploy.sh -e staging -d -a
```

## Cost Considerations

### Staging Environment
- **Estimated cost**: ~$200-300/month
- **App Service Plans**: 2x P1v3 instances
- **Application Gateway**: Standard_v2 with autoscaling

### Production Environment
- **Estimated cost**: ~$400-600/month
- **App Service Plans**: 2x P2v3 instances
- **Application Gateway**: WAF_v2 with higher capacity

## Troubleshooting

### Common Issues

1. **Azure CLI not logged in**
   ```bash
   az login
   ```

2. **Terraform not initialized**
   ```bash
   terraform init
   ```

3. **Permission errors**
   - Ensure you have Contributor role on the subscription
   - Check if all required resource providers are registered

4. **Deployment hangs or fails**
   - Check Azure Activity Log in the portal
   - Review Terraform logs for specific error messages

### Getting Help

1. **Review the logs**: Check the detailed error messages in the terminal
2. **Azure portal**: Check the Activity Log for any resource creation issues
3. **Terraform state**: Use `terraform show` to see the current state
4. **Re-run with debug**: Set `TF_LOG=DEBUG` for detailed Terraform logs

## Next Steps

1. **Configure custom domain**: Replace the Application Gateway self-signed certificate
2. **Set up CI/CD**: Use Azure DevOps or GitHub Actions for automated deployments
3. **Configure monitoring**: Set up alerts and monitoring dashboards
4. **Scale testing**: Test the autoscaling capabilities under load
5. **Security hardening**: Review and tighten network security groups

## Support

For issues with this template:
1. Check the README.md for detailed documentation
2. Review the troubleshooting section
3. Check Azure documentation for specific service issues