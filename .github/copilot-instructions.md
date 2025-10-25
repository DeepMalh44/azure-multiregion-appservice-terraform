<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Azure App Service Terraform Project

This project contains Terraform configurations for deploying a multi-region Azure App Service with Azure Application Gateway for high availability and security.

## Project Structure
- `modules/` - Reusable Terraform modules
- `environments/` - Environment-specific configurations
- `app/` - Hello World application source code
- `scripts/` - Deployment and utility scripts

## Development Guidelines
- Follow Azure Terraform best practices
- Use modular design for reusability
- Implement proper variable validation
- Include comprehensive documentation
- Use consistent naming conventions