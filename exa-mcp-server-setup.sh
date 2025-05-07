#!/bin/bash
# Setup script for the Exa MCP server in a staging environment

set -e

# Configuration variables
SOURCE_REPO="https://github.com/your-org/exa-mcp-server.git"
STAGING_DIR="/path/to/staging/exa-mcp-server"
API_KEY="your-production-api-key"  # Replace with actual API key in secure environment

# Create staging directory if it doesn't exist
mkdir -p $STAGING_DIR

# Clone or update the repository
if [ -d "$STAGING_DIR/.git" ]; then
    echo "Updating existing repository..."
    cd $STAGING_DIR
    git pull origin main
else
    echo "Cloning repository..."
    git clone $SOURCE_REPO $STAGING_DIR
    cd $STAGING_DIR
fi

# Install dependencies and build
echo "Installing dependencies..."
npm install

echo "Building application..."
npm run build

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    echo "EXA_API_KEY=$API_KEY" > .env
    echo "Environment file created."
else
    echo "Environment file already exists."
fi

# Check if build was successful
if [ -d "build" ]; then
    echo "Build completed successfully."
else
    echo "Build failed. Please check the logs."
    exit 1
fi

# Verify that the server can start
echo "Verifying server..."
node -e "
try {
    const index = require('./build/index.js');
    console.log('Server verification successful.');
} catch (error) {
    console.error('Server verification failed:', error);
    process.exit(1);
}"

echo "Exa MCP server setup complete. Server is ready for use in staging environment."
echo "Update the .mcp.json file to use the server from this location."
echo "Staging directory: $STAGING_DIR"