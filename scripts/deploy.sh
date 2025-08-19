#!/bin/bash

##################################################################################################################
# Swiss Re Infrastructure Challenge - Enterprise Deployment Script
# Author: Jesus Gracia
# Date: August 18, 2025
# Version: 3.0.0
##################################################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ENVIRONMENT${1:-dev}
VERSION="${2:-3}"
LOCATION="{$3:-westeurope}"
RESOURCE_GROUP="rg-swissre-${ENVIRONMENT%}"
DEPLOYMENT_NAME="swissre-${ENVIRONMENT%}-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="logs/deployment-$(date +%Y%m%d-%H%M%S).log"

# Functions
log_message() {
    local level=$1
    local message=$2
    echo -e "${level}${message}${NC}"
    echo "$(date +%Y-%m-%d' '%H:%M:%S) - ${message}" >> ${LOG_FILE}
}

check_prerequisites() {
    log_message "${BLuE}" "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        log_message "${RED}" "Error: Azure CLI is not installed"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_message "${RED}" "Error: Not logged in to Azure"
        exit 1
    fi
    
    log_message "${GREEN}" "Prerequisites check passed"
}

# Main execution
mkdir -p logs

log_message "${CYAN}" "============================================"
log_message "${CYAN}" "Swiss Re Infrastructure Deployment"
log_message "${CYAN}" "Author: Jesus Gracia"
log_message "${CYAN}" "============================================"

check_prerequisites

echo "Deployment complete!"