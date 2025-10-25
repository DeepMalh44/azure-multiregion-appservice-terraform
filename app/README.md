# Hello World App for Azure App Service

This is a simple Node.js application that demonstrates a Hello World service running on Azure App Service.

## Features

- Health check endpoint at `/health`
- Information endpoint at `/api/info`
- Environment-aware responses
- Request metadata logging
- Multi-region deployment support

## Endpoints

- `GET /` - Main Hello World endpoint
- `GET /health` - Health check for Application Gateway probes
- `GET /api/info` - Application and system information

## Environment Variables

The application uses the following environment variables:

- `PORT` - Server port (default: 3000)
- `APP_ENV` - Application environment (staging/production)
- `APP_REGION` - Azure region where the app is deployed
- `WEBSITE_INSTANCE_ID` - Azure App Service instance identifier

## Local Development

```bash
npm install
npm run dev
```

## Deployment

This application is designed to be deployed to Azure App Service using the Terraform configuration in this repository.
