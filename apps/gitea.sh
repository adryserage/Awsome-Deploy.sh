#!/bin/bash
# Gitea Docker Installation Script

# Set default values
DB_NAME="gitea"
DB_USER="gitea"
DB_PASSWORD=$(openssl rand -base64 16)
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
GITEA_CONTAINER_NAME="gitea"
DB_CONTAINER_NAME="gitea-db"
NETWORK_NAME="gitea-network"
HTTP_PORT=3000
SSH_PORT=2222
VOLUME_DB="gitea-db-data"
VOLUME_GITEA="gitea-data"

echo "Gitea Docker Installation"
echo "========================="
echo ""
echo "This script will install Gitea using Docker."
echo "Default HTTP port: $HTTP_PORT"
echo "Default SSH port: $SSH_PORT"
echo ""
read -p "Enter HTTP port to use (default: $HTTP_PORT): " HTTP_PORT_INPUT
HTTP_PORT=${HTTP_PORT_INPUT:-$HTTP_PORT}

read -p "Enter SSH port to use (default: $SSH_PORT): " SSH_PORT_INPUT
SSH_PORT=${SSH_PORT_INPUT:-$SSH_PORT}

# Create docker network
echo "Creating Docker network..."
docker network create $NETWORK_NAME

# Create volumes
echo "Creating Docker volumes..."
docker volume create $VOLUME_DB
docker volume create $VOLUME_GITEA

# Run PostgreSQL container
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

# Run Gitea container
echo "Starting Gitea container..."
docker run -d \
  --name $GITEA_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -p $HTTP_PORT:3000 \
  -p $SSH_PORT:22 \
  -e USER_UID=1000 \
  -e USER_GID=1000 \
  -e GITEA__database__DB_TYPE=postgres \
  -e GITEA__database__HOST="${DB_CONTAINER_NAME}:5432" \
  -e GITEA__database__NAME=$DB_NAME \
  -e GITEA__database__USER=$DB_USER \
  -e GITEA__database__PASSWD=$DB_ROOT_PASSWORD \
  -v $VOLUME_GITEA:/data \
  --restart always \
  gitea/gitea:latest

echo ""
echo "Gitea installation completed!"
echo "============================="
echo "Gitea is now running at: http://localhost:$HTTP_PORT"
echo "SSH access is available on port: $SSH_PORT"
echo ""
echo "Database Information (SAVE THIS INFORMATION):"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_ROOT_PASSWORD"
echo ""
echo "To stop Gitea: docker stop $GITEA_CONTAINER_NAME $DB_CONTAINER_NAME"
echo "To start Gitea: docker start $DB_CONTAINER_NAME $GITEA_CONTAINER_NAME"
echo ""
echo "Note: On first access, you will need to complete the installation wizard."
echo "For production use, you should configure SSL and proper domain settings."
echo "Visit the Gitea documentation for more information: https://docs.gitea.io/"
