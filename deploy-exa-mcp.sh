#!/bin/bash
# Deployment script for Exa MCP server
# This script handles the deployment of the Exa MCP server to production

set -e

# Configuration
STAGING_DIR="${1:-/path/to/staging/exa-mcp-server}"
PROD_DIR="${2:-/path/to/production/exa-mcp-server}"
MCP_CONFIG="${3:-/path/to/production/.mcp.json}"
BACKUP_DIR="/path/to/backups/$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/var/log/exa-mcp-deploy-$(date +%Y%m%d-%H%M%S).log"
API_KEY_FILE="${4:-/path/to/secrets/exa_api_key}"

# Function for logging
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    log "ERROR: $1"
    log "Deployment failed. Rolling back..."
    if [ -d "$BACKUP_DIR" ] && [ -d "$PROD_DIR" ]; then
        rm -rf "$PROD_DIR"
        cp -r "$BACKUP_DIR" "$PROD_DIR"
        log "Rollback completed successfully."
    else
        log "Could not rollback. Manual intervention required."
    fi
    exit 1
}

# Check if staging directory exists
if [ ! -d "$STAGING_DIR" ]; then
    handle_error "Staging directory $STAGING_DIR does not exist"
fi

# Check if staging build exists
if [ ! -d "$STAGING_DIR/build" ]; then
    handle_error "Build directory $STAGING_DIR/build does not exist. Run staging setup first."
fi

# Create backup of production directory if it exists
if [ -d "$PROD_DIR" ]; then
    log "Creating backup of production directory..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROD_DIR" "$BACKUP_DIR"
    log "Backup created at $BACKUP_DIR"
fi

# Create or update production directory
log "Deploying to production directory..."
mkdir -p "$PROD_DIR"

# Copy files from staging to production
log "Copying files from staging to production..."
rsync -av --exclude=node_modules "$STAGING_DIR/" "$PROD_DIR/"

# Install dependencies in production
log "Installing dependencies in production..."
cd "$PROD_DIR"
npm ci --production

# Configure environment
if [ -f "$API_KEY_FILE" ]; then
    log "Configuring environment with API key..."
    API_KEY=$(cat "$API_KEY_FILE")
    echo "EXA_API_KEY=$API_KEY" > "$PROD_DIR/.env"
else
    handle_error "API key file not found: $API_KEY_FILE"
fi

# Update MCP configuration
if [ -f "$MCP_CONFIG" ]; then
    log "Updating MCP configuration..."
    # Use jq to update the configuration
    # This requires jq to be installed
    if command -v jq >/dev/null 2>&1; then
        TMP_CONFIG=$(mktemp)
        jq --arg path "$PROD_DIR/build/index.js" '.mcpServers.exa.args[0] = $path' "$MCP_CONFIG" > "$TMP_CONFIG"
        mv "$TMP_CONFIG" "$MCP_CONFIG"
    else
        log "Warning: jq not found. Could not update MCP configuration automatically."
        log "Please update $MCP_CONFIG manually to point to $PROD_DIR/build/index.js"
    fi
else
    handle_error "MCP configuration file not found: $MCP_CONFIG"
fi

# Test production instance
log "Testing production instance..."
cd "$PROD_DIR"
if node -e "
try {
    const index = require('./build/index.js');
    console.log('Server verification successful.');
} catch (error) {
    console.error('Server verification failed:', error);
    process.exit(1);
}"; then
    log "Production instance tested successfully."
else
    handle_error "Production instance test failed."
fi

log "Deployment completed successfully."
log "Exa MCP server is now available at: $PROD_DIR/build/index.js"
log "MCP configuration updated in: $MCP_CONFIG"

exit 0