#!/bin/bash

# Remote Backup Script
# This script provides options for backing up data to various remote storage providers

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
if [ -f "$(dirname "$0")/../utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/../utils/get_server_ip.sh"
fi

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Create menu for backup options
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}        Remote Backup Options          ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Backup options
echo "1. Configure AWS S3 Backup"
echo "2. Configure Google Cloud Storage Backup"
echo "3. Configure SFTP/SCP Remote Server Backup"
echo "4. Configure Dropbox Backup"
echo "5. Configure OneDrive Backup"
echo "6. Schedule Automated Backups"
echo "7. Restore from Remote Backup"
echo "8. Exit"
echo ""

read -p "Select an option [1-8]: " BACKUP_OPTION

# Function to check if a package is installed
check_package() {
    if ! command -v "$1" &> /dev/null; then
        info "Installing $1..."
        apt-get update && apt-get install -y "$1" || error "Failed to install $1"
    fi
}

# Function to create backup directory
create_backup_dir() {
    local backup_dir="$1"
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir" || error "Failed to create backup directory"
    fi
}

# Function to configure AWS S3 backup
configure_aws_s3() {
    info "Configuring AWS S3 Backup"
    
    # Check for required packages
    check_package "awscli"
    
    # Ask for AWS credentials
    read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY
    read -p "Enter AWS Secret Access Key: " AWS_SECRET_KEY
    read -p "Enter AWS Region (default: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-"us-east-1"}
    read -p "Enter S3 Bucket Name: " S3_BUCKET
    read -p "Enter backup directory path to backup: " BACKUP_SOURCE
    read -p "Enter backup prefix in S3 (default: backup): " S3_PREFIX
    S3_PREFIX=${S3_PREFIX:-"backup"}
    
    # Configure AWS CLI
    mkdir -p ~/.aws
    cat > ~/.aws/credentials << EOL
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
EOL

    cat > ~/.aws/config << EOL
[default]
region = ${AWS_REGION}
output = json
EOL

    # Create backup script
    local backup_script="/usr/local/bin/s3-backup.sh"
    cat > "$backup_script" << EOL
#!/bin/bash
DATE=\$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/tmp/backup-\$DATE"
mkdir -p "\$BACKUP_DIR"

# Source the server IP utility if available
if [ -f "$(dirname "$0")/../utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/../utils/get_server_ip.sh"
fi

# Get server IP for logging
SERVER_IP=\$(get_server_ip)

# Create backup
tar -czf "\$BACKUP_DIR/backup-\$DATE.tar.gz" -C "${BACKUP_SOURCE}" .

# Upload to S3
aws s3 cp "\$BACKUP_DIR/backup-\$DATE.tar.gz" "s3://${S3_BUCKET}/${S3_PREFIX}/\$SERVER_IP/backup-\$DATE.tar.gz"

# Clean up
rm -rf "\$BACKUP_DIR"
EOL

    chmod +x "$backup_script"
    
    # Create cron job
    read -p "Do you want to schedule regular backups? (y/n): " SCHEDULE_BACKUP
    if [[ "$SCHEDULE_BACKUP" =~ ^[Yy]$ ]]; then
        read -p "Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM): " CRON_SCHEDULE
        (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $backup_script") | crontab -
        success "Backup scheduled with cron: $CRON_SCHEDULE"
    fi
    
    success "AWS S3 backup configured successfully"
    info "You can run manual backups with: $backup_script"
}

# Function to configure Google Cloud Storage backup
configure_gcs() {
    info "Configuring Google Cloud Storage Backup"
    
    # Check for required packages
    if ! command -v gsutil &> /dev/null; then
        info "Installing Google Cloud SDK..."
        export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
        echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        apt-get update && apt-get install -y google-cloud-sdk || error "Failed to install Google Cloud SDK"
    fi
    
    # Ask for GCS details
    read -p "Enter path to Google Cloud service account key JSON file: " GCS_KEY_FILE
    read -p "Enter GCS Bucket Name: " GCS_BUCKET
    read -p "Enter backup directory path to backup: " BACKUP_SOURCE
    read -p "Enter backup prefix in GCS (default: backup): " GCS_PREFIX
    GCS_PREFIX=${GCS_PREFIX:-"backup"}
    
    # Authenticate with service account
    gcloud auth activate-service-account --key-file="$GCS_KEY_FILE" || error "Failed to authenticate with Google Cloud"
    
    # Create backup script
    local backup_script="/usr/local/bin/gcs-backup.sh"
    cat > "$backup_script" << EOL
#!/bin/bash
DATE=\$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/tmp/backup-\$DATE"
mkdir -p "\$BACKUP_DIR"

# Source the server IP utility if available
if [ -f "$(dirname "$0")/../utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/../utils/get_server_ip.sh"
fi

# Get server IP for logging
SERVER_IP=\$(get_server_ip)

# Create backup
tar -czf "\$BACKUP_DIR/backup-\$DATE.tar.gz" -C "${BACKUP_SOURCE}" .

# Upload to GCS
gsutil cp "\$BACKUP_DIR/backup-\$DATE.tar.gz" "gs://${GCS_BUCKET}/${GCS_PREFIX}/\$SERVER_IP/backup-\$DATE.tar.gz"

# Clean up
rm -rf "\$BACKUP_DIR"
EOL

    chmod +x "$backup_script"
    
    # Create cron job
    read -p "Do you want to schedule regular backups? (y/n): " SCHEDULE_BACKUP
    if [[ "$SCHEDULE_BACKUP" =~ ^[Yy]$ ]]; then
        read -p "Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM): " CRON_SCHEDULE
        (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $backup_script") | crontab -
        success "Backup scheduled with cron: $CRON_SCHEDULE"
    fi
    
    success "Google Cloud Storage backup configured successfully"
    info "You can run manual backups with: $backup_script"
}

# Function to configure SFTP/SCP backup
configure_sftp() {
    info "Configuring SFTP/SCP Remote Server Backup"
    
    # Check for required packages
    check_package "openssh-client"
    
    # Ask for SFTP details
    read -p "Enter remote server hostname or IP: " REMOTE_HOST
    read -p "Enter remote server port (default: 22): " REMOTE_PORT
    REMOTE_PORT=${REMOTE_PORT:-"22"}
    read -p "Enter remote server username: " REMOTE_USER
    read -p "Enter remote server backup path: " REMOTE_PATH
    read -p "Enter local directory path to backup: " BACKUP_SOURCE
    read -p "Use SSH key authentication? (y/n): " USE_SSH_KEY
    
    # Setup SSH key if requested
    if [[ "$USE_SSH_KEY" =~ ^[Yy]$ ]]; then
        if [ ! -f ~/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        fi
        
        info "Copy this SSH public key to your remote server's authorized_keys file:"
        cat ~/.ssh/id_rsa.pub
        read -p "Press Enter when you have added the key to the remote server..."
    fi
    
    # Create backup script
    local backup_script="/usr/local/bin/sftp-backup.sh"
    cat > "$backup_script" << EOL
#!/bin/bash
DATE=\$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/tmp/backup-\$DATE"
mkdir -p "\$BACKUP_DIR"

# Source the server IP utility if available
if [ -f "$(dirname "$0")/../utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/../utils/get_server_ip.sh"
fi

# Get server IP for logging
SERVER_IP=\$(get_server_ip)

# Create backup
tar -czf "\$BACKUP_DIR/backup-\$DATE.tar.gz" -C "${BACKUP_SOURCE}" .

# Upload to remote server
scp -P ${REMOTE_PORT} "\$BACKUP_DIR/backup-\$DATE.tar.gz" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/\$SERVER_IP/backup-\$DATE.tar.gz

# Clean up
rm -rf "\$BACKUP_DIR"
EOL

    chmod +x "$backup_script"
    
    # Create cron job
    read -p "Do you want to schedule regular backups? (y/n): " SCHEDULE_BACKUP
    if [[ "$SCHEDULE_BACKUP" =~ ^[Yy]$ ]]; then
        read -p "Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM): " CRON_SCHEDULE
        (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $backup_script") | crontab -
        success "Backup scheduled with cron: $CRON_SCHEDULE"
    fi
    
    success "SFTP/SCP backup configured successfully"
    info "You can run manual backups with: $backup_script"
}

# Function to configure Dropbox backup
configure_dropbox() {
    info "Configuring Dropbox Backup"
    
    # Check for required packages
    check_package "curl"
    
    # Install Dropbox Uploader script
    if [ ! -f "/usr/local/bin/dropbox_uploader.sh" ]; then
        info "Installing Dropbox Uploader script..."
        curl -s https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh -o /usr/local/bin/dropbox_uploader.sh
        chmod +x /usr/local/bin/dropbox_uploader.sh
    fi
    
    # Configure Dropbox Uploader
    info "Please follow the instructions to link this server with your Dropbox account:"
    /usr/local/bin/dropbox_uploader.sh
    
    # Ask for backup details
    read -p "Enter local directory path to backup: " BACKUP_SOURCE
    read -p "Enter Dropbox folder for backups (default: Backups): " DROPBOX_FOLDER
    DROPBOX_FOLDER=${DROPBOX_FOLDER:-"Backups"}
    
    # Create backup script
    local backup_script="/usr/local/bin/dropbox-backup.sh"
    cat > "$backup_script" << EOL
#!/bin/bash
DATE=\$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/tmp/backup-\$DATE"
mkdir -p "\$BACKUP_DIR"

# Source the server IP utility if available
if [ -f "$(dirname "$0")/../utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/../utils/get_server_ip.sh"
fi

# Get server IP for logging
SERVER_IP=\$(get_server_ip)

# Create backup
tar -czf "\$BACKUP_DIR/backup-\$DATE.tar.gz" -C "${BACKUP_SOURCE}" .

# Upload to Dropbox
/usr/local/bin/dropbox_uploader.sh mkdir "${DROPBOX_FOLDER}/\$SERVER_IP"
/usr/local/bin/dropbox_uploader.sh upload "\$BACKUP_DIR/backup-\$DATE.tar.gz" "${DROPBOX_FOLDER}/\$SERVER_IP/backup-\$DATE.tar.gz"

# Clean up
rm -rf "\$BACKUP_DIR"
EOL

    chmod +x "$backup_script"
    
    # Create cron job
    read -p "Do you want to schedule regular backups? (y/n): " SCHEDULE_BACKUP
    if [[ "$SCHEDULE_BACKUP" =~ ^[Yy]$ ]]; then
        read -p "Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM): " CRON_SCHEDULE
        (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $backup_script") | crontab -
        success "Backup scheduled with cron: $CRON_SCHEDULE"
    fi
    
    success "Dropbox backup configured successfully"
    info "You can run manual backups with: $backup_script"
}

# Function to configure OneDrive backup
configure_onedrive() {
    info "Configuring OneDrive Backup"
    
    # Check for required packages
    check_package "curl"
    check_package "git"
    
    # Install OneDrive client if not already installed
    if ! command -v onedrive &> /dev/null; then
        info "Installing OneDrive client..."
        apt-get update
        apt-get install -y build-essential libcurl4-openssl-dev libsqlite3-dev pkg-config git curl libnotify-dev
        git clone https://github.com/abraunegg/onedrive.git /tmp/onedrive
        cd /tmp/onedrive
        ./configure
        make
        make install
        cd -
        rm -rf /tmp/onedrive
    fi
    
    # Configure OneDrive
    info "Please follow the instructions to link this server with your OneDrive account:"
    onedrive
    
    # Ask for backup details
    read -p "Enter local directory path to backup: " BACKUP_SOURCE
    read -p "Enter OneDrive folder for backups (default: Backups): " ONEDRIVE_FOLDER
    ONEDRIVE_FOLDER=${ONEDRIVE_FOLDER:-"Backups"}
    
    # Create OneDrive config directory if it doesn't exist
    mkdir -p ~/.config/onedrive
    
    # Create backup script
    local backup_script="/usr/local/bin/onedrive-backup.sh"
    cat > "$backup_script" << EOL
#!/bin/bash
DATE=\$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/tmp/backup-\$DATE"
mkdir -p "\$BACKUP_DIR"

# Source the server IP utility if available
if [ -f "$(dirname "$0")/../utils/get_server_ip.sh" ]; then
    source "$(dirname "$0")/../utils/get_server_ip.sh"
fi

# Get server IP for logging
SERVER_IP=\$(get_server_ip)

# Create backup
tar -czf "\$BACKUP_DIR/backup-\$DATE.tar.gz" -C "${BACKUP_SOURCE}" .

# Create OneDrive backup folder
mkdir -p ~/OneDrive/${ONEDRIVE_FOLDER}/\$SERVER_IP
cp "\$BACKUP_DIR/backup-\$DATE.tar.gz" ~/OneDrive/${ONEDRIVE_FOLDER}/\$SERVER_IP/

# Sync with OneDrive
onedrive --synchronize --verbose

# Clean up
rm -rf "\$BACKUP_DIR"
EOL

    chmod +x "$backup_script"
    
    # Create cron job
    read -p "Do you want to schedule regular backups? (y/n): " SCHEDULE_BACKUP
    if [[ "$SCHEDULE_BACKUP" =~ ^[Yy]$ ]]; then
        read -p "Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM): " CRON_SCHEDULE
        (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $backup_script") | crontab -
        success "Backup scheduled with cron: $CRON_SCHEDULE"
    fi
    
    success "OneDrive backup configured successfully"
    info "You can run manual backups with: $backup_script"
}

# Function to schedule automated backups
schedule_backups() {
    info "Scheduling Automated Backups"
    
    # List available backup scripts
    echo "Available backup scripts:"
    ls -1 /usr/local/bin/*-backup.sh 2>/dev/null || echo "No backup scripts found"
    echo ""
    
    read -p "Enter the full path to the backup script: " BACKUP_SCRIPT
    
    if [ ! -f "$BACKUP_SCRIPT" ]; then
        error "Backup script not found: $BACKUP_SCRIPT"
    fi
    
    # Ask for schedule
    echo "Common cron schedule examples:"
    echo "- Daily at midnight: 0 0 * * *"
    echo "- Weekly on Sunday at 2 AM: 0 2 * * 0"
    echo "- Monthly on the 1st at 3 AM: 0 3 1 * *"
    echo "- Every 6 hours: 0 */6 * * *"
    echo ""
    
    read -p "Enter cron schedule: " CRON_SCHEDULE
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $BACKUP_SCRIPT") | crontab -
    
    success "Backup scheduled with cron: $CRON_SCHEDULE"
}

# Function to restore from backup
restore_from_backup() {
    info "Restore from Remote Backup"
    
    # List available backup methods
    echo "Available backup methods:"
    echo "1. AWS S3"
    echo "2. Google Cloud Storage"
    echo "3. SFTP/SCP Remote Server"
    echo "4. Dropbox"
    echo "5. OneDrive"
    echo ""
    
    read -p "Select backup method to restore from [1-5]: " RESTORE_METHOD
    
    case $RESTORE_METHOD in
        1)
            # AWS S3 restore
            check_package "awscli"
            read -p "Enter S3 Bucket Name: " S3_BUCKET
            read -p "Enter S3 backup prefix: " S3_PREFIX
            read -p "Enter server IP in backup path (default: use current): " SERVER_IP
            
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP=$(get_server_ip)
            fi
            
            # List available backups
            info "Available backups:"
            aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/${SERVER_IP}/"
            
            read -p "Enter backup file name to restore: " BACKUP_FILE
            read -p "Enter directory to restore to: " RESTORE_DIR
            
            mkdir -p "$RESTORE_DIR"
            
            # Download and extract backup
            aws s3 cp "s3://${S3_BUCKET}/${S3_PREFIX}/${SERVER_IP}/${BACKUP_FILE}" /tmp/
            tar -xzf "/tmp/${BACKUP_FILE}" -C "$RESTORE_DIR"
            rm "/tmp/${BACKUP_FILE}"
            
            success "Backup restored to $RESTORE_DIR"
            ;;
            
        2)
            # GCS restore
            if ! command -v gsutil &> /dev/null; then
                error "Google Cloud SDK not installed. Please configure GCS backup first."
            fi
            
            read -p "Enter GCS Bucket Name: " GCS_BUCKET
            read -p "Enter GCS backup prefix: " GCS_PREFIX
            read -p "Enter server IP in backup path (default: use current): " SERVER_IP
            
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP=$(get_server_ip)
            fi
            
            # List available backups
            info "Available backups:"
            gsutil ls "gs://${GCS_BUCKET}/${GCS_PREFIX}/${SERVER_IP}/"
            
            read -p "Enter backup file name to restore: " BACKUP_FILE
            read -p "Enter directory to restore to: " RESTORE_DIR
            
            mkdir -p "$RESTORE_DIR"
            
            # Download and extract backup
            gsutil cp "gs://${GCS_BUCKET}/${GCS_PREFIX}/${SERVER_IP}/${BACKUP_FILE}" /tmp/
            tar -xzf "/tmp/${BACKUP_FILE}" -C "$RESTORE_DIR"
            rm "/tmp/${BACKUP_FILE}"
            
            success "Backup restored to $RESTORE_DIR"
            ;;
            
        3)
            # SFTP/SCP restore
            check_package "openssh-client"
            
            read -p "Enter remote server hostname or IP: " REMOTE_HOST
            read -p "Enter remote server port (default: 22): " REMOTE_PORT
            REMOTE_PORT=${REMOTE_PORT:-"22"}
            read -p "Enter remote server username: " REMOTE_USER
            read -p "Enter remote server backup path: " REMOTE_PATH
            read -p "Enter server IP in backup path (default: use current): " SERVER_IP
            
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP=$(get_server_ip)
            fi
            
            # List available backups
            info "Available backups (you may need to enter password):"
            ssh -p "$REMOTE_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "ls -la ${REMOTE_PATH}/${SERVER_IP}/"
            
            read -p "Enter backup file name to restore: " BACKUP_FILE
            read -p "Enter directory to restore to: " RESTORE_DIR
            
            mkdir -p "$RESTORE_DIR"
            
            # Download and extract backup
            scp -P "$REMOTE_PORT" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/${SERVER_IP}/${BACKUP_FILE}" /tmp/
            tar -xzf "/tmp/${BACKUP_FILE}" -C "$RESTORE_DIR"
            rm "/tmp/${BACKUP_FILE}"
            
            success "Backup restored to $RESTORE_DIR"
            ;;
            
        4)
            # Dropbox restore
            if [ ! -f "/usr/local/bin/dropbox_uploader.sh" ]; then
                error "Dropbox Uploader not installed. Please configure Dropbox backup first."
            fi
            
            read -p "Enter Dropbox folder for backups: " DROPBOX_FOLDER
            read -p "Enter server IP in backup path (default: use current): " SERVER_IP
            
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP=$(get_server_ip)
            fi
            
            # List available backups
            info "Available backups:"
            /usr/local/bin/dropbox_uploader.sh list "${DROPBOX_FOLDER}/${SERVER_IP}"
            
            read -p "Enter backup file name to restore: " BACKUP_FILE
            read -p "Enter directory to restore to: " RESTORE_DIR
            
            mkdir -p "$RESTORE_DIR"
            
            # Download and extract backup
            /usr/local/bin/dropbox_uploader.sh download "${DROPBOX_FOLDER}/${SERVER_IP}/${BACKUP_FILE}" /tmp/
            tar -xzf "/tmp/${BACKUP_FILE}" -C "$RESTORE_DIR"
            rm "/tmp/${BACKUP_FILE}"
            
            success "Backup restored to $RESTORE_DIR"
            ;;
            
        5)
            # OneDrive restore
            if ! command -v onedrive &> /dev/null; then
                error "OneDrive client not installed. Please configure OneDrive backup first."
            fi
            
            read -p "Enter OneDrive folder for backups: " ONEDRIVE_FOLDER
            read -p "Enter server IP in backup path (default: use current): " SERVER_IP
            
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP=$(get_server_ip)
            fi
            
            # Sync with OneDrive
            info "Syncing with OneDrive..."
            onedrive --synchronize --verbose
            
            # List available backups
            info "Available backups:"
            ls -la ~/OneDrive/${ONEDRIVE_FOLDER}/${SERVER_IP}/
            
            read -p "Enter backup file name to restore: " BACKUP_FILE
            read -p "Enter directory to restore to: " RESTORE_DIR
            
            mkdir -p "$RESTORE_DIR"
            
            # Extract backup
            cp ~/OneDrive/${ONEDRIVE_FOLDER}/${SERVER_IP}/${BACKUP_FILE} /tmp/
            tar -xzf "/tmp/${BACKUP_FILE}" -C "$RESTORE_DIR"
            rm "/tmp/${BACKUP_FILE}"
            
            success "Backup restored to $RESTORE_DIR"
            ;;
            
        *)
            error "Invalid option. Please select 1-5."
            ;;
    esac
}

# Process user selection
case $BACKUP_OPTION in
    1)
        configure_aws_s3
        ;;
    2)
        configure_gcs
        ;;
    3)
        configure_sftp
        ;;
    4)
        configure_dropbox
        ;;
    5)
        configure_onedrive
        ;;
    6)
        schedule_backups
        ;;
    7)
        restore_from_backup
        ;;
    8)
        info "Exiting"
        exit 0
        ;;
    *)
        error "Invalid option. Please select 1-8."
        ;;
esac
