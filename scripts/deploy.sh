#!/bin/bash
################################################################################
# Swiss Re Infrastructure Deployment Script
# Author: Jesus Gracia
# Date: August 18, 2025
# Version: 3.0.0
################################################################################

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
VERSION=${2:-3}
LOCATION=${3:-westeurope}
RESOURCE_GROUP="rg-swissre-${ENVIRONMENT}"
DEPLOYMENT_NAME="swissre-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}Swiss Re Infrastructure Deployment${NC}"
echo -e "${BLUE}Author: Jesus Gracia${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Location: ${LOCATION}${NC}"
echo ""

# Check Azure CLI
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

# Create resource group
echo -e "${BLUE}Creating resource group...${NC}"
if az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none; then
    echo -e "${GREEN}Resource group created successfully${NC}"
else
    echo -e "${RED}Failed to create resource group${NC}"
    exit 1
fi

# Validate template
echo -e "${BLUE}Validating template...${NC}"
if az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file infrastructure/main.bicep \
    --parameters deploymentVersion=$VERSION \
    --output none; then
    echo -e "${GREEN}Template validation passed${NC}"
else
    echo -e "${RED}Template validation failed${NC}"
    exit 1
fi

# Deploy infrastructure
echo -e "${BLUE}Deploying infrastructure...${NC}"
if az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file infrastructure/main.bicep \
    --parameters deploymentVersion=$VERSION \
    --output table; then
    echo -e "${GREEN}Deployment completed successfully!${NC}"
else
    echo -e "${RED}Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}Author: Jesus Gracia${NC}"
echo -e "${GREEN}================================================================${NC}"