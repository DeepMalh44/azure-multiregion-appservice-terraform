const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

// Middleware to parse JSON
app.use(express.json());

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Environment variables
const appEnv = process.env.APP_ENV || 'development';
const appRegion = process.env.APP_REGION || 'unknown';
const instanceId = process.env.WEBSITE_INSTANCE_ID || 'local';

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: appEnv,
    region: appRegion,
    instanceId: instanceId
  });
});

// Beautiful HTML page route
app.get('/wishes', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Root endpoint
app.get('/', (req, res) => {
  const responseData = {
    message: 'Hello World from Azure App Service!',
    timestamp: new Date().toISOString(),
    environment: appEnv,
    region: appRegion,
    instanceId: instanceId,
    requestHeaders: {
      'user-agent': req.get('User-Agent'),
      'x-forwarded-for': req.get('X-Forwarded-For'),
      'x-forwarded-proto': req.get('X-Forwarded-Proto'),
      'host': req.get('Host')
    }
  };

  res.json(responseData);
});

// API endpoint for testing
app.get('/api/info', (req, res) => {
  res.json({
    application: 'Hello World App',
    version: '1.0.0',
    environment: appEnv,
    region: appRegion,
    instanceId: instanceId,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    platform: process.platform,
    nodeVersion: process.version
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    timestamp: new Date().toISOString(),
    environment: appEnv
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    timestamp: new Date().toISOString(),
    environment: appEnv
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Hello World app listening on port ${port}`);
  console.log(`Environment: ${appEnv}`);
  console.log(`Region: ${appRegion}`);
  console.log(`Instance ID: ${instanceId}`);
});