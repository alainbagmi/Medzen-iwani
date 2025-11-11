#!/bin/bash

# EHRbase Studio Deployment Script for Docker
# Deploys EHRbase Studio as Docker container on single VM

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Studio Docker Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Docker
echo -e "${YELLOW}Step 1: Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not found. Please install Docker.${NC}"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Docker daemon.${NC}"
    echo "Please ensure Docker is running and you have permissions."
    exit 1
fi

echo -e "${GREEN}✓ Docker is available${NC}"
docker --version
echo ""

# Step 2: Check Docker Compose
echo -e "${YELLOW}Step 2: Checking Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose not found.${NC}"
    echo "Installing docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo -e "${GREEN}✓ Docker Compose is available${NC}"
docker-compose --version
echo ""

# Step 3: Create deployment directory
echo -e "${YELLOW}Step 3: Setting up deployment directory...${NC}"
DEPLOY_DIR="/opt/ehrbase-studio"

if [ -d "$DEPLOY_DIR" ]; then
    echo -e "${YELLOW}Warning: $DEPLOY_DIR already exists.${NC}"
    read -p "Overwrite existing deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

sudo mkdir -p "$DEPLOY_DIR"
echo -e "${GREEN}✓ Deployment directory created: $DEPLOY_DIR${NC}"
echo ""

# Step 4: Copy docker-compose.yml
echo -e "${YELLOW}Step 4: Creating docker-compose.yml...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../docker/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker-compose.yml not found at $COMPOSE_FILE${NC}"
    exit 1
fi

sudo cp "$COMPOSE_FILE" "$DEPLOY_DIR/docker-compose.yml"
echo -e "${GREEN}✓ docker-compose.yml copied${NC}"
echo ""

# Step 5: Configure EHRbase URL
echo -e "${YELLOW}Step 5: Configuring EHRbase URL...${NC}"
read -p "Enter EHRbase REST API URL [https://ehrbase.mylestechsolutions.com/ehrbase/rest]: " EHRBASE_URL
EHRBASE_URL=${EHRBASE_URL:-https://ehrbase.mylestechsolutions.com/ehrbase/rest}

sudo sed -i "s|EHRBASE_REST_URL:.*|EHRBASE_REST_URL: \"$EHRBASE_URL\"|" "$DEPLOY_DIR/docker-compose.yml"
echo -e "${GREEN}✓ EHRbase URL configured: $EHRBASE_URL${NC}"
echo ""

# Step 6: Deploy Studio
echo -e "${YELLOW}Step 6: Deploying EHRbase Studio...${NC}"
cd "$DEPLOY_DIR"
sudo docker-compose pull
sudo docker-compose up -d

echo -e "${GREEN}✓ EHRbase Studio deployed${NC}"
echo ""

# Step 7: Wait for container to be healthy
echo -e "${YELLOW}Step 7: Waiting for container to be healthy...${NC}"
echo "This may take 30-60 seconds..."

for i in {1..30}; do
    if sudo docker-compose ps | grep -q "Up (healthy)"; then
        echo -e "${GREEN}✓ Container is healthy${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Step 8: Check status
echo -e "${YELLOW}Step 8: Checking deployment status...${NC}"
sudo docker-compose ps
echo ""

# Step 9: Show logs
echo -e "${YELLOW}Step 9: Recent logs:${NC}"
sudo docker-compose logs --tail=20
echo ""

# Step 10: Get access information
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""

# Get VM IP
VM_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}Access EHRbase Studio:${NC}"
echo "  http://$VM_IP:8081"
echo "  http://$(hostname):8081"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure your firewall/reverse proxy to expose Studio"
echo "2. Access Studio and login with EHRbase credentials"
echo "3. Upload OpenEHR templates"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  View logs:    cd $DEPLOY_DIR && sudo docker-compose logs -f"
echo "  Restart:      cd $DEPLOY_DIR && sudo docker-compose restart"
echo "  Stop:         cd $DEPLOY_DIR && sudo docker-compose stop"
echo "  Update:       cd $DEPLOY_DIR && sudo docker-compose pull && sudo docker-compose up -d"
echo ""
