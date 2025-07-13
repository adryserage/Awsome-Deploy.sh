#!/bin/bash
# Prometheus & Grafana Monitoring Stack Installation Script

# Set default values
NETWORK_NAME="monitoring-network"
PROMETHEUS_CONTAINER_NAME="prometheus"
GRAFANA_CONTAINER_NAME="grafana"
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
VOLUME_PROMETHEUS="prometheus-data"
VOLUME_GRAFANA="grafana-data"

echo "Prometheus & Grafana Monitoring Stack Installation"
echo "================================================="
echo ""
echo "This script will install Prometheus and Grafana using Docker."
echo "Default Prometheus port: $PROMETHEUS_PORT"
echo "Default Grafana port: $GRAFANA_PORT"
echo ""
read -p "Enter Prometheus port to use (default: $PROMETHEUS_PORT): " PROMETHEUS_PORT_INPUT
PROMETHEUS_PORT=${PROMETHEUS_PORT_INPUT:-$PROMETHEUS_PORT}

read -p "Enter Grafana port to use (default: $GRAFANA_PORT): " GRAFANA_PORT_INPUT
GRAFANA_PORT=${GRAFANA_PORT_INPUT:-$GRAFANA_PORT}

# Create docker network
echo "Creating Docker network..."
docker network create $NETWORK_NAME

# Create volumes
echo "Creating Docker volumes..."
docker volume create $VOLUME_PROMETHEUS
docker volume create $VOLUME_GRAFANA

# Create Prometheus config directory and file
echo "Creating Prometheus configuration..."
mkdir -p /tmp/prometheus
cat > /tmp/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
EOF

# Run Prometheus container
echo "Starting Prometheus container..."
docker run -d \
  --name $PROMETHEUS_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -p $PROMETHEUS_PORT:9090 \
  -v /tmp/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $VOLUME_PROMETHEUS:/prometheus \
  --restart always \
  prom/prometheus:latest

# Run Grafana container
echo "Starting Grafana container..."
docker run -d \
  --name $GRAFANA_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -p $GRAFANA_PORT:3000 \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
  -v $VOLUME_GRAFANA:/var/lib/grafana \
  --restart always \
  grafana/grafana:latest

echo ""
echo "Monitoring stack installation completed!"
echo "========================================"
echo "Prometheus is now running at: http://localhost:$PROMETHEUS_PORT"
echo "Grafana is now running at: http://localhost:$GRAFANA_PORT"
echo ""
echo "Grafana Default Credentials:"
echo "Username: admin"
echo "Password: admin (you will be prompted to change on first login)"
echo ""
echo "To stop the monitoring stack: docker stop $GRAFANA_CONTAINER_NAME $PROMETHEUS_CONTAINER_NAME"
echo "To start the monitoring stack: docker start $PROMETHEUS_CONTAINER_NAME $GRAFANA_CONTAINER_NAME"
echo ""
echo "Next steps:"
echo "1. Log in to Grafana at http://localhost:$GRAFANA_PORT"
echo "2. Add Prometheus as a data source (URL: http://$PROMETHEUS_CONTAINER_NAME:9090)"
echo "3. Import dashboards for your specific needs"
echo ""
echo "For more information, visit:"
echo "- Prometheus documentation: https://prometheus.io/docs/"
echo "- Grafana documentation: https://grafana.com/docs/"
