#!/bin/bash

# Main Menu Script for Awsome-Deploy.sh
# This script provides a central interface to access all available scripts

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

# Source the server IP utility if available
if [ -f "$(dirname "$0")/utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/utils/get_server_ip.sh"
fi

# Function to display progress bar
show_progress() {
    local duration=$1
    local step=0.1
    local progress=0
    local total_steps=$(echo "$duration / $step" | bc)
    local bar_length=40
    
    echo -ne "Progress: ["
    
    while [ $(echo "$progress < $duration" | bc) -eq 1 ]; do
        local current_step=$(echo "$progress / $duration * $bar_length" | bc -l)
        local current_step_int=${current_step%.*}
        
        echo -ne "${GREEN}"
        for ((i=0; i<current_step_int; i++)); do
            echo -ne "#"
        done
        
        for ((i=current_step_int; i<bar_length; i++)); do
            echo -ne " "
        done
        
        local percent=$(echo "$progress / $duration * 100" | bc -l)
        echo -ne "${NC}] ${percent%.*}%\r"
        
        sleep $step
        progress=$(echo "$progress + $step" | bc)
    done
    
    echo -ne "Progress: [${GREEN}"
    for ((i=0; i<bar_length; i++)); do
        echo -ne "#"
    done
    echo -e "${NC}] 100%"
}

# Function to check if a script exists
check_script() {
    if [ ! -f "$1" ]; then
        warning "Script not found: $1"
        return 1
    fi
    return 0
}

# Function to make a script executable and run it
run_script() {
    local script_path="$1"
    
    if check_script "$script_path"; then
        chmod +x "$script_path"
        clear
        info "Running $(basename "$script_path")..."
        "$script_path"
        echo ""
        read -p "Press Enter to return to the main menu..."
    else
        read -p "Press Enter to return to the main menu..."
    fi
}

# Function to display the main menu
show_main_menu() {
    clear
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}                 AWSOME-DEPLOY.SH                     ${NC}"
    echo -e "${GREEN}           Scripts That Make Life Easier              ${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    
    # Get server IP
    local server_ip=$(get_server_ip)
    echo -e "Server IP: ${BLUE}$server_ip${NC}"
    echo ""
    
    echo -e "${YELLOW}CORE SCRIPTS:${NC}"
    echo "1) System Management (basic.sh)"
    echo "2) Docker Setup (docker.sh)"
    echo ""
    
    echo -e "${YELLOW}APPLICATION SCRIPTS:${NC}"
    echo "3) WordPress"
    echo "4) NextCloud"
    echo "5) Gitea"
    echo "6) Monitoring Tools (Prometheus, Grafana)"
    echo "7) Database Servers"
    echo "8) Ethibox"
    echo "9) n8n Workflow Automation"
    echo "10) Nginx Proxy Manager"
    echo "11) OnTrack Expense Tracker"
    echo "12) WHMCS Billing Platform"
    echo "13) YunoHost Self-Hosting Platform"
    echo ""
    
    echo -e "${YELLOW}SECURITY SCRIPTS:${NC}"
    echo "14) Firewall Configuration"
    echo "15) Automatic Updates"
    echo "16) SSL Certificate Management"
    echo "17) User Management"
    echo ""
    
    echo -e "${YELLOW}MAINTENANCE SCRIPTS:${NC}"
    echo "18) Docker Backup"
    echo "19) Remote Backup Solutions"
    echo ""
    
    echo -e "${YELLOW}UTILITIES:${NC}"
    echo "20) Documentation"
    echo "21) Troubleshooting"
    echo "22) Check for Updates"
    echo ""
    
    echo "0) Exit"
    echo ""
}

