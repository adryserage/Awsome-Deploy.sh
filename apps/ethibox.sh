#!/usr/bin/env bash
# shellcheck shell=bash

# Ethibox Installation Script
# This script installs Ethibox, an open-source web app hoster

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
PORT=3000
DATA_DIR="/var/lib/ethibox"

# Create menu for installation options
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}       Ethibox Installation Menu       ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Ask for port configuration
read -p "Enter the port for Ethibox (default: 3000): " USER_PORT
if [ ! -z "$USER_PORT" ]; then
    PORT=$USER_PORT
fi

# Ask for data directory
read -p "Enter the data directory path (default: /var/lib/ethibox): " USER_DATA_DIR
if [ ! -z "$USER_DATA_DIR" ]; then
    DATA_DIR=$USER_DATA_DIR
fi

# Create data directory if it doesn't exist
if [ ! -d "$DATA_DIR" ]; then
    info "Creating data directory at $DATA_DIR"
    mkdir -p "$DATA_DIR" || error "Failed to create data directory"
fi

# Check if Ethibox container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^ethibox$"; then
    warning "Ethibox container already exists."
    read -p "Do you want to remove it and create a new one? (y/n): " REMOVE_CONTAINER
    if [[ "$REMOVE_CONTAINER" =~ ^[Yy]$ ]]; then
        info "Removing existing Ethibox container"
        docker rm -f ethibox || error "Failed to remove existing container"
    else
        error "Installation aborted. Existing container was not removed."
    fi
fi

# Pull the latest image
info "Pulling the latest Ethibox image"
docker pull ethibox/ethibox || error "Failed to pull Ethibox image"

# Run the container
info "Starting Ethibox container"
docker run -d \
    --name ethibox \
    -p "${PORT}:3000" \
    -v "${DATA_DIR}:/data" \
    --restart unless-stopped \
    ethibox/ethibox

# Check if container is running
if docker ps | grep -q "ethibox"; then
    success "Ethibox has been successfully installed!"
    echo -e "${GREEN}=======================================${NC}"
    # Get server IP
    SERVER_IP=$(get_server_ip)
    echo -e "Access Ethibox at http://${SERVER_IP}:${PORT}"
    echo -e "Data is stored in ${DATA_DIR}"
    echo -e "${GREEN}=======================================${NC}"
else
    error "Failed to start Ethibox container. Check docker logs for more information."
fi
