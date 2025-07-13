#!/bin/bash

# n8n Installation Script
# This script installs n8n, a workflow automation platform

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
PORT=5678
DATA_VOLUME="n8n_data"
ENABLE_BASIC_AUTH="true"
N8N_USER="admin"
N8N_PASSWORD="$(openssl rand -base64 12)"
TIMEZONE="$(cat /etc/timezone 2>/dev/null || echo "UTC")"

# Create menu for installation options
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}          n8n Installation Menu         ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Ask for port configuration
read -p "Enter the port for n8n (default: 5678): " USER_PORT
if [ ! -z "$USER_PORT" ]; then
    PORT=$USER_PORT
fi

# Ask for basic auth configuration
read -p "Enable basic authentication? (Y/n): " ENABLE_AUTH
if [[ "$ENABLE_AUTH" =~ ^[Nn]$ ]]; then
    ENABLE_BASIC_AUTH="false"
else
    # Ask for username and password if auth is enabled
    read -p "Enter username for n8n (default: admin): " USER_USERNAME
    if [ ! -z "$USER_USERNAME" ]; then
        N8N_USER=$USER_USERNAME
    fi
    
    read -p "Enter password for n8n (leave blank for random): " USER_PASSWORD
    if [ ! -z "$USER_PASSWORD" ]; then
        N8N_PASSWORD=$USER_PASSWORD
    fi
    
    info "Using username: $N8N_USER and password: $N8N_PASSWORD"
fi

# Ask for timezone
read -p "Enter timezone (default: $TIMEZONE): " USER_TIMEZONE
if [ ! -z "$USER_TIMEZONE" ]; then
    TIMEZONE=$USER_TIMEZONE
fi

# Create Docker volume if it doesn't exist
if ! docker volume inspect $DATA_VOLUME &>/dev/null; then
    info "Creating Docker volume: $DATA_VOLUME"
    docker volume create $DATA_VOLUME || error "Failed to create Docker volume"
fi

# Check if n8n container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^n8n$"; then
    warning "n8n container already exists."
    read -p "Do you want to remove it and create a new one? (y/n): " REMOVE_CONTAINER
    if [[ "$REMOVE_CONTAINER" =~ ^[Yy]$ ]]; then
        info "Removing existing n8n container"
        docker rm -f n8n || error "Failed to remove existing container"
    else
        error "Installation aborted. Existing container was not removed."
    fi
fi

# Pull the latest image
info "Pulling the latest n8n image"
docker pull docker.n8n.io/n8nio/n8n || error "Failed to pull n8n image"

# Run the container
info "Starting n8n container"
if [ "$ENABLE_BASIC_AUTH" = "true" ]; then
    docker run -d \
        --name n8n \
        -p ${PORT}:5678 \
        -v ${DATA_VOLUME}:/home/node/.n8n \
        -e N8N_BASIC_AUTH_ACTIVE="true" \
        -e N8N_BASIC_AUTH_USER="${N8N_USER}" \
        -e N8N_BASIC_AUTH_PASSWORD="${N8N_PASSWORD}" \
        -e TZ="${TIMEZONE}" \
        --restart unless-stopped \
        docker.n8n.io/n8nio/n8n
else
    docker run -d \
        --name n8n \
        -p ${PORT}:5678 \
        -v ${DATA_VOLUME}:/home/node/.n8n \
        -e TZ="${TIMEZONE}" \
        --restart unless-stopped \
        docker.n8n.io/n8nio/n8n
fi

# Check if container is running
if docker ps | grep -q "n8n"; then
    success "n8n has been successfully installed!"
    echo -e "${GREEN}=======================================${NC}"
    # Get server IP
    SERVER_IP=$(get_server_ip)
    echo -e "Access n8n at http://${SERVER_IP}:${PORT}"
    if [ "$ENABLE_BASIC_AUTH" = "true" ]; then
        echo -e "Username: ${N8N_USER}"
        echo -e "Password: ${N8N_PASSWORD}"
        echo -e "Please save these credentials in a secure location."
    fi
    echo -e "${GREEN}=======================================${NC}"
else
    error "Failed to start n8n container. Check docker logs for more information."
fi
