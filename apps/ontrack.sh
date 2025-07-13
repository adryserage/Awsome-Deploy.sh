#!/bin/bash

# OnTrack Installation Script
# This script installs OnTrack, a personal expense tracking app

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

# Create menu for installation options
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}        OnTrack Installation Menu       ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Installation options
echo "1. Install with Docker (recommended)"
echo "2. Install with Homebrew (macOS only)"
echo "3. Install manually (Ruby on Rails)"
echo ""

read -p "Select installation method [1-3]: " INSTALL_METHOD

case $INSTALL_METHOD in
    1)
        # Docker installation
        info "Installing OnTrack with Docker"
        
        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            error "Docker is not installed. Please install Docker first."
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            error "Docker Compose is not installed. Please install Docker Compose first."
        fi
        
        # Ask for installation directory
        read -p "Enter installation directory (default: ./ontrack): " INSTALL_DIR
        INSTALL_DIR=${INSTALL_DIR:-"./ontrack"}
        
        # Create directory if it doesn't exist
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR" || error "Failed to change to installation directory"
        
        # Clone the repository
        info "Cloning OnTrack repository"
        if [ -d ".git" ]; then
            warning "Git repository already exists in this directory."
            read -p "Do you want to update it? (y/n): " UPDATE_REPO
            if [[ "$UPDATE_REPO" =~ ^[Yy]$ ]]; then
                git pull || error "Failed to update repository"
            fi
        else
            git clone https://github.com/inoda/ontrack . || error "Failed to clone repository"
        fi
        
        # Create docker-compose.yml file
        info "Creating Docker Compose configuration"
        cat > docker-compose.yml << EOL
version: '3'

services:
  db:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ontrack_password
      POSTGRES_USER: ontrack
      POSTGRES_DB: ontrack_production
    restart: unless-stopped

  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgres://ontrack:ontrack_password@db/ontrack_production
      RAILS_ENV: production
      SECRET_KEY_BASE: $(openssl rand -hex 64)
    restart: unless-stopped

volumes:
  postgres_data:
 EOL
        
        # Create Dockerfile if it doesn't exist
        if [ ! -f "Dockerfile" ]; then
            info "Creating Dockerfile"
            cat > Dockerfile << EOL
FROM ruby:3.0

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client yarn
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY . /app

RUN yarn install
RUN bundle exec rake assets:precompile

CMD ["rails", "server", "-b", "0.0.0.0"]
EOL
        fi
        
        # Build and start the containers
        info "Building and starting OnTrack containers"
        docker-compose build || error "Failed to build containers"
        docker-compose up -d || error "Failed to start containers"
        
        # Wait for the application to start
        info "Waiting for OnTrack to start..."
        sleep 10
        
        # Setup the database
        info "Setting up the database"
        docker-compose exec web rails db:setup || warning "Database setup may have failed. You might need to run 'docker-compose exec web rails db:setup' manually."
        
        success "OnTrack has been successfully installed with Docker!"
        echo -e "${GREEN}=======================================${NC}"
        # Get server IP
        SERVER_IP=$(get_server_ip)
        echo -e "Access OnTrack at http://${SERVER_IP}:3000"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "To stop OnTrack: docker-compose down"
        echo -e "To start OnTrack: docker-compose up -d"
        echo -e "To view logs: docker-compose logs -f"
        ;;
        
    2)
        # Homebrew installation (macOS only)
        info "Installing OnTrack with Homebrew"
        
        # Check if running on macOS
        if [[ "$(uname)" != "Darwin" ]]; then
            error "Homebrew installation is only supported on macOS."
        fi
        
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            error "Homebrew is not installed. Please install Homebrew first."
        fi
        
        # Clone the repository
        info "Cloning OnTrack repository"
        git clone https://github.com/inoda/ontrack || error "Failed to clone repository"
        cd ontrack || error "Failed to change to ontrack directory"
        
        # Install with Homebrew script
        info "Running Homebrew installation script"
        if [ -f "scripts/install_with_brew.sh" ]; then
            sh scripts/install_with_brew.sh || error "Homebrew installation script failed"
        else
            error "Homebrew installation script not found"
        fi
        
        success "OnTrack has been successfully installed with Homebrew!"
        ;;
        
    3)
        # Manual installation
        info "Installing OnTrack manually"
        
        # Check for required dependencies
        for cmd in ruby gem bundle yarn; do
            if ! command -v $cmd &> /dev/null; then
                error "$cmd is not installed. Please install it first."
            fi
        done
        
        # Clone the repository
        info "Cloning OnTrack repository"
        git clone https://github.com/inoda/ontrack || error "Failed to clone repository"
        cd ontrack || error "Failed to change to ontrack directory"
        
        # Install dependencies
        info "Installing Ruby dependencies"
        bundle install || error "Failed to install Ruby dependencies"
        
        info "Installing JavaScript dependencies"
        yarn install || error "Failed to install JavaScript dependencies"
        
        # Setup database
        info "Setting up database"
        bundle exec rails db:setup || error "Failed to setup database"
        
        # Precompile assets
        info "Precompiling assets"
        bundle exec rails assets:precompile || warning "Failed to precompile assets"
        
        success "OnTrack has been successfully installed manually!"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "To start the server: bundle exec rails server"
        # Get server IP
        SERVER_IP=$(get_server_ip)
        echo -e "Then access OnTrack at http://${SERVER_IP}:3000"
        echo -e "${GREEN}=======================================${NC}"
        ;;
        
    *)
        error "Invalid option. Please select 1, 2, or 3."
        ;;
esac