# Function to display documentation
show_documentation() {
    clear
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}                 DOCUMENTATION                        ${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Available Documentation:${NC}"
    echo "1) Basic Usage Guide"
    echo "2) Docker Scripts"
    echo "3) Application Scripts"
    echo "4) Security Scripts"
    echo "5) Maintenance Scripts"
    echo "6) Troubleshooting"
    echo ""
    echo "0) Back to Main Menu"
    echo ""
    
    read -p "Select documentation to view: " DOC_OPTION
    
    case $DOC_OPTION in
        1)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 BASIC USAGE GUIDE                    ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            echo "Awsome-Deploy.sh is a collection of bash scripts designed to simplify"
            echo "system setup, Docker deployments, and application installations."
            echo ""
            echo "To use any script:"
            echo "1. Make sure the script is executable (chmod +x script_name.sh)"
            echo "2. Run the script with ./script_name.sh"
            echo "3. Follow the on-screen prompts"
            echo ""
            echo "Most scripts require root privileges, so you may need to use sudo."
            echo ""
            read -p "Press Enter to return to documentation menu..."
            show_documentation
            ;;
        2)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 DOCKER SCRIPTS                       ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            echo "docker.sh - Docker Setup Script"
            echo "- Installs Docker and Docker Compose"
            echo "- Sets up Docker network and volumes"
            echo "- Installs common Docker utilities"
            echo ""
            echo "Usage: ./docker.sh"
            echo ""
            read -p "Press Enter to return to documentation menu..."
            show_documentation
            ;;
        3)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 APPLICATION SCRIPTS                  ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            echo "apps/wordpress.sh - WordPress Installation"
            echo "- Installs WordPress with MySQL backend"
            echo "- Configurable ports and credentials"
            echo ""
            echo "apps/nextcloud.sh - NextCloud Installation"
            echo "- Installs NextCloud with PostgreSQL backend"
            echo "- Configurable admin credentials and ports"
            echo ""
            echo "apps/gitea.sh - Gitea Installation"
            echo "- Installs lightweight Git service"
            echo "- Configurable HTTP and SSH ports"
            echo ""
            echo "apps/monitoring.sh - Monitoring Tools"
            echo "- Installs Prometheus and Grafana"
            echo "- Pre-configured dashboards"
            echo ""
            echo "apps/databases.sh - Database Servers"
            echo "- Installs MySQL, PostgreSQL, or MongoDB"
            echo "- Configurable ports and credentials"
            echo ""
            echo "apps/ethibox.sh - Ethibox Installation"
            echo "- Installs open-source web app hoster"
            echo "- Configurable port settings"
            echo ""
            echo "apps/n8n.sh - n8n Workflow Automation"
            echo "- Installs workflow automation platform"
            echo "- Configurable authentication and ports"
            echo ""
            echo "apps/nginx-proxy.sh - Nginx Proxy Manager"
            echo "- Installs proxy manager with SSL support"
            echo "- Configurable ports and settings"
            echo ""
            echo "apps/ontrack.sh - OnTrack Expense Tracker"
            echo "- Installs personal expense tracking app"
            echo "- Multiple installation methods"
            echo ""
            echo "apps/whmcs.sh - WHMCS Billing Platform"
            echo "- Installs web hosting billing platform"
            echo "- Docker or traditional installation"
            echo ""
            echo "apps/yunohost.sh - YunoHost Self-Hosting"
            echo "- Installs self-hosting platform"
            echo "- Multiple installation methods"
            echo ""
            read -p "Press Enter to return to documentation menu..."
            show_documentation
            ;;
        4)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 SECURITY SCRIPTS                     ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            echo "security/firewall.sh - Firewall Configuration"
            echo "- UFW-based firewall setup"
            echo "- Predefined profiles and custom rules"
            echo ""
            echo "security/auto_updates.sh - Automatic Updates"
            echo "- Configures unattended-upgrades"
            echo "- Email notification options"
            echo ""
            echo "security/ssl_manager.sh - SSL Certificate Management"
            echo "- Certbot installation and configuration"
            echo "- Certificate renewal and management"
            echo ""
            echo "security/user_management.sh - User Management"
            echo "- User creation and management"
            echo "- SSH hardening and security audits"
            echo ""
            read -p "Press Enter to return to documentation menu..."
            show_documentation
            ;;
        5)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 MAINTENANCE SCRIPTS                  ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            echo "maintenance/backup.sh - Docker Backup"
            echo "- Backup and restore Docker containers and volumes"
            echo "- Scheduled automatic backups"
            echo ""
            echo "maintenance/remote_backup.sh - Remote Backup Solutions"
            echo "- Configure backups to cloud storage"
            echo "- Multiple provider options (AWS, GCP, SFTP, etc.)"
            echo ""
            read -p "Press Enter to return to documentation menu..."
            show_documentation
            ;;
        6)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 TROUBLESHOOTING                      ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            echo "Common Issues and Solutions:"
            echo ""
            echo "1. Docker container fails to start"
            echo "   - Check if ports are already in use"
            echo "   - Check if container name already exists"
            echo "   - Check Docker logs: docker logs container_name"
            echo ""
            echo "2. Permission denied errors"
            echo "   - Make sure scripts are executable: chmod +x script.sh"
            echo "   - Run with sudo if required"
            echo ""
            echo "3. Network connectivity issues"
            echo "   - Check if Docker network exists: docker network ls"
            echo "   - Check firewall settings: sudo ufw status"
            echo ""
            echo "4. Database connection errors"
            echo "   - Verify database credentials"
            echo "   - Check if database container is running"
            echo ""
            echo "5. SSL certificate errors"
            echo "   - Ensure domain points to server IP"
            echo "   - Check certificate expiration: certbot certificates"
            echo ""
            read -p "Press Enter to return to documentation menu..."
            show_documentation
            ;;
        0)
            return
            ;;
        *)
            warning "Invalid option"
            read -p "Press Enter to try again..."
            show_documentation
            ;;
    esac
}

