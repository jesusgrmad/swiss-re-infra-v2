#!/bin/bash
# ============================================================================
# Swiss Re Infrastructure Validation Script
# Author: Jesus Gracia
# Version: 3.0.0
# Description: Validates deployment and checks all components
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT="${1:-dev}"
RESOURCE_GROUP="rg-swissre-${ENVIRONMENT}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="/tmp/validation-report-${TIMESTAMP}.json"

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# ============================================================================
# Functions
# ============================================================================

log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

check_pass() {
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
    log "✓ $1" "$GREEN"
}

check_fail() {
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
    log "✗ $1" "$RED"
}

check_warn() {
    ((WARNINGS++))
    log "⚠ $1" "$YELLOW"
}

info() {
    log "ℹ $1" "$BLUE"
}

# ============================================================================
# Validation Functions
# ============================================================================

validate_resource_group() {
    info "Validating Resource Group..."
    
    if az group exists --name "$RESOURCE_GROUP" 2>/dev/null; then
        check_pass "Resource group exists: $RESOURCE_GROUP"
        
        # Get resource count
        RESOURCE_COUNT=$(az resource list \
            --resource-group "$RESOURCE_GROUP" \
            --query "length(@)" -o tsv)
        
        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            check_pass "Resource group contains $RESOURCE_COUNT resources"
        else
            check_fail "Resource group is empty"
        fi
    else
        check_fail "Resource group not found: $RESOURCE_GROUP"
        exit 1
    fi
}

validate_networking() {
    info "Validating Network Configuration..."
    
    # Check VNet
    VNET_NAME="vnet-swissre-${ENVIRONMENT}"
    if az network vnet show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VNET_NAME" &>/dev/null; then
        check_pass "Virtual Network exists: $VNET_NAME"
        
        # Check subnets
        SUBNETS=$(az network vnet subnet list \
            --resource-group "$RESOURCE_GROUP" \
            --vnet-name "$VNET_NAME" \
            --query "[].name" -o tsv)
        
        REQUIRED_SUBNETS=("AzureFirewallSubnet" "AzureBastionSubnet" "snet-vms" "snet-private-endpoints")
        for subnet in "${REQUIRED_SUBNETS[@]}"; do
            if echo "$SUBNETS" | grep -q "$subnet"; then
                check_pass "Subnet exists: $subnet"
            else
                check_fail "Subnet missing: $subnet"
            fi
        done
        
        # Check specific IP configuration
        VM_IP=$(az network nic show \
            --resource-group "$RESOURCE_GROUP" \
            --name "nic-vm-swissre-${ENVIRONMENT}" \
            --query "ipConfigurations[0].privateIPAddress" -o tsv 2>/dev/null || echo "")
        
        if [ "$VM_IP" == "10.0.3.4" ]; then
            check_pass "VM has correct static IP: 10.0.3.4"
        else
            check_fail "VM IP is incorrect: $VM_IP (expected: 10.0.3.4)"
        fi
    else
        check_fail "Virtual Network not found: $VNET_NAME"
    fi
}

