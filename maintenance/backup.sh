#!/bin/bash
# Docker Container and Volume Backup Script

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Default backup directory
BACKUP_DIR="/var/backups/docker"
DATE=$(date +%Y-%m-%d)
RETENTION_DAYS=7

echo "Docker Container and Volume Backup"
echo "=================================="
echo ""

# Menu options
PS3='Please select an option: '
options=(
  "Backup All Containers" 
  "Backup Specific Container" 
  "Backup All Volumes" 
  "Backup Specific Volume" 
  "Schedule Automatic Backups" 
  "Restore Container" 
  "Restore Volume" 
  "List Backups" 
  "Clean Old Backups" 
  "Configure Settings" 
  "Quit"
)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

select opt in "${options[@]}"
do
  case $opt in
    "Backup All Containers")
      echo "Backing up all Docker containers..."
      
      # Create container backup directory
      mkdir -p "$BACKUP_DIR/containers/$DATE"
      
      # Get list of running containers
      CONTAINERS=$(docker ps -q)
      
      if [ -z "$CONTAINERS" ]; then
        echo "No running containers found."
        continue
      fi
      
      # Backup each container
      for CONTAINER_ID in $CONTAINERS; do
        CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER_ID" | sed 's/\///')
        echo "Backing up container: $CONTAINER_NAME"
        
        # Export container
        docker export "$CONTAINER_ID" > "$BACKUP_DIR/containers/$DATE/$CONTAINER_NAME.tar"
        
        # Save container configuration
        docker inspect "$CONTAINER_ID" > "$BACKUP_DIR/containers/$DATE/$CONTAINER_NAME.json"
        
        echo "Container $CONTAINER_NAME backed up successfully."
      done
      
      echo "All containers backed up to $BACKUP_DIR/containers/$DATE/"
      ;;
      
    "Backup Specific Container")
      echo "Backing up a specific Docker container..."
      
      # List available containers
      echo "Available containers:"
      docker ps --format "{{.ID}}\t{{.Names}}\t{{.Image}}"
      
      read -p "Enter container name or ID: " CONTAINER
      
      # Check if container exists
      if ! docker ps -q -f "name=$CONTAINER" -f "id=$CONTAINER" | grep -q .; then
        echo "Container $CONTAINER not found or not running."
        continue
      fi
      
      # Create container backup directory
      mkdir -p "$BACKUP_DIR/containers/$DATE"
      
      # Get container name for filename
      CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER" | sed 's/\///')
      
      # Export container
      echo "Exporting container $CONTAINER_NAME..."
      docker export "$CONTAINER" > "$BACKUP_DIR/containers/$DATE/$CONTAINER_NAME.tar"
      
      # Save container configuration
      docker inspect "$CONTAINER" > "$BACKUP_DIR/containers/$DATE/$CONTAINER_NAME.json"
      
      echo "Container $CONTAINER_NAME backed up successfully to $BACKUP_DIR/containers/$DATE/"
      ;;
      
    "Backup All Volumes")
      echo "Backing up all Docker volumes..."
      
      # Create volume backup directory
      mkdir -p "$BACKUP_DIR/volumes/$DATE"
      
      # Get list of volumes
      VOLUMES=$(docker volume ls -q)
      
      if [ -z "$VOLUMES" ]; then
        echo "No volumes found."
        continue
      fi
      
      # Backup each volume
      for VOLUME in $VOLUMES; do
        echo "Backing up volume: $VOLUME"
        
        # Create temporary container to access volume
        TEMP_CONTAINER=$(docker run -d -v "$VOLUME:/volume" --name "backup-$VOLUME" alpine:latest sleep 300)
        
        # Tar the volume contents
        docker exec "backup-$VOLUME" tar -cf "/volume/$VOLUME.tar" -C /volume .
        
        # Copy the tar file from the container
        docker cp "backup-$VOLUME:/volume/$VOLUME.tar" "$BACKUP_DIR/volumes/$DATE/$VOLUME.tar"
        
        # Remove temporary container
        docker rm -f "backup-$VOLUME"
        
        echo "Volume $VOLUME backed up successfully."
      done
      
      echo "All volumes backed up to $BACKUP_DIR/volumes/$DATE/"
      ;;
      
    "Backup Specific Volume")
      echo "Backing up a specific Docker volume..."
      
      # List available volumes
      echo "Available volumes:"
      docker volume ls
      
      read -p "Enter volume name: " VOLUME
      
      # Check if volume exists
      if ! docker volume ls -q | grep -q "^$VOLUME$"; then
        echo "Volume $VOLUME not found."
        continue
      fi
      
      # Create volume backup directory
      mkdir -p "$BACKUP_DIR/volumes/$DATE"
      
      # Create temporary container to access volume
      echo "Creating temporary container to access volume..."
      TEMP_CONTAINER=$(docker run -d -v "$VOLUME:/volume" --name "backup-$VOLUME" alpine:latest sleep 300)
      
      # Tar the volume contents
      echo "Archiving volume contents..."
      docker exec "backup-$VOLUME" tar -cf "/volume/$VOLUME.tar" -C /volume .
      
      # Copy the tar file from the container
      echo "Copying backup file..."
      docker cp "backup-$VOLUME:/volume/$VOLUME.tar" "$BACKUP_DIR/volumes/$DATE/$VOLUME.tar"
      
      # Remove temporary container
      echo "Cleaning up temporary container..."
      docker rm -f "backup-$VOLUME"
      
      echo "Volume $VOLUME backed up successfully to $BACKUP_DIR/volumes/$DATE/$VOLUME.tar"
      ;;
      
    "Schedule Automatic Backups")
      echo "Setting up automatic backup schedule..."
      
      echo "Select backup frequency:"
      echo "1) Daily"
      echo "2) Weekly"
      echo "3) Monthly"
      read -p "Enter your choice (1-3): " freq_choice
      
      # Create backup script
      cat > /usr/local/bin/docker-backup.sh << 'EOF'
