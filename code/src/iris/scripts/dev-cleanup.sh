#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="./"
NGINX_PID_FILE="$PROJECT_DIR/logs/nginx.pid"

print_status() {
    echo -e "${BLUE}[TERRATEAM-CLEANUP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[TERRATEAM-CLEANUP]${NC} $1"
}

print_status "Cleaning up development environment..."

# Stop nginx
if [ -f "$NGINX_PID_FILE" ]; then
    print_status "Stopping nginx..."
    kill $(cat "$NGINX_PID_FILE") 2>/dev/null || true
    rm -f "$NGINX_PID_FILE" 2>/dev/null || true
fi

# Kill any remaining nginx processes with our config
pkill -f "nginx.*$PROJECT_DIR/nginx.conf" 2>/dev/null || true

# Kill any proxy servers
pkill -f "proxy\|simple-proxy" 2>/dev/null || true

# Kill any node processes in this directory (Vite, etc.)
pkill -f "node.*vite\|vite" 2>/dev/null || true

# Remove hosts entry (optional - comment out if you want to keep it)
# sudo sed -i '/127.0.0.1 app.terrateam.io/d' /etc/hosts

print_success "Development environment cleaned up"
print_status "Note: /etc/hosts entry for app.terrateam.io is preserved"
print_status "Run 'sudo sed -i \"/127.0.0.1 app.terrateam.io/d\" /etc/hosts' to remove it"
