#!/bin/bash
# Database Servers Installation Script (MySQL, PostgreSQL, MongoDB)

# Source the server IP utility
SCRIPT_DIR="$(dirname "$(dirname "$0")")"
source "$SCRIPT_DIR/utils/get_server_ip.sh"

PS3='Please select database to install: '
options=("MySQL" "PostgreSQL" "MongoDB" "All" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "MySQL")
            echo "Installing MySQL Server..."
            
            # Set default values
            MYSQL_CONTAINER_NAME="mysql-server"
            MYSQL_PORT=3306
            MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)
            MYSQL_VOLUME="mysql-data"
            
            echo "MySQL Docker Installation"
            echo "========================="
            echo ""
            echo "Default MySQL port: $MYSQL_PORT"
            echo ""
            read -p "Enter MySQL port to use (default: $MYSQL_PORT): " MYSQL_PORT_INPUT
            MYSQL_PORT=${MYSQL_PORT_INPUT:-$MYSQL_PORT}
            
            # Create volume
            echo "Creating Docker volume..."
            docker volume create $MYSQL_VOLUME
            
            # Run MySQL container
            echo "Starting MySQL container..."
            docker run -d \
              --name $MYSQL_CONTAINER_NAME \
              -p $MYSQL_PORT:3306 \
              -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
              -v $MYSQL_VOLUME:/var/lib/mysql \
              --restart always \
              mysql:8.0
            
            echo ""
            echo "MySQL installation completed!"
            echo "============================"
            # Get server IP
            SERVER_IP=$(get_server_ip)
            echo "MySQL is now running at: ${SERVER_IP}:$MYSQL_PORT"
            echo ""
            echo "MySQL Root Password (SAVE THIS INFORMATION): $MYSQL_ROOT_PASSWORD"
            echo ""
            echo "To stop MySQL: docker stop $MYSQL_CONTAINER_NAME"
            echo "To start MySQL: docker start $MYSQL_CONTAINER_NAME"
            echo "To connect to MySQL: mysql -h ${SERVER_IP} -P $MYSQL_PORT -u root -p"
            echo ""
            break
            ;;
            
        "PostgreSQL")
            echo "Installing PostgreSQL Server..."
            
            # Set default values
            POSTGRES_CONTAINER_NAME="postgres-server"
            POSTGRES_PORT=5432
            POSTGRES_USER="postgres"
            POSTGRES_PASSWORD=$(openssl rand -base64 16)
            POSTGRES_VOLUME="postgres-data"
            
            echo "PostgreSQL Docker Installation"
            echo "=============================="
            echo ""
            echo "Default PostgreSQL port: $POSTGRES_PORT"
            echo ""
            read -p "Enter PostgreSQL port to use (default: $POSTGRES_PORT): " POSTGRES_PORT_INPUT
            POSTGRES_PORT=${POSTGRES_PORT_INPUT:-$POSTGRES_PORT}
            
            # Create volume
            echo "Creating Docker volume..."
            docker volume create $POSTGRES_VOLUME
            
            # Run PostgreSQL container
            echo "Starting PostgreSQL container..."
            docker run -d \
              --name $POSTGRES_CONTAINER_NAME \
              -p $POSTGRES_PORT:5432 \
              -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
              -v $POSTGRES_VOLUME:/var/lib/postgresql/data \
              --restart always \
              postgres:13
            
            echo ""
            echo "PostgreSQL installation completed!"
            echo "=================================="
            # Get server IP
            SERVER_IP=$(get_server_ip)
            echo "PostgreSQL is now running at: ${SERVER_IP}:$POSTGRES_PORT"
            echo ""
            echo "PostgreSQL Credentials (SAVE THIS INFORMATION):"
            echo "Username: $POSTGRES_USER"
            echo "Password: $POSTGRES_PASSWORD"
            echo ""
            echo "To stop PostgreSQL: docker stop $POSTGRES_CONTAINER_NAME"
            echo "To start PostgreSQL: docker start $POSTGRES_CONTAINER_NAME"
            echo "To connect to PostgreSQL: psql -h ${SERVER_IP} -p $POSTGRES_PORT -U postgres -W"
            echo ""
            break
            ;;
            
        "MongoDB")
            echo "Installing MongoDB Server..."
            
            # Set default values
            MONGO_CONTAINER_NAME="mongodb-server"
            MONGO_PORT=27017
            MONGO_USER="admin"
            MONGO_PASSWORD=$(openssl rand -base64 16)
            MONGO_VOLUME="mongodb-data"
            
            echo "MongoDB Docker Installation"
            echo "=========================="
            echo ""
            echo "Default MongoDB port: $MONGO_PORT"
            echo ""
            read -p "Enter MongoDB port to use (default: $MONGO_PORT): " MONGO_PORT_INPUT
            MONGO_PORT=${MONGO_PORT_INPUT:-$MONGO_PORT}
            
            # Create volume
            echo "Creating Docker volume..."
            docker volume create $MONGO_VOLUME
            
            # Run MongoDB container
            echo "Starting MongoDB container..."
            docker run -d \
              --name $MONGO_CONTAINER_NAME \
              -p $MONGO_PORT:27017 \
              -e MONGO_INITDB_ROOT_USERNAME=$MONGO_USER \
              -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD \
              -v $MONGO_VOLUME:/data/db \
              --restart always \
              mongo:latest
            
            echo ""
            echo "MongoDB installation completed!"
            echo "=============================="
            # Get server IP
            SERVER_IP=$(get_server_ip)
            echo "MongoDB is now running at: ${SERVER_IP}:$MONGO_PORT"
            echo ""
            echo "MongoDB Credentials (SAVE THIS INFORMATION):"
            echo "Username: $MONGO_USER"
            echo "Password: $MONGO_PASSWORD"
            echo ""
            echo "To stop MongoDB: docker stop $MONGO_CONTAINER_NAME"
            echo "To start MongoDB: docker start $MONGO_CONTAINER_NAME"
            # Get server IP
            SERVER_IP=$(get_server_ip)
            echo "To connect to MongoDB: mongo mongodb://$MONGO_USER:$MONGO_PASSWORD@${SERVER_IP}:$MONGO_PORT"
            echo ""
            break
            ;;
            
        "All")
            echo "Installing all database servers..."
            
            # MySQL
            MYSQL_CONTAINER_NAME="mysql-server"
            MYSQL_PORT=3306
            MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)
            MYSQL_VOLUME="mysql-data"
            
            # PostgreSQL
            POSTGRES_CONTAINER_NAME="postgres-server"
            POSTGRES_PORT=5432
            POSTGRES_USER="postgres"
            POSTGRES_PASSWORD=$(openssl rand -base64 16)
            POSTGRES_VOLUME="postgres-data"
            
            # MongoDB
            MONGO_CONTAINER_NAME="mongodb-server"
            MONGO_PORT=27017
            MONGO_USER="admin"
            MONGO_PASSWORD=$(openssl rand -base64 16)
            MONGO_VOLUME="mongodb-data"
            
            # Create volumes
            echo "Creating Docker volumes..."
            docker volume create $MYSQL_VOLUME
            docker volume create $POSTGRES_VOLUME
            docker volume create $MONGO_VOLUME
            
            # Run MySQL container
            echo "Starting MySQL container..."
            docker run -d \
              --name $MYSQL_CONTAINER_NAME \
              -p $MYSQL_PORT:3306 \
              -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
              -v $MYSQL_VOLUME:/var/lib/mysql \
              --restart always \
              mysql:8.0
            
            # Run PostgreSQL container
            echo "Starting PostgreSQL container..."
            docker run -d \
              --name $POSTGRES_CONTAINER_NAME \
              -p $POSTGRES_PORT:5432 \
              -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
              -v $POSTGRES_VOLUME:/var/lib/postgresql/data \
              --restart always \
              postgres:13
            
            # Run MongoDB container
            echo "Starting MongoDB container..."
            docker run -d \
              --name $MONGO_CONTAINER_NAME \
              -p $MONGO_PORT:27017 \
              -e MONGO_INITDB_ROOT_USERNAME=$MONGO_USER \
              -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD \
              -v $MONGO_VOLUME:/data/db \
              --restart always \
              mongo:latest
            
            echo ""
            echo "All database servers installation completed!"
            echo "=========================================="
            echo ""
            # Get server IP
            SERVER_IP=$(get_server_ip)
            echo "MySQL is running at: ${SERVER_IP}:$MYSQL_PORT"
            echo "MySQL Root Password: $MYSQL_ROOT_PASSWORD"
            echo ""
            echo "PostgreSQL is running at: ${SERVER_IP}:$POSTGRES_PORT"
            echo "PostgreSQL Username: $POSTGRES_USER"
            echo "PostgreSQL Password: $POSTGRES_PASSWORD"
            echo ""
            echo "MongoDB is running at: ${SERVER_IP}:$MONGO_PORT"
            echo "MongoDB Username: $MONGO_USER"
            echo "MongoDB Password: $MONGO_PASSWORD"
            echo ""
            echo "IMPORTANT: Save these credentials in a secure location!"
            echo ""
            break
            ;;
            
        "Quit")
            break
            ;;
            
        *) echo "Invalid option $REPLY";;
    esac
done
