#!/bin/bash

# YunoHost Installation Script
# This script installs YunoHost, a self-hosting platform

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

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Create menu for installation options
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}        YunoHost Installation Menu      ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Installation options
echo "1. Install YunoHost on a fresh Debian system"
echo "2. Install YunoHost with Docker"
echo "3. Install YunoHost on a VPS"
echo ""

read -p "Select installation method [1-3]: " INSTALL_METHOD

case $INSTALL_METHOD in
    1)
        # Standard installation on a fresh Debian system
        info "Installing YunoHost on a fresh Debian system"
        
        # Check if running on Debian
        if [ ! -f /etc/debian_version ]; then
            error "This installation method requires a Debian-based system"
        fi
        
        # Ask for installation options
        read -p "Do you want to perform a full installation? (Y/n): " FULL_INSTALL
        if [[ "$FULL_INSTALL" =~ ^[Nn]$ ]]; then
            INSTALL_OPTS="-d"
            info "Performing a minimal installation"
        else
            INSTALL_OPTS=""
            info "Performing a full installation"
        fi
        
        # Update package lists
        info "Updating package lists"
        apt-get update || error "Failed to update package lists"
        
        # Install curl if not already installed
        if ! command -v curl &> /dev/null; then
            info "Installing curl"
            apt-get install -y curl || error "Failed to install curl"
        fi
        
        # Run the YunoHost installation script
        info "Running YunoHost installation script"
        curl https://install.yunohost.org | bash $INSTALL_OPTS || error "YunoHost installation failed"
        
        success "YunoHost has been successfully installed!"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "You can now configure YunoHost by running:"
        echo -e "yunohost tools postinstall"
        echo -e "${GREEN}=======================================${NC}"
        ;;
        
    2)
        # Docker installation
        info "Installing YunoHost with Docker"
        
        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            error "Docker is not installed. Please install Docker first."
        fi
        
        # Ask for installation directory
        read -p "Enter data directory (default: ./yunohost_data): " DATA_DIR
        DATA_DIR=${DATA_DIR:-"./yunohost_data"}
        
        # Create data directory if it doesn't exist
        mkdir -p "$DATA_DIR"
        
        # Ask for port configuration
        read -p "Enter HTTP port (default: 80): " HTTP_PORT
        HTTP_PORT=${HTTP_PORT:-"80"}
        
        read -p "Enter HTTPS port (default: 443): " HTTPS_PORT
        HTTPS_PORT=${HTTPS_PORT:-"443"}
        
        read -p "Enter SSH port (default: 2222): " SSH_PORT
        SSH_PORT=${SSH_PORT:-"2222"}
        
        # Pull the YunoHost Docker image
        info "Pulling the YunoHost Docker image"
        docker pull yunohost/yunohost:latest || error "Failed to pull YunoHost Docker image"
        
        # Run the YunoHost Docker container
        info "Starting YunoHost Docker container"
        docker run -d \
            --name=yunohost \
            --restart=unless-stopped \
            --publish=${HTTP_PORT}:80 \
            --publish=${HTTPS_PORT}:443 \
            --publish=${SSH_PORT}:22 \
            --volume=${DATA_DIR}:/data \
            --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
            yunohost/yunohost:latest || error "Failed to start YunoHost Docker container"
        
        success "YunoHost Docker container has been started!"
        echo -e "${GREEN}=======================================${NC}"
        # Get server IP
        SERVER_IP=$(get_server_ip)
        echo -e "Access YunoHost at: https://${SERVER_IP}"
        echo -e "SSH access: ssh -p ${SSH_PORT} root@${SERVER_IP}"
        echo -e "Data directory: ${DATA_DIR}"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "To complete the installation, run:"
        echo -e "docker exec -it yunohost yunohost tools postinstall"
        echo -e "${GREEN}=======================================${NC}"
        ;;
        
    3)
        # VPS installation
        info "Installing YunoHost on a VPS"
        
        # Check if running on Debian
        if [ ! -f /etc/debian_version ]; then
            error "This installation method requires a Debian-based system"
        fi
        
        # Update package lists
        info "Updating package lists"
        apt-get update || error "Failed to update package lists"
        
        # Install required packages
        info "Installing required packages"
        apt-get install -y curl wget git || error "Failed to install required packages"
        
        # Clone the YunoHost install script repository
        info "Cloning YunoHost install script repository"
        git clone https://github.com/YunoHost/install_script /tmp/install_script || error "Failed to clone repository"
        
        # Run the installation script
        info "Running YunoHost installation script"
        cd /tmp/install_script && ./install_yunohost || error "YunoHost installation failed"
        
        success "YunoHost has been successfully installed!"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "You can now configure YunoHost by running:"
        echo -e "yunohost tools postinstall"
        echo -e "${GREEN}=======================================${NC}"
        ;;
        
    *)
        error "Invalid option. Please select 1, 2, or 3."
        ;;
esac
