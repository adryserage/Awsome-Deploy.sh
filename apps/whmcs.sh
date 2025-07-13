#!/bin/bash

# WHMCS Installation Script
# This script installs WHMCS, a web hosting billing & automation platform

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
echo -e "${GREEN}         WHMCS Installation Menu        ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Installation options
echo "1. Install WHMCS with Docker (recommended)"
echo "2. Install WHMCS with traditional LAMP stack"
echo ""

read -p "Select installation method [1-2]: " INSTALL_METHOD

case $INSTALL_METHOD in
    1)
        # Docker installation
        info "Installing WHMCS with Docker"
        
        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            error "Docker is not installed. Please install Docker first."
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            error "Docker Compose is not installed. Please install Docker Compose first."
        fi
        
        # Ask for installation directory
        read -p "Enter installation directory (default: ./whmcs): " INSTALL_DIR
        INSTALL_DIR=${INSTALL_DIR:-"./whmcs"}
        
        # Create directory if it doesn't exist
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR" || error "Failed to change to installation directory"
        
        # Ask for database credentials
        read -p "Enter MySQL root password (default: random): " MYSQL_ROOT_PASSWORD
        MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(openssl rand -base64 12)}
        
        read -p "Enter WHMCS database name (default: whmcs): " WHMCS_DB_NAME
        WHMCS_DB_NAME=${WHMCS_DB_NAME:-"whmcs"}
        
        read -p "Enter WHMCS database user (default: whmcs_user): " WHMCS_DB_USER
        WHMCS_DB_USER=${WHMCS_DB_USER:-"whmcs_user"}
        
        read -p "Enter WHMCS database password (default: random): " WHMCS_DB_PASSWORD
        WHMCS_DB_PASSWORD=${WHMCS_DB_PASSWORD:-$(openssl rand -base64 12)}
        
        read -p "Enter web port (default: 8080): " WEB_PORT
        WEB_PORT=${WEB_PORT:-"8080"}
        
        # Create docker-compose.yml file
        info "Creating Docker Compose configuration"
        cat > docker-compose.yml << EOL
version: '3'

services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${WHMCS_DB_NAME}
      MYSQL_USER: ${WHMCS_DB_USER}
      MYSQL_PASSWORD: ${WHMCS_DB_PASSWORD}

  web:
    image: php:7.4-apache
    depends_on:
      - db
    volumes:
      - ./html:/var/www/html
    ports:
      - "${WEB_PORT}:80"
    restart: unless-stopped

volumes:
  db_data:
 EOL
        
        # Start the containers
        info "Starting Docker containers"
        docker-compose up -d || error "Failed to start containers"
        
        # Wait for the database to initialize
        info "Waiting for database initialization..."
        sleep 10
        
        # Create the html directory if it doesn't exist
        mkdir -p html
        
        # Install required PHP extensions
        info "Installing required PHP extensions"
        docker-compose exec web apt-get update
        docker-compose exec web apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev zip unzip wget
        docker-compose exec web docker-php-ext-configure gd --with-freetype --with-jpeg
        docker-compose exec web docker-php-ext-install gd mysqli pdo pdo_mysql
        
        # Download WHMCS
        info "You need to manually download WHMCS from your client area at whmcs.com"
        info "After downloading, extract the files to the '${INSTALL_DIR}/html' directory"
        
        success "Docker environment for WHMCS has been set up!"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "Database Information:"
        echo -e "Host: db"
        echo -e "Database Name: ${WHMCS_DB_NAME}"
        echo -e "Database User: ${WHMCS_DB_USER}"
        echo -e "Database Password: ${WHMCS_DB_PASSWORD}"
        echo -e "${GREEN}=======================================${NC}"
        # Get server IP
        SERVER_IP=$(get_server_ip)
        echo -e "Access WHMCS at http://${SERVER_IP}:${WEB_PORT}"
        echo -e "Complete the installation through the web interface"
        echo -e "${GREEN}=======================================${NC}"
        ;;
        
    2)
        # Traditional installation
        info "Installing WHMCS with traditional LAMP stack"
        
        # Check for required commands
        for cmd in wget php mysql; do
            if ! command -v $cmd &> /dev/null; then
                error "$cmd is not installed. Please install it first."
            fi
        done
        
        # Ask for MySQL password
        read -p "Enter MySQL root password: " MYSQL_PASSWORD
        if [ -z "$MYSQL_PASSWORD" ]; then
            error "MySQL password cannot be empty"
        fi
        
        # Ask for WHMCS version
        read -p "Enter WHMCS version to install (default: 8.3.0): " WHMCS_VERSION
        WHMCS_VERSION=${WHMCS_VERSION:-"8.3.0"}
        
        # Download the deployment script
        info "Downloading WHMCS deployment script"
        wget -O deploy.sh https://files.scripting.online/whmcs/whmcs-${WHMCS_VERSION}.sh || error "Failed to download deployment script"
        
        # Make the script executable
        chmod +x deploy.sh || error "Failed to make deployment script executable"
        
        # Run the deployment script
        info "Running WHMCS deployment script"
        ./deploy.sh "$MYSQL_PASSWORD" || error "WHMCS deployment failed"
        
        success "WHMCS has been successfully installed!"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "Access WHMCS through your domain"
        echo -e "Complete the installation through the web interface"
        echo -e "${GREEN}=======================================${NC}"
        ;;
        
    *)
        error "Invalid option. Please select 1 or 2."
        ;;
esac