validate_firewall() {
    info "Validating Azure Firewall..."
    
    FIREWALL_NAME="fw-swissre-${ENVIRONMENT}"
    if az network firewall show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$FIREWALL_NAME" &>/dev/null; then
        check_pass "Azure Firewall exists: $FIREWALL_NAME"
        
        # Check firewall status
        FW_STATUS=$(az network firewall show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$FIREWALL_NAME" \
            --query "provisioningState" -o tsv)
        
        if [ "$FW_STATUS" == "Succeeded" ]; then
            check_pass "Firewall provisioning state: Succeeded"
        else
            check_warn "Firewall provisioning state: $FW_STATUS"
        fi
        
        # Check public IP
        FW_PUBLIC_IP=$(az network firewall show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$FIREWALL_NAME" \
            --query "ipConfigurations[0].publicIPAddress.id" -o tsv)
        
        if [ -n "$FW_PUBLIC_IP" ]; then
            check_pass "Firewall has public IP configured"
        else
            check_fail "Firewall missing public IP"
        fi
    else
        check_fail "Azure Firewall not found: $FIREWALL_NAME"
    fi
}

validate_bastion() {
    info "Validating Azure Bastion..."
    
    BASTION_NAME="bastion-swissre-${ENVIRONMENT}"
    if az network bastion show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BASTION_NAME" &>/dev/null; then
        check_pass "Azure Bastion exists: $BASTION_NAME"
        
        # Check Bastion SKU
        BASTION_SKU=$(az network bastion show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$BASTION_NAME" \
            --query "sku.name" -o tsv)
        
        if [ "$BASTION_SKU" == "Standard" ]; then
            check_pass "Bastion SKU is Standard"
        else
            check_warn "Bastion SKU is: $BASTION_SKU (expected: Standard)"
        fi
    else
        check_fail "Azure Bastion not found: $BASTION_NAME"
    fi
}

validate_vm() {
    info "Validating Virtual Machine..."
    
    VM_NAME="vm-swissre-${ENVIRONMENT}"
    if az vm show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" &>/dev/null; then
        check_pass "Virtual Machine exists: $VM_NAME"
        
        # Check VM status
        VM_STATUS=$(az vm show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$VM_NAME" \
            --query "provisioningState" -o tsv)
        
        if [ "$VM_STATUS" == "Succeeded" ]; then
            check_pass "VM provisioning state: Succeeded"
        else
            check_warn "VM provisioning state: $VM_STATUS"
        fi
        
        # Check OS
        VM_OS=$(az vm show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$VM_NAME" \
            --query "storageProfile.imageReference.offer" -o tsv)
        
        if [[ "$VM_OS" == *"ubuntu"* ]]; then
            check_pass "VM is running Ubuntu"
        else
            check_fail "VM OS is not Ubuntu: $VM_OS"
        fi
        
        # Check for public IP (should not have one)
        PUBLIC_IP=$(az vm show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$VM_NAME" \
            --show-details \
            --query "publicIps" -o tsv)
        
        if [ -z "$PUBLIC_IP" ]; then
            check_pass "VM has no public IP (as required)"
        else
            check_fail "VM has public IP: $PUBLIC_IP (not allowed)"
        fi
        
        # Check managed identity (Version 3)
        IDENTITY=$(az vm show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$VM_NAME" \
            --query "identity.type" -o tsv)
        
        if [ "$IDENTITY" == "SystemAssigned" ] || [ "$IDENTITY" == "UserAssigned" ]; then
            check_pass "VM has managed identity configured"
        else
            check_warn "VM has no managed identity (required for Version 3)"
        fi
    else
        check_fail "Virtual Machine not found: $VM_NAME"
    fi
}

validate_nsg() {
    info "Validating Network Security Groups..."
    
    NSG_NAME="nsg-vms"
    if az network nsg show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$NSG_NAME" &>/dev/null; then
        check_pass "NSG exists: $NSG_NAME"
        
        # Check for deny internet rule
        DENY_INTERNET=$(az network nsg rule show \
            --resource-group "$RESOURCE_GROUP" \
            --nsg-name "$NSG_NAME" \
            --name "DenyInternetInbound" \
            --query "access" -o tsv 2>/dev/null || echo "")
        
        if [ "$DENY_INTERNET" == "Deny" ]; then
            check_pass "NSG denies Internet inbound traffic"
        else
            check_fail "NSG does not deny Internet inbound traffic"
        fi
    else
        check_fail "NSG not found: $NSG_NAME"
    fi
}

validate_keyvault() {
    info "Validating Key Vault (Version 3)..."
    
    # Key Vault name includes unique string
    KV_NAME=$(az keyvault list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?starts_with(name, 'kv-swissre-${ENVIRONMENT}')].name" -o tsv | head -1)
    
    if [ -n "$KV_NAME" ]; then
        check_pass "Key Vault exists: $KV_NAME"
        
        # Check soft delete
        SOFT_DELETE=$(az keyvault show \
            --name "$KV_NAME" \
            --query "properties.enableSoftDelete" -o tsv)
        
        if [ "$SOFT_DELETE" == "true" ]; then
            check_pass "Key Vault has soft delete enabled"
        else
            check_warn "Key Vault soft delete not enabled"
        fi
        
        # Check network rules
        DEFAULT_ACTION=$(az keyvault show \
            --name "$KV_NAME" \
            --query "properties.networkAcls.defaultAction" -o tsv)
        
        if [ "$DEFAULT_ACTION" == "Deny" ]; then
            check_pass "Key Vault denies public access by default"
        else
            check_warn "Key Vault allows public access"
        fi
    else
        check_warn "Key Vault not found (required for Version 3)"
    fi
}

validate_storage() {
    info "Validating Storage Account (Version 3)..."
    
    # Storage account name includes unique string
    STORAGE_NAME=$(az storage account list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?starts_with(name, 'stswissre${ENVIRONMENT}')].name" -o tsv | head -1)
    
    if [ -n "$STORAGE_NAME" ]; then
        check_pass "Storage Account exists: $STORAGE_NAME"
        
        # Check HTTPS only
        HTTPS_ONLY=$(az storage account show \
            --name "$STORAGE_NAME" \
            --query "supportsHttpsTrafficOnly" -o tsv)
        
        if [ "$HTTPS_ONLY" == "true" ]; then
            check_pass "Storage Account enforces HTTPS"
        else
            check_fail "Storage Account does not enforce HTTPS"
        fi
        
        # Check public blob access
        BLOB_PUBLIC=$(az storage account show \
            --name "$STORAGE_NAME" \
            --query "allowBlobPublicAccess" -o tsv)
        
        if [ "$BLOB_PUBLIC" == "false" ]; then
            check_pass "Storage Account denies public blob access"
        else
            check_warn "Storage Account allows public blob access"
        fi
    else
        check_warn "Storage Account not found (required for Version 3)"
    fi
}

validate_monitoring() {
    info "Validating Log Analytics (Version 3)..."
    
    WORKSPACE_NAME="log-swissre-${ENVIRONMENT}"
    if az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$WORKSPACE_NAME" &>/dev/null; then
        check_pass "Log Analytics Workspace exists: $WORKSPACE_NAME"
        
        # Check retention
        RETENTION=$(az monitor log-analytics workspace show \
            --resource-group "$RESOURCE_GROUP" \
            --workspace-name "$WORKSPACE_NAME" \
            --query "retentionInDays" -o tsv)
        
        if [ "$RETENTION" -ge 30 ]; then
            check_pass "Log retention is $RETENTION days"
        else
            check_warn "Log retention is only $RETENTION days"
        fi
    else
        check_warn "Log Analytics Workspace not found (required for Version 3)"
    fi
}

generate_report() {
    info "Generating validation report..."
    
    REPORT='{
  "timestamp": "'$TIMESTAMP'",
  "environment": "'$ENVIRONMENT'",
  "resourceGroup": "'$RESOURCE_GROUP'",
  "validation": {
    "totalChecks": '$TOTAL_CHECKS',
    "passed": '$PASSED_CHECKS',
    "failed": '$FAILED_CHECKS',
    "warnings": '$WARNINGS'
  },
  "status": "'$([ $FAILED_CHECKS -eq 0 ] && echo "PASSED" || echo "FAILED")'"
}'

    echo "$REPORT" | jq '.' > "$REPORT_FILE"
    
    cat << EOF

════════════════════════════════════════════════════════════════════
                    VALIDATION REPORT
════════════════════════════════════════════════════════════════════

  Environment:     $ENVIRONMENT
  Resource Group:  $RESOURCE_GROUP
  Timestamp:       $TIMESTAMP
  
  Results:
  ────────────────────────────────────────────────────────────────
  Total Checks:    $TOTAL_CHECKS
  Passed:          $PASSED_CHECKS $([ $PASSED_CHECKS -eq $TOTAL_CHECKS ] && echo "✓" || echo "")
  Failed:          $FAILED_CHECKS $([ $FAILED_CHECKS -eq 0 ] && echo "✓" || echo "✗")
  Warnings:        $WARNINGS
  
  Overall Status:  $([ $FAILED_CHECKS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
  
  Report saved to: $REPORT_FILE
  
════════════════════════════════════════════════════════════════════

EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log "Swiss Re Infrastructure Validation Script v3.0.0" "$BLUE"
    log "Validating environment: $ENVIRONMENT" "$BLUE"
    echo ""
    
    # Run validations
    validate_resource_group
    validate_networking
    validate_firewall
    validate_bastion
    validate_vm
    validate_nsg
    validate_keyvault
    validate_storage
    validate_monitoring
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [ $FAILED_CHECKS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main
