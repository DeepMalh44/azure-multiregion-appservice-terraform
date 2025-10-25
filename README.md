
# Azure Multi-Region App Service Template

A Terraform template that sets up a Hello World application across multiple Azure regions with load balancing and high availability.

## What This Does

This template creates:

- App Services in East US and West US 2
- Application Gateway to handle traffic and load balancing
- Virtual networks with isolated subnets
- Security groups and monitoring
- A simple Node.js Hello World app

## Project Structure

```text
AppServiceTerraform/
├── main.tf                     # Main configuration
├── variables.tf                # Variables
├── outputs.tf                  # Outputs
├── modules/
│   ├── networking/             # Networks and subnets
│   ├── app-service/            # App Service setup
│   └── application-gateway/    # Load balancer
├── environments/
│   ├── staging/
│   └── production/
├── app/                        # Node.js Hello World app
└── scripts/
    └── deploy.ps1              # Deployment script
```

## Requirements

- Azure CLI
- Terraform (version 1.0 or later)
- PowerShell (Windows) or Bash (Linux/Mac)
- An Azure subscription

## Getting Started

### Option 1: Automated Deployment (Recommended)

Use the PowerShell deployment script for complete infrastructure and application deployment:

```powershell
# 1. Login to Azure
az login

# 2. Deploy everything to staging (infrastructure + application)
.\scripts\deploy.ps1 -Environment staging -AutoApprove

# 3. Deploy everything to production (infrastructure + application)  
.\scripts\deploy.ps1 -Environment production
```

### Option 2: Infrastructure Only

Deploy only the infrastructure without the application:

```powershell
# Deploy only infrastructure to staging
.\scripts\deploy.ps1 -Environment staging -SkipAppDeployment -AutoApprove

# Later, deploy just the application
.\scripts\deploy-app-only.ps1
```

### Option 3: Manual Terraform Commands

1. **Login to Azure**

   ```bash
   az login
   ```

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Deploy to staging**

   ```bash
   terraform plan -var-file="environments/staging/terraform.tfvars"
   terraform apply -var-file="environments/staging/terraform.tfvars"
   ```

4. **Deploy to production**

   ```bash
   terraform plan -var-file="environments/production/terraform.tfvars"
   terraform apply -var-file="environments/production/terraform.tfvars"
   ```

## What Gets Created

After deployment, you'll have:

- Two App Services running your application
- An Application Gateway with a public IP
- Virtual networks in both regions
- Monitoring and health checks
- Network security rules

## Testing Your Deployment

Once deployed, Terraform will output the Application Gateway URL. You can test:

- Main app: `http://your-gateway-url/`
- Health check: `http://your-gateway-url/health`
- App info: `http://your-gateway-url/api/info`

## Configuration

Key settings in `terraform.tfvars`:

- `project_name` - Name for your resources
- `environment` - staging or production
- `primary_region` - First region (default: eastus)
- `secondary_region` - Second region (default: westus2)
- `app_service_sku` - App Service size (default: S1)

## Cleanup

To remove everything:

```bash
terraform destroy -var-file="environments/staging/terraform.tfvars"
```

## The Hello World App

The included Node.js app provides:

- Basic "Hello World" response
- Health check endpoint for monitoring
- System information endpoint
- Request details for debugging

## Common Issues

**Permission errors**: Make sure you're logged into Azure CLI and have the right subscription selected.

**Resource conflicts**: If names are taken, change the `project_name` variable.

**Region availability**: Some regions might not have all services. Stick with the defaults unless you need specific regions.

## Customizing

- Modify the app in the `app/` folder
- Adjust Terraform variables for different configurations
- Add more regions by extending the modules
- Change the App Service SKU for more/less power

## Cost Considerations

This setup uses Standard S1 App Services by default, which cost about $75/month per region. For testing, you might want to use the staging environment with smaller instances.

The Application Gateway adds additional cost but provides the load balancing and high availability features.

## Security Notes

The App Services are placed in private subnets and only accessible through the Application Gateway. Network Security Groups limit traffic between components.

For production use, consider:

- Adding custom SSL certificates
- Implementing Web Application Firewall rules
- Setting up private endpoints
- Configuring backup and disaster recovery

## Support

This is a template to get you started. For production deployments, review and adjust the configuration based on your specific requirements.

Check the Azure documentation for detailed information about each service and best practices.
