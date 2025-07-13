#!/usr/bin/env bash
# shellcheck shell=bash

# Nginx Proxy Manager Installation Script
# This script installs Nginx Proxy Manager with automatic SSL certificate management

# Source the server IP utility
SCRIPT_DIR="$(dirname "$(dirname "$0")")"
source "$SCRIPT_DIR/utils/get_server_ip.sh"

# Color definitions
RED='\e[1;31m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
NC='\e[0m' # No Color

# Function to display messages
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Default values
HTTP_PORT=80
HTTPS_PORT=443
ADMIN_PORT=81
DEFAULT_HOST=""
DEFAULT_EMAIL=""
NETWORK_NAME="nginx-proxy-network"

# Create menu for installation options
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}    Nginx Proxy Manager Installation    ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Ask for port configuration
read -p "Enter HTTP port (default: 80): " USER_HTTP_PORT
if [ ! -z "$USER_HTTP_PORT" ]; then
    HTTP_PORT=$USER_HTTP_PORT
fi

read -p "Enter HTTPS port (default: 443): " USER_HTTPS_PORT
if [ ! -z "$USER_HTTPS_PORT" ]; then
    HTTPS_PORT=$USER_HTTPS_PORT
fi

read -p "Enter admin panel port (default: 81): " USER_ADMIN_PORT
if [ ! -z "$USER_ADMIN_PORT" ]; then
    ADMIN_PORT=$USER_ADMIN_PORT
fi

# Ask for default host
read -p "Enter default host (optional): " USER_DEFAULT_HOST
if [ ! -z "$USER_DEFAULT_HOST" ]; then
    DEFAULT_HOST=$USER_DEFAULT_HOST
fi

# Ask for default email for Let's Encrypt
read -p "Enter email for Let's Encrypt (required for SSL): " USER_EMAIL
if [ ! -z "$USER_EMAIL" ]; then
    DEFAULT_EMAIL=$USER_EMAIL
else
    warning "No email provided. SSL certificate generation may fail."
fi

# Create Docker network if it doesn't exist
if ! docker network inspect $NETWORK_NAME &>/dev/null; then
    info "Creating Docker network: $NETWORK_NAME"
    docker network create $NETWORK_NAME || error "Failed to create Docker network"
fi

# Create Docker volumes if they don't exist
for VOLUME in "certs" "vhost" "html" "acme"; do
    if ! docker volume inspect $VOLUME &>/dev/null; then
        info "Creating Docker volume: $VOLUME"
        docker volume create $VOLUME || error "Failed to create Docker volume: $VOLUME"
    fi
done

# Check if containers already exist
if docker ps -a --format '{{.Names}}' | grep -q "^nginx-proxy$"; then
    warning "Nginx Proxy container already exists."
    read -p "Do you want to remove it and create a new one? (y/n): " REMOVE_CONTAINER
    if [[ "$REMOVE_CONTAINER" =~ ^[Yy]$ ]]; then
        info "Removing existing Nginx Proxy container"
        docker rm -f nginx-proxy || error "Failed to remove existing container"
    else
        error "Installation aborted. Existing container was not removed."
    fi
fi

if docker ps -a --format '{{.Names}}' | grep -q "^nginx-proxy-acme$"; then
    warning "Nginx Proxy ACME companion container already exists."
    read -p "Do you want to remove it and create a new one? (y/n): " REMOVE_CONTAINER
    if [[ "$REMOVE_CONTAINER" =~ ^[Yy]$ ]]; then
        info "Removing existing Nginx Proxy ACME companion container"
        docker rm -f nginx-proxy-acme || error "Failed to remove existing container"
    else
        error "Installation aborted. Existing container was not removed."
    fi
fi

# Pull the latest images
info "Pulling the latest Nginx Proxy images"
docker pull nginxproxy/nginx-proxy || error "Failed to pull Nginx Proxy image"
docker pull nginxproxy/acme-companion || error "Failed to pull ACME companion image"

# Run the Nginx Proxy container
info "Starting Nginx Proxy container"
docker run --detach \
    --name nginx-proxy \
    --publish ${HTTP_PORT}:80 \
    --publish ${HTTPS_PORT}:443 \
    --publish ${ADMIN_PORT}:81 \
    --volume certs:/etc/nginx/certs \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    --network ${NETWORK_NAME} \
    --restart unless-stopped \
    -e HTTP_PORT=${HTTP_PORT} \
    -e HTTPS_PORT=${HTTPS_PORT} \
    ${DEFAULT_HOST:+-e DEFAULT_HOST=${DEFAULT_HOST}} \
    nginxproxy/nginx-proxy

# Run the ACME companion container
info "Starting ACME companion container"
docker run --detach \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --network ${NETWORK_NAME} \
    --restart unless-stopped \
    ${DEFAULT_EMAIL:+-e DEFAULT_EMAIL=${DEFAULT_EMAIL}} \
    nginxproxy/acme-companion

# Check if containers are running
if docker ps | grep -q "nginx-proxy" && docker ps | grep -q "nginx-proxy-acme"; then
    success "Nginx Proxy Manager has been successfully installed!"
    echo -e "${GREEN}=======================================${NC}"
    echo -e "HTTP Port: ${HTTP_PORT}"
    echo -e "HTTPS Port: ${HTTPS_PORT}"
    echo -e "Admin Port: ${ADMIN_PORT}"
    # Get server IP
    SERVER_IP=$(get_server_ip)
    echo -e "Access admin panel at http://${SERVER_IP}:${ADMIN_PORT}"
    echo -e "${GREEN}=======================================${NC}"
    echo -e "To use with other containers, connect them to the '${NETWORK_NAME}' network"
    echo -e "and set the following environment variables on your containers:"
    echo -e "  - VIRTUAL_HOST=your-domain.com"
    echo -e "  - VIRTUAL_PORT=container_port"
    echo -e "  - LETSENCRYPT_HOST=your-domain.com"
    echo -e "  - LETSENCRYPT_EMAIL=your-email@example.com"
    echo -e "${GREEN}=======================================${NC}"
else
    error "Failed to start containers. Check docker logs for more information."
fi