#!/bin/bash
# Automatic Docker backup script

BACKUP_DIR="/var/backups/docker"
DATE=$(date +%Y-%m-%d)

# Create backup directories
mkdir -p "$BACKUP_DIR/containers/$DATE"
mkdir -p "$BACKUP_DIR/volumes/$DATE"

# Backup containers
echo "Backing up containers..."
for CONTAINER_ID in $(docker ps -q); do
  CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER_ID" | sed 's/\///')
  docker export "$CONTAINER_ID" > "$BACKUP_DIR/containers/$DATE/$CONTAINER_NAME.tar"
  docker inspect "$CONTAINER_ID" > "$BACKUP_DIR/containers/$DATE/$CONTAINER_NAME.json"
done

# Backup volumes
echo "Backing up volumes..."
for VOLUME in $(docker volume ls -q); do
  TEMP_CONTAINER=$(docker run -d -v "$VOLUME:/volume" --name "backup-$VOLUME" alpine:latest sleep 300)
  docker exec "backup-$VOLUME" tar -cf "/volume/$VOLUME.tar" -C /volume .
  docker cp "backup-$VOLUME:/volume/$VOLUME.tar" "$BACKUP_DIR/volumes/$DATE/$VOLUME.tar"
  docker rm -f "backup-$VOLUME"
done

# Clean old backups (older than 7 days)
find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

