#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="./"
NGINX_PID_FILE="$PROJECT_DIR/logs/nginx.pid"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[TERRATEAM-DEV]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[TERRATEAM-DEV]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[TERRATEAM-DEV]${NC} $1"
}

print_error() {
    echo -e "${RED}[TERRATEAM-DEV]${NC} $1"
}

# Cleanup function
cleanup() {
    print_status "Shutting down development environment..."
    
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
    
    print_success "Development environment stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    print_error "nginx is not installed. Please install it first:"
    print_error "  sudo apt update && sudo apt install nginx"
    exit 1
fi

# Check if authbind is installed
if ! command -v authbind &> /dev/null; then
    print_error "authbind is not installed. Please install it first:"
    print_error "  sudo apt update && sudo apt install authbind"
    exit 1
fi

# Check if authbind is configured for ports 80 and 443
if [ ! -f "/etc/authbind/byport/80" ] || [ ! -f "/etc/authbind/byport/443" ]; then
    print_error "authbind is not configured for ports 80 and 443. Please run:"
    print_error "  sudo touch /etc/authbind/byport/80 /etc/authbind/byport/443"
    print_error "  sudo chown $USER:$USER /etc/authbind/byport/80 /etc/authbind/byport/443"
    print_error "  sudo chmod 755 /etc/authbind/byport/80 /etc/authbind/byport/443"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this script as root."
    exit 1
fi

print_status "Starting Terrateam development environment..."

# Change to project directory
cd "$PROJECT_DIR"

# Check if /etc/hosts entry exists
if ! grep -q "127.0.0.1 app.terrateam.io" /etc/hosts; then
    print_status "Adding app.terrateam.io to /etc/hosts..."
    echo "127.0.0.1 app.terrateam.io" | sudo tee -a /etc/hosts > /dev/null
    print_success "Added app.terrateam.io to /etc/hosts"
fi

# Check if SSL certificates exist
if [ ! -f "ssl-certs/app.terrateam.io.crt" ] || [ ! -f "ssl-certs/app.terrateam.io.key" ]; then
    print_status "Creating SSL certificates..."
    mkdir -p ssl-certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl-certs/app.terrateam.io.key \
        -out ssl-certs/app.terrateam.io.crt \
        -subj "/C=US/ST=Dev/L=Local/O=Development/CN=app.terrateam.io" > /dev/null 2>&1
    print_success "SSL certificates created"
fi

# Create nginx directories
print_status "Setting up nginx directories..."
mkdir -p logs/client_temp logs/proxy_temp logs/fastcgi_temp logs/uwsgi_temp logs/scgi_temp

# Stop any existing nginx processes using our config
pkill -f "nginx.*$PROJECT_DIR/nginx.conf" 2>/dev/null || true

# Start nginx with authbind (no sudo needed!)
print_status "Starting nginx reverse proxy with authbind..."
authbind --deep nginx -c "$PROJECT_DIR/nginx.conf" -p "$PROJECT_DIR" 2>"$PROJECT_DIR/logs/nginx_startup.log"
if [ $? -eq 0 ]; then
    print_success "Nginx started successfully on ports 80/443 without root!"
    print_status "Logs are written to: $PROJECT_DIR/logs/"
else
    print_error "Failed to start nginx"
    exit 1
fi

# Wait a moment for nginx to fully start
sleep 2

# Start Vite dev server
print_status "Starting Vite development server..."
print_warning "Press Ctrl+C to stop all services"
print_success "Development environment ready!"
print_success "Open your browser to: https://app.terrateam.io"
print_warning "You'll need to accept the self-signed certificate"

# Start Vite (this will block)
npm run dev

# This line will be reached when Vite is stopped
cleanup
