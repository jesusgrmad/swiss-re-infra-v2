#!/bin/bash
# ============================================================================
# Swiss Re Infrastructure Deployment Script
# Author: Jesus Gracia
# Version: 3.0.0
# Description: Automated deployment for all versions
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="/tmp/deploy-${TIMESTAMP}.log"

# Default values
DEFAULT_LOCATION="westeurope"
DEFAULT_ENVIRONMENT="dev"
DEFAULT_VERSION="3"

# ============================================================================
# Functions
# ============================================================================

log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR: $1" "$RED"
    exit 1
}

success() {
    log "SUCCESS: $1" "$GREEN"
}

info() {
    log "INFO: $1" "$BLUE"
}

warning() {
    log "WARNING: $1" "$YELLOW"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Swiss Re Infrastructure to Azure

OPTIONS:
    -e, --environment ENV    Environment (dev/test/prod) [default: dev]
    -v, --version VERSION    Deployment version (1/2/3) [default: 3]
    -l, --location LOCATION  Azure location [default: westeurope]
    -g, --resource-group RG  Resource group name [default: auto-generated]
    -s, --subscription SUB   Azure subscription ID [default: current]
    -h, --help              Show this help message

EXAMPLES:
    $0 -e dev -v 3
    $0 --environment prod --version 2
    $0 -e test -v 1 -l northeurope

EOF
    exit 0
}

check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        error "Azure CLI is not installed. Please install it first."
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        error "Not logged in to Azure. Please run 'az login' first."
    fi
    
    # Check Bicep
    if ! az bicep version &> /dev/null; then
        warning "Bicep CLI not installed. Installing..."
        az bicep install
    fi
    
    success "All prerequisites met"
}

parse_arguments() {
    ENVIRONMENT="$DEFAULT_ENVIRONMENT"
    VERSION="$DEFAULT_VERSION"
    LOCATION="$DEFAULT_LOCATION"
    RESOURCE_GROUP=""
    SUBSCRIPTION=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -l|--location)
                LOCATION="$2"
                shift 2
                ;;
            -g|--resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            -s|--subscription)
                SUBSCRIPTION="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
        error "Invalid environment: $ENVIRONMENT. Must be dev, test, or prod."
    fi
    
    # Validate version
    if [[ ! "$VERSION" =~ ^[1-3]$ ]]; then
        error "Invalid version: $VERSION. Must be 1, 2, or 3."
    fi
    
    # Set resource group if not provided
    if [ -z "$RESOURCE_GROUP" ]; then
        RESOURCE_GROUP="rg-swissre-${ENVIRONMENT}"
    fi
    
    # Set subscription if provided
    if [ -n "$SUBSCRIPTION" ]; then
        az account set --subscription "$SUBSCRIPTION"
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
}

create_resource_group() {
    info "Creating resource group: $RESOURCE_GROUP"
    
    if az group exists --name "$RESOURCE_GROUP" 2>/dev/null; then
        warning "Resource group already exists"
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --tags Environment="$ENVIRONMENT" Project="SwissRe" Version="$VERSION" \
            --output none
        success "Resource group created"
    fi
}