# Function to display troubleshooting menu
show_troubleshooting() {
    clear
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}                 TROUBLESHOOTING                      ${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Diagnostic Tools:${NC}"
    echo "1) Check Docker Status"
    echo "2) Check System Resources"
    echo "3) Check Network Configuration"
    echo "4) Check Disk Space"
    echo "5) View Docker Logs"
    echo "6) View System Logs"
    echo ""
    echo "0) Back to Main Menu"
    echo ""
    
    read -p "Select a diagnostic tool: " DIAG_OPTION
    
    case $DIAG_OPTION in
        1)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 DOCKER STATUS                        ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            
            # Check if Docker is installed
            if ! command -v docker &> /dev/null; then
                error "Docker is not installed"
            fi
            
            info "Docker version:"
            docker --version
            echo ""
            
            info "Docker Compose version:"
            docker-compose --version 2>/dev/null || echo "Docker Compose not installed"
            echo ""
            
            info "Running containers:"
            docker ps
            echo ""
            
            info "Docker networks:"
            docker network ls
            echo ""
            
            info "Docker volumes:"
            docker volume ls
            echo ""
            
            read -p "Press Enter to return to troubleshooting menu..."
            show_troubleshooting
            ;;
        2)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 SYSTEM RESOURCES                     ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            
            info "CPU usage:"
            top -bn1 | head -n 5
            echo ""
            
            info "Memory usage:"
            free -h
            echo ""
            
            info "Load average:"
            uptime
            echo ""
            
            read -p "Press Enter to return to troubleshooting menu..."
            show_troubleshooting
            ;;
        3)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 NETWORK CONFIGURATION                ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            
            info "Network interfaces:"
            ip addr show
            echo ""
            
            info "Routing table:"
            ip route
            echo ""
            
            info "DNS configuration:"
            cat /etc/resolv.conf
            echo ""
            
            info "Open ports:"
            ss -tuln
            echo ""
            
            read -p "Press Enter to return to troubleshooting menu..."
            show_troubleshooting
            ;;
        4)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 DISK SPACE                           ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            
            info "Disk usage:"
            df -h
            echo ""
            
            info "Largest directories:"
            du -h --max-depth=1 / 2>/dev/null | sort -hr | head -n 10
            echo ""
            
            read -p "Press Enter to return to troubleshooting menu..."
            show_troubleshooting
            ;;
        5)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 DOCKER LOGS                          ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            
            # Check if Docker is installed
            if ! command -v docker &> /dev/null; then
                error "Docker is not installed"
            fi
            
            info "Available containers:"
            docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
            echo ""
            
            read -p "Enter container name to view logs (or press Enter to go back): " CONTAINER_NAME
            
            if [ -n "$CONTAINER_NAME" ]; then
                clear
                info "Logs for container: $CONTAINER_NAME"
                docker logs "$CONTAINER_NAME" 2>&1 | less
            fi
            
            show_troubleshooting
            ;;
        6)
            clear
            echo -e "${GREEN}=======================================================${NC}"
            echo -e "${GREEN}                 SYSTEM LOGS                          ${NC}"
            echo -e "${GREEN}=======================================================${NC}"
            echo ""
            
            info "Available logs:"
            echo "1) System log (syslog)"
            echo "2) Authentication log (auth.log)"
            echo "3) Kernel log (dmesg)"
            echo ""
            
            read -p "Select log to view (or press Enter to go back): " LOG_OPTION
            
            case $LOG_OPTION in
                1)
                    clear
                    info "System log (syslog):"
                    less /var/log/syslog
                    ;;
                2)
                    clear
                    info "Authentication log (auth.log):"
                    less /var/log/auth.log
                    ;;
                3)
                    clear
                    info "Kernel log (dmesg):"
                    dmesg | less
                    ;;
            esac
            
            show_troubleshooting
            ;;
        0)
            return
            ;;
        *)
            warning "Invalid option"
            read -p "Press Enter to try again..."
            show_troubleshooting
            ;;
    esac
}

