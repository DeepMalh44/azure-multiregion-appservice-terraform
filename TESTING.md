# Quick Test Guide

## Testing Your Deployment

After cloning this repository and deploying the infrastructure, you can test the application using these commands:

### 1. Test the Beautiful Wishes Page
```powershell
Invoke-WebRequest -Uri "http://agw-hello-world-app-6e716b99-e556fbad.eastus.cloudapp.azure.com/wishes"
```

### 2. Test Health Endpoint
```powershell
Invoke-WebRequest -Uri "http://agw-hello-world-app-6e716b99-e556fbad.eastus.cloudapp.azure.com/health"
```

### 3. Test API Info Endpoint
```powershell
Invoke-WebRequest -Uri "http://agw-hello-world-app-6e716b99-e556fbad.eastus.cloudapp.azure.com/api/info"
```

### 4. Open in Browser
```powershell
Start-Process "http://agw-hello-world-app-6e716b99-e556fbad.eastus.cloudapp.azure.com/wishes"
```

## Re-deployment Commands

### Deploy Infrastructure
```powershell
terraform init
terraform plan
terraform apply
```

### Deploy Application to Both Regions
```powershell
cd app

# Deploy to East US
az webapp up --name app-hello-world-app-eastus-6e716b99 --resource-group rg-hello-world-app-eastus-6e716b99 --runtime "node:20-lts" --os-type Linux

# Deploy to West US 2  
az webapp up --name app-hello-world-app-westus2-6e716b99 --resource-group rg-hello-world-app-westus2-6e716b99 --runtime "node:20-lts" --os-type Linux --plan asp-hello-world-app-westus2-6e716b99
```

## Expected Results

- Status Code 200 for all endpoints
- Beautiful animated wishes page with "Good Day Today! All Your Wishes Come True"
- JSON responses from health and API endpoints showing region information
- Load balancing working across both regions

---
*Last Updated: October 25, 2025*