#!/bin/bash
# NextCloud Docker Installation Script

# Set default values
DB_NAME="nextcloud"
DB_USER="nextcloud"
DB_PASSWORD=$(openssl rand -base64 16)
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
NEXTCLOUD_CONTAINER_NAME="nextcloud"
DB_CONTAINER_NAME="nextcloud-db"
NETWORK_NAME="nextcloud-network"
PORT=8081
VOLUME_DB="nextcloud-db-data"
VOLUME_NC="nextcloud-data"
ADMIN_USER="admin"
ADMIN_PASSWORD=$(openssl rand -base64 12)

echo "NextCloud Docker Installation"
echo "============================"
echo ""
echo "This script will install NextCloud using Docker."
echo "Default port: $PORT"
echo ""
read -p "Enter port to use (default: $PORT): " PORT_INPUT
PORT=${PORT_INPUT:-$PORT}

read -p "Enter NextCloud admin username (default: $ADMIN_USER): " ADMIN_USER_INPUT
ADMIN_USER=${ADMIN_USER_INPUT:-$ADMIN_USER}

# Create docker network
echo "Creating Docker network..."
docker network create $NETWORK_NAME

# Create volumes
echo "Creating Docker volumes..."
docker volume create $VOLUME_DB
docker volume create $VOLUME_NC

# Run PostgreSQL container (NextCloud recommends PostgreSQL over MySQL)
echo "Starting PostgreSQL container..."
docker run -d \
  --name $DB_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -e POSTGRES_PASSWORD=$DB_ROOT_PASSWORD \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_USER=$DB_USER \
  -v $VOLUME_DB:/var/lib/postgresql/data \
  --restart always \
  postgres:13

# Wait for PostgreSQL to initialize
echo "Waiting for PostgreSQL to initialize..."
sleep 15

# Run NextCloud container
echo "Starting NextCloud container..."
docker run -d \
  --name $NEXTCLOUD_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -p $PORT:80 \
  -e POSTGRES_HOST=$DB_CONTAINER_NAME \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_USER=$DB_USER \
  -e POSTGRES_PASSWORD=$DB_ROOT_PASSWORD \
  -e NEXTCLOUD_ADMIN_USER=$ADMIN_USER \
  -e NEXTCLOUD_ADMIN_PASSWORD=$ADMIN_PASSWORD \
  -e NEXTCLOUD_TRUSTED_DOMAINS="localhost" \
  -v $VOLUME_NC:/var/www/html \
  --restart always \
  nextcloud:latest

echo ""
echo "NextCloud installation completed!"
echo "=================================="
echo "NextCloud is now running at: http://localhost:$PORT"
echo ""
echo "NextCloud Admin Credentials (SAVE THIS INFORMATION):"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "Database Information:"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_ROOT_PASSWORD"
echo ""
echo "To stop NextCloud: docker stop $NEXTCLOUD_CONTAINER_NAME $DB_CONTAINER_NAME"
echo "To start NextCloud: docker start $DB_CONTAINER_NAME $NEXTCLOUD_CONTAINER_NAME"
echo ""
echo "Note: For production use, you should configure SSL and proper trusted domains."
echo "Visit the NextCloud documentation for more information: https://docs.nextcloud.com/"