# Function to check for updates
check_for_updates() {
    clear
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}                 CHECK FOR UPDATES                     ${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install git first."
    fi
    
    # Check if the current directory is a git repository
    if [ ! -d ".git" ]; then
        error "Not a git repository. Please run this script from the Awsome-Deploy.sh directory."
    fi
    
    info "Checking for updates..."
    echo ""
    
    # Show progress bar for 2 seconds
    show_progress 2
    
    # Fetch updates
    git fetch origin
    
    # Check if there are updates available
    local_rev=$(git rev-parse HEAD)
    remote_rev=$(git rev-parse origin/master)
    
    if [ "$local_rev" != "$remote_rev" ]; then
        success "Updates available!"
        echo ""
        info "Changes:"
        git log --oneline HEAD..origin/master
        echo ""
        
        read -p "Do you want to update now? (y/n): " UPDATE_NOW
        if [[ "$UPDATE_NOW" =~ ^[Yy]$ ]]; then
            info "Updating..."
            git pull origin master
            success "Update complete!"
        else
            info "Update skipped. You can update later with: git pull origin master"
        fi
    else
        success "You are already running the latest version!"
    fi
    
    echo ""
    read -p "Press Enter to return to the main menu..."
}

# Main loop
while true; do
    show_main_menu
    read -p "Enter your choice: " OPTION
    
    case $OPTION in
        1)
            run_script "$(dirname "$0")/basic.sh"
            ;;
        2)
            run_script "$(dirname "$0")/docker.sh"
            ;;
        3)
            run_script "$(dirname "$0")/apps/wordpress.sh"
            ;;
        4)
            run_script "$(dirname "$0")/apps/nextcloud.sh"
            ;;
        5)
            run_script "$(dirname "$0")/apps/gitea.sh"
            ;;
        6)
            run_script "$(dirname "$0")/apps/monitoring.sh"
            ;;
        7)
            run_script "$(dirname "$0")/apps/databases.sh"
            ;;
        8)
            run_script "$(dirname "$0")/apps/ethibox.sh"
            ;;
        9)
            run_script "$(dirname "$0")/apps/n8n.sh"
            ;;
        10)
            run_script "$(dirname "$0")/apps/nginx-proxy.sh"
            ;;
        11)
            run_script "$(dirname "$0")/apps/ontrack.sh"
            ;;
        12)
            run_script "$(dirname "$0")/apps/whmcs.sh"
            ;;
        13)
            run_script "$(dirname "$0")/apps/yunohost.sh"
            ;;
        14)
            run_script "$(dirname "$0")/security/firewall.sh"
            ;;
        15)
            run_script "$(dirname "$0")/security/auto_updates.sh"
            ;;
        16)
            run_script "$(dirname "$0")/security/ssl_manager.sh"
            ;;
        17)
            run_script "$(dirname "$0")/security/user_management.sh"
            ;;
        18)
            run_script "$(dirname "$0")/maintenance/backup.sh"
            ;;
        19)
            run_script "$(dirname "$0")/maintenance/remote_backup.sh"
            ;;
        20)
            show_documentation
            ;;
        21)
            show_troubleshooting
            ;;
        22)
            check_for_updates
            ;;
        0)
            clear
            success "Thank you for using Awsome-Deploy.sh!"
            exit 0
            ;;
        *)
            warning "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done