echo "Backup completed: $(date)"
EOF
      
      chmod +x /usr/local/bin/docker-backup.sh
      
      # Set up cron job based on frequency
      case $freq_choice in
        1)
          # Daily at 2 AM
          (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/docker-backup.sh > /var/log/docker-backup.log 2>&1") | crontab -
          echo "Daily backup scheduled at 2:00 AM."
          ;;
        2)
          # Weekly on Sunday at 2 AM
          (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/docker-backup.sh > /var/log/docker-backup.log 2>&1") | crontab -
          echo "Weekly backup scheduled on Sunday at 2:00 AM."
          ;;
        3)
          # Monthly on the 1st at 2 AM
          (crontab -l 2>/dev/null; echo "0 2 1 * * /usr/local/bin/docker-backup.sh > /var/log/docker-backup.log 2>&1") | crontab -
          echo "Monthly backup scheduled on the 1st of each month at 2:00 AM."
          ;;
        *)
          echo "Invalid choice. No schedule set."
          ;;
      esac
      
      echo "Automatic backup schedule configured."
      echo "You can verify with: crontab -l"
      ;;
      
    "Restore Container")
      echo "Restoring a Docker container from backup..."
      
      # List available container backups
      echo "Available container backups:"
      find "$BACKUP_DIR/containers" -name "*.tar" | sort
      
      read -p "Enter full path to container backup file: " BACKUP_FILE
      
      if [ ! -f "$BACKUP_FILE" ]; then
        echo "Backup file not found: $BACKUP_FILE"
        continue
      fi
      
      # Get container name from backup file
      CONTAINER_NAME=$(basename "$BACKUP_FILE" .tar)
      
      # Check if container with same name exists
      if docker ps -a -q -f "name=$CONTAINER_NAME" | grep -q .; then
        read -p "Container $CONTAINER_NAME already exists. Replace it? (y/n): " replace
        if [ "$replace" = "y" ] || [ "$replace" = "Y" ]; then
          docker rm -f "$CONTAINER_NAME"
        else
          echo "Restoration cancelled."
          continue
        fi
      fi
      
      # Get configuration file
      CONFIG_FILE="${BACKUP_FILE%.tar}.json"
      
      if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found: $CONFIG_FILE"
        read -p "Enter image to use for restoration: " IMAGE
        
        # Import container without configuration
        cat "$BACKUP_FILE" | docker import - "$IMAGE:restored"
        echo "Container data imported as image $IMAGE:restored"
        echo "You will need to manually create a container from this image."
      else
        # Extract configuration from backup
        IMAGE=$(jq -r '.[0].Config.Image' "$CONFIG_FILE")
        PORTS=$(jq -r '.[0].HostConfig.PortBindings | to_entries | map("\(.key):\(.value[0].HostPort)") | join(" -p ")' "$CONFIG_FILE")
        VOLUMES=$(jq -r '.[0].HostConfig.Binds | join(" -v ")' "$CONFIG_FILE")
        ENV=$(jq -r '.[0].Config.Env | map("-e " + .) | join(" ")' "$CONFIG_FILE")
        
        # Import container
        cat "$BACKUP_FILE" | docker import - "$IMAGE:restored"
        
        # Create new container with similar configuration
        CMD="docker run -d --name $CONTAINER_NAME"
        
        if [ ! -z "$PORTS" ]; then
          CMD="$CMD -p $PORTS"
        fi
        
        if [ ! -z "$VOLUMES" ]; then
          CMD="$CMD -v $VOLUMES"
        fi
        
        if [ ! -z "$ENV" ]; then
          CMD="$CMD $ENV"
        fi
        
        CMD="$CMD $IMAGE:restored"
        
        echo "Executing: $CMD"
        eval "$CMD"
        
        echo "Container $CONTAINER_NAME restored successfully."
      fi
      ;;
      
    "Restore Volume")
      echo "Restoring a Docker volume from backup..."
      
      # List available volume backups
      echo "Available volume backups:"
      find "$BACKUP_DIR/volumes" -name "*.tar" | sort
      
      read -p "Enter full path to volume backup file: " BACKUP_FILE
      
      if [ ! -f "$BACKUP_FILE" ]; then
        echo "Backup file not found: $BACKUP_FILE"
        continue
      fi
      
      # Get volume name from backup file
      VOLUME_NAME=$(basename "$BACKUP_FILE" .tar)
      
      # Check if volume with same name exists
      if docker volume ls -q | grep -q "^$VOLUME_NAME$"; then
        read -p "Volume $VOLUME_NAME already exists. Replace it? (y/n): " replace
        if [ "$replace" = "y" ] || [ "$replace" = "Y" ]; then
          docker volume rm "$VOLUME_NAME"
        else
          read -p "Enter new volume name: " VOLUME_NAME
        fi
      fi
      
      # Create new volume
      docker volume create "$VOLUME_NAME"
      
      # Create temporary container to restore volume
      echo "Creating temporary container to restore volume..."
      TEMP_CONTAINER=$(docker run -d -v "$VOLUME_NAME:/volume" --name "restore-$VOLUME_NAME" alpine:latest sleep 300)
      
      # Copy backup file to container
      echo "Copying backup file to container..."
      docker cp "$BACKUP_FILE" "restore-$VOLUME_NAME:/volume/backup.tar"
      
      # Extract backup in volume
      echo "Extracting backup to volume..."
      docker exec "restore-$VOLUME_NAME" tar -xf "/volume/backup.tar" -C /volume
      
      # Clean up
      echo "Cleaning up temporary container..."
      docker exec "restore-$VOLUME_NAME" rm "/volume/backup.tar"
      docker rm -f "restore-$VOLUME_NAME"
      
      echo "Volume $VOLUME_NAME restored successfully."
      ;;
      
    "List Backups")
      echo "Listing available backups..."
      
      echo "Container backups:"
      find "$BACKUP_DIR/containers" -name "*.tar" | sort
      
      echo ""
      echo "Volume backups:"
      find "$BACKUP_DIR/volumes" -name "*.tar" | sort
      ;;
      
    "Clean Old Backups")
      echo "Cleaning old backups..."
      
      read -p "Enter number of days to keep backups (default: $RETENTION_DAYS): " days_input
      DAYS=${days_input:-$RETENTION_DAYS}
      
      echo "Removing backups older than $DAYS days..."
      find "$BACKUP_DIR" -type d -mtime "+$DAYS" -exec rm -rf {} \; 2>/dev/null || true
      
      echo "Old backups cleaned up."
      ;;
      
    "Configure Settings")
      echo "Configuring backup settings..."
      
      read -p "Enter backup directory (current: $BACKUP_DIR): " dir_input
      if [ ! -z "$dir_input" ]; then
        BACKUP_DIR="$dir_input"
        mkdir -p "$BACKUP_DIR"
        echo "Backup directory set to: $BACKUP_DIR"
      fi
      
      read -p "Enter backup retention days (current: $RETENTION_DAYS): " days_input
      if [ ! -z "$days_input" ]; then
        RETENTION_DAYS="$days_input"
        echo "Backup retention set to $RETENTION_DAYS days."
      fi
      
      # Save settings
      cat > /etc/docker-backup.conf << EOF
BACKUP_DIR="$BACKUP_DIR"
RETENTION_DAYS=$RETENTION_DAYS
EOF
      
      echo "Settings saved to /etc/docker-backup.conf"
      ;;
      
    "Quit")
      break
      ;;
      
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