validate_templates() {
    info "Validating Bicep templates..."
    
    # Build and validate main template
    az bicep build \
        --file "${PROJECT_ROOT}/infrastructure/main.bicep" \
        --stdout > /dev/null
    
    # Validate all modules
    for module in "${PROJECT_ROOT}"/infrastructure/modules/*.bicep; do
        if [ -f "$module" ]; then
            az bicep build --file "$module" --stdout > /dev/null
        fi
    done
    
    success "All templates validated successfully"
}

generate_password() {
    # Generate a secure password if not provided
    if [ -z "${ADMIN_PASSWORD:-}" ]; then
        ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        ADMIN_PASSWORD="${ADMIN_PASSWORD}Aa1!"
        warning "Generated admin password (save this): $ADMIN_PASSWORD"
    fi
}

deploy_infrastructure() {
    info "Deploying infrastructure (Version $VERSION)..."
    
    DEPLOYMENT_NAME="deploy-${ENVIRONMENT}-${TIMESTAMP}"
    TEMPLATE_FILE="${PROJECT_ROOT}/infrastructure/main.bicep"
    PARAMETERS_FILE="${PROJECT_ROOT}/infrastructure/parameters.${ENVIRONMENT}.json"
    
    # Check if parameters file exists
    if [ ! -f "$PARAMETERS_FILE" ]; then
        error "Parameters file not found: $PARAMETERS_FILE"
    fi
    
    # Deploy with what-if first (for production)
    if [ "$ENVIRONMENT" == "prod" ]; then
        warning "Running what-if analysis for production deployment..."
        az deployment group what-if \
            --resource-group "$RESOURCE_GROUP" \
            --template-file "$TEMPLATE_FILE" \
            --parameters "@$PARAMETERS_FILE" \
            --parameters deploymentVersion="$VERSION" \
            --parameters adminPassword="$ADMIN_PASSWORD" \
            --name "$DEPLOYMENT_NAME" || true
        
        read -p "Continue with deployment? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Deployment cancelled by user"
        fi
    fi
    
    # Actual deployment
    info "Starting deployment: $DEPLOYMENT_NAME"
    
    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$PARAMETERS_FILE" \
        --parameters deploymentVersion="$VERSION" \
        --parameters adminPassword="$ADMIN_PASSWORD" \
        --name "$DEPLOYMENT_NAME" \
        --output json > "${LOG_FILE}.json"
    
    success "Deployment completed successfully"
}

post_deployment_validation() {
    info "Running post-deployment validation..."
    
    # Get deployment outputs
    OUTPUTS=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs -o json)
    
    # Extract key values
    VM_NAME=$(echo "$OUTPUTS" | jq -r '.vmName.value')
    FIREWALL_NAME=$(echo "$OUTPUTS" | jq -r '.firewallName.value')
    BASTION_NAME=$(echo "$OUTPUTS" | jq -r '.bastionName.value')
    
    # Check VM status
    VM_STATUS=$(az vm show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    
    if [ "$VM_STATUS" == "Succeeded" ]; then
        success "VM provisioned successfully"
    else
        warning "VM status: $VM_STATUS"
    fi
    
    # Check firewall status
    FW_STATUS=$(az network firewall show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$FIREWALL_NAME" \
        --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    
    if [ "$FW_STATUS" == "Succeeded" ]; then
        success "Firewall provisioned successfully"
    else
        warning "Firewall status: $FW_STATUS"
    fi
    
    # Run validation script if exists
    VALIDATE_SCRIPT="${SCRIPT_DIR}/validate.sh"
    if [ -f "$VALIDATE_SCRIPT" ]; then
        info "Running validation script..."
        bash "$VALIDATE_SCRIPT" "$ENVIRONMENT"
    fi
}

cleanup_on_error() {
    if [ "${CLEANUP_ON_ERROR:-false}" == "true" ]; then
        warning "Cleaning up resources due to error..."
        az group delete \
            --name "$RESOURCE_GROUP" \
            --yes \
            --no-wait
    fi
}

print_summary() {
    cat << EOF

════════════════════════════════════════════════════════════════════
                    DEPLOYMENT SUMMARY
════════════════════════════════════════════════════════════════════
  
  Environment:      $ENVIRONMENT
  Version:          $VERSION
  Resource Group:   $RESOURCE_GROUP
  Location:         $LOCATION
  Subscription:     $SUBSCRIPTION_ID
  
  Deployment Name:  $DEPLOYMENT_NAME
  Log File:         $LOG_FILE
  
  Status:           COMPLETED SUCCESSFULLY
  
════════════════════════════════════════════════════════════════════

Next Steps:
1. Access VM via Bastion: az network bastion ssh --name $BASTION_NAME --resource-group $RESOURCE_GROUP --target-resource-id \$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query id -o tsv) --auth-type password

2. Check application:
   - Version 1: Basic infrastructure
   - Version 2: HTTP/HTTPS via firewall public IP
   - Version 3: Full enterprise features

3. View logs: cat $LOG_FILE

EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    info "Swiss Re Infrastructure Deployment Script v3.0.0"
    info "Starting deployment process..."
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Set error trap
    trap cleanup_on_error ERR
    
    # Execute deployment steps
    check_prerequisites
    generate_password
    create_resource_group
    validate_templates
    deploy_infrastructure
    post_deployment_validation
    print_summary
    
    success "Deployment completed successfully!"
}

# Run main function
main "$@"
