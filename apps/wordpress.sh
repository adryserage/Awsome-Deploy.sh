#!/bin/bash
# WordPress Docker Installation Script

# Set default values
DB_NAME="wordpress"
DB_USER="wordpress"
DB_PASSWORD=$(openssl rand -base64 16)
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
WP_CONTAINER_NAME="wordpress"
DB_CONTAINER_NAME="wordpress-db"
NETWORK_NAME="wordpress-network"
PORT=8080
VOLUME_DB="wordpress-db-data"
VOLUME_WP="wordpress-data"

echo "WordPress Docker Installation"
echo "============================"
echo ""
echo "This script will install WordPress using Docker."
echo "Default port: $PORT"
echo ""
read -p "Enter port to use (default: $PORT): " PORT_INPUT
PORT=${PORT_INPUT:-$PORT}

# Create docker network
echo "Creating Docker network..."
docker network create $NETWORK_NAME

# Create volumes
echo "Creating Docker volumes..."
docker volume create $VOLUME_DB
docker volume create $VOLUME_WP

# Run MySQL container
echo "Starting MySQL container..."
docker run -d \
  --name $DB_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
  -e MYSQL_DATABASE=$DB_NAME \
  -e MYSQL_USER=$DB_USER \
  -e MYSQL_PASSWORD=$DB_PASSWORD \
  -v $VOLUME_DB:/var/lib/mysql \
  --restart always \
  mysql:5.7

# Wait for MySQL to initialize
echo "Waiting for MySQL to initialize..."
sleep 10

# Run WordPress container
echo "Starting WordPress container..."
docker run -d \
  --name $WP_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -p $PORT:80 \
  -e WORDPRESS_DB_HOST=$DB_CONTAINER_NAME \
  -e WORDPRESS_DB_USER=$DB_USER \
  -e WORDPRESS_DB_PASSWORD=$DB_PASSWORD \
  -e WORDPRESS_DB_NAME=$DB_NAME \
  -v $VOLUME_WP:/var/www/html \
  --restart always \
  wordpress:latest

echo ""
echo "WordPress installation completed!"
echo "=================================="
echo "WordPress is now running at: http://localhost:$PORT"
echo ""
echo "Database Information (SAVE THIS INFORMATION):"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASSWORD"
echo "Database Root Password: $DB_ROOT_PASSWORD"
echo ""
echo "To stop WordPress: docker stop $WP_CONTAINER_NAME $DB_CONTAINER_NAME"
echo "To start WordPress: docker start $DB_CONTAINER_NAME $WP_CONTAINER_NAME"
echo ""
