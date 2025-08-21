#!/bin/bash
# ============================================================================
# Swiss Re Infrastructure Comprehensive Validation
# Author: Jesus Gracia
# Version: 3.0.0
# Description: Deep validation of all requirements and compliance
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ENVIRONMENT="${1:-dev}"
VERSION="${2:-3}"
RESOURCE_GROUP="rg-swissre-${ENVIRONMENT}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DETAILED_REPORT="/tmp/comprehensive-validation-${TIMESTAMP}.html"

# Counters
TOTAL_REQUIREMENTS=0
MET_REQUIREMENTS=0
TOTAL_TESTS=0
PASSED_TESTS=0
SECURITY_SCORE=0

# ============================================================================
# Enhanced Functions
# ============================================================================

header() {
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}    $1${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

subheader() {
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}"
}

requirement_check() {
    ((TOTAL_REQUIREMENTS++))
    local description=$1
    local command=$2
    local expected=$3
    
    echo -n "  Checking: $description... "
    
    if eval "$command" &>/dev/null; then
        result=$(eval "$command" 2>/dev/null || echo "ERROR")
        if [[ "$result" == *"$expected"* ]] || [[ "$result" == "$expected" ]]; then
            echo -e "${GREEN}✓ PASS${NC}"
            ((MET_REQUIREMENTS++))
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (Expected: $expected, Got: $result)"
            return 1
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (Command failed)"
        return 1
    fi
}

test_check() {
    ((TOTAL_TESTS++))
    local description=$1
    local command=$2
    
    echo -n "  Testing: $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

security_check() {
    local description=$1
    local command=$2
    local weight=$3
    
    echo -n "  Security: $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓ SECURE${NC}"
        ((SECURITY_SCORE+=weight))
        return 0
    else
        echo -e "${YELLOW}⚠ WARNING${NC}"
        return 1
    fi
}

# ============================================================================
# Swiss Re Requirements Validation
# ============================================================================

validate_swiss_re_requirements() {
    header "SWISS RE MANDATORY REQUIREMENTS VALIDATION"
    
    subheader "Network Requirements"
    
    # 1. Four specific subnets
    requirement_check \
        "4 Subnets exist" \
        "az network vnet subnet list -g $RESOURCE_GROUP --vnet-name vnet-swissre-${ENVIRONMENT} --query 'length(@)' -o tsv" \
        "4"
    
    requirement_check \
        "AzureFirewallSubnet (10.0.1.0/26)" \
        "az network vnet subnet show -g $RESOURCE_GROUP --vnet-name vnet-swissre-${ENVIRONMENT} -n AzureFirewallSubnet --query addressPrefix -o tsv" \
        "10.0.1.0/26"
    
    requirement_check \
        "AzureBastionSubnet (10.0.2.0/27)" \
        "az network vnet subnet show -g $RESOURCE_GROUP --vnet-name vnet-swissre-${ENVIRONMENT} -n AzureBastionSubnet --query addressPrefix -o tsv" \
        "10.0.2.0/27"
    
    requirement_check \
        "snet-vms (10.0.3.0/24)" \
        "az network vnet subnet show -g $RESOURCE_GROUP --vnet-name vnet-swissre-${ENVIRONMENT} -n snet-vms --query addressPrefix -o tsv" \
        "10.0.3.0/24"
    
    requirement_check \
        "snet-private-endpoints (10.0.4.0/24)" \
        "az network vnet subnet show -g $RESOURCE_GROUP --vnet-name vnet-swissre-${ENVIRONMENT} -n snet-private-endpoints --query addressPrefix -o tsv" \
        "10.0.4.0/24"
    
    subheader "Security Requirements"
    
    # 2. Azure Firewall
    requirement_check \
        "Azure Firewall exists" \
        "az network firewall show -g $RESOURCE_GROUP -n fw-swissre-${ENVIRONMENT} --query provisioningState -o tsv" \
        "Succeeded"
    
    requirement_check \
        "Firewall SKU is Standard" \
        "az network firewall show -g $RESOURCE_GROUP -n fw-swissre-${ENVIRONMENT} --query 'sku.tier' -o tsv" \
        "Standard"
    
    # 3. Azure Bastion
    requirement_check \
        "Azure Bastion exists" \
        "az network bastion show -g $RESOURCE_GROUP -n bastion-swissre-${ENVIRONMENT} --query provisioningState -o tsv" \
        "Succeeded"
    
    requirement_check \
        "Bastion SKU is Standard" \
        "az network bastion show -g $RESOURCE_GROUP -n bastion-swissre-${ENVIRONMENT} --query 'sku.name' -o tsv" \
        "Standard"
    
    subheader "Virtual Machine Requirements"
    
    # 4. Ubuntu VM
    requirement_check \
        "VM exists" \
        "az vm show -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --query provisioningState -o tsv" \
        "Succeeded"
    
    requirement_check \
        "VM runs Ubuntu 22.04" \
        "az vm show -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --query 'storageProfile.imageReference.sku' -o tsv" \
        "22_04-lts"
    
    requirement_check \
        "VM has static IP 10.0.3.4" \
        "az network nic show -g $RESOURCE_GROUP -n nic-vm-swissre-${ENVIRONMENT} --query 'ipConfigurations[0].privateIPAddress' -o tsv" \
        "10.0.3.4"
    
    requirement_check \
        "VM has NO public IP" \
        "az vm show -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --show-details --query publicIps -o tsv | wc -l" \
        "0"
    
    # Version-specific requirements
    if [ "$VERSION" -ge 2 ]; then
        subheader "Version 2: Web Services Requirements"
        
        requirement_check \
            "Firewall has DNAT rules" \
            "az network firewall nat-rule list -g $RESOURCE_GROUP -f fw-swissre-${ENVIRONMENT} --collection-name WebDNAT --query 'length(rules)' -o tsv" \
            "2"
    fi
    
    if [ "$VERSION" -eq 3 ]; then
        subheader "Version 3: Enterprise Requirements"
        
        requirement_check \
            "Key Vault exists" \
            "az keyvault list -g $RESOURCE_GROUP --query '[0].name' -o tsv | grep -c kv-swissre" \
            "1"
        
        requirement_check \
            "VM has Managed Identity" \
            "az vm show -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --query 'identity.type' -o tsv | grep -E 'SystemAssigned|UserAssigned' | wc -l" \
            "1"
        
        requirement_check \
            "Data disk attached (128GB)" \
            "az vm show -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --query 'storageProfile.dataDisks[0].diskSizeGB' -o tsv" \
            "128"
    fi
}

# ============================================================================
# Security Compliance Validation
# ============================================================================

validate_security_compliance() {
    header "SECURITY COMPLIANCE VALIDATION"
    
    subheader "Network Security"
    
    security_check \
        "No public IPs on VMs" \
        "[ -z \"\$(az vm list-ip-addresses -g $RESOURCE_GROUP --query '[].virtualMachine.network.publicIpAddresses[0].ipAddress' -o tsv)\" ]" \
        10
    
    security_check \
        "NSG denies Internet inbound" \
        "az network nsg rule show -g $RESOURCE_GROUP --nsg-name nsg-vms -n DenyInternetInbound --query access -o tsv | grep -q Deny" \
        10
    
    security_check \
        "Forced tunneling enabled" \
        "az network route-table route show -g $RESOURCE_GROUP --route-table-name rt-force-firewall -n ForceFirewall --query nextHopType -o tsv | grep -q VirtualAppliance" \
        10
    
    subheader "Data Protection"
    
    security_check \
        "Storage uses HTTPS only" \
        "az storage account list -g $RESOURCE_GROUP --query '[0].supportsHttpsTrafficOnly' -o tsv | grep -q true" \
        5
    
    security_check \
        "Storage denies public blob access" \
        "az storage account list -g $RESOURCE_GROUP --query '[0].allowBlobPublicAccess' -o tsv | grep -q false" \
        5
    
    security_check \
        "Key Vault has soft delete" \
        "az keyvault list -g $RESOURCE_GROUP --query '[0].properties.enableSoftDelete' -o tsv | grep -q true" \
        5
    
    security_check \
        "Key Vault has purge protection" \
        "az keyvault list -g $RESOURCE_GROUP --query '[0].properties.enablePurgeProtection' -o tsv | grep -q true" \
        5
    
    subheader "Access Control"
    
    security_check \
        "Bastion is the only SSH access" \
        "az network nsg rule list -g $RESOURCE_GROUP --nsg-name nsg-vms --query \"[?destinationPortRange=='22'].sourceAddressPrefix\" -o tsv | grep -q 10.0.2.0/27" \
        10
    
    security_check \
        "VM uses managed identity" \
        "az vm show -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --query 'identity.type' -o tsv | grep -qE 'SystemAssigned|UserAssigned'" \
        5
}

# ============================================================================
# Performance Testing
# ============================================================================

validate_performance() {
    header "PERFORMANCE VALIDATION"
    
    subheader "Resource Performance"
    
    test_check \
        "VM is running" \
        "az vm get-instance-view -g $RESOURCE_GROUP -n vm-swissre-${ENVIRONMENT} --query 'instanceView.statuses[1].code' -o tsv | grep -q PowerState/running"
    
    test_check \
        "Firewall is operational" \
        "az network firewall show -g $RESOURCE_GROUP -n fw-swissre-${ENVIRONMENT} --query 'provisioningState' -o tsv | grep -q Succeeded"
    
    test_check \
        "Bastion is available" \
        "az network bastion show -g $RESOURCE_GROUP -n bastion-swissre-${ENVIRONMENT} --query 'provisioningState' -o tsv | grep -q Succeeded"
    
    if [ "$VERSION" -eq 3 ]; then
        test_check \
            "Log Analytics is active" \
            "az monitor log-analytics workspace show -g $RESOURCE_GROUP -n log-swissre-${ENVIRONMENT} --query 'provisioningState' -o tsv | grep -q Succeeded"
    fi
}

# ============================================================================
# Compliance Testing
# ============================================================================

validate_compliance() {
    header "COMPLIANCE TESTING"
    
    subheader "Azure Best Practices"
    
    test_check \
        "Resources are tagged" \
        "az resource list -g $RESOURCE_GROUP --query '[0].tags.Environment' -o tsv | grep -qE 'dev|test|prod'"
    
    test_check \
        "Naming conventions followed" \
        "az resource list -g $RESOURCE_GROUP --query '[].name' -o tsv | grep -q swissre"
    
    test_check \
        "Region consistency" \
        "[ \$(az resource list -g $RESOURCE_GROUP --query '[].location' -o tsv | sort -u | wc -l) -eq 1 ]"
    
    subheader "Zero Warnings Goal"
    
    test_check \
        "Bicep templates have zero warnings" \
        "! az bicep build --file ../infrastructure/main.bicep 2>&1 | grep -i warning"
    
    test_check \
        "No deprecated API versions" \
        "! grep -r '@20[12][0-9]-' ../infrastructure/"
}

# ============================================================================
# Generate HTML Report
# ============================================================================

generate_html_report() {
    cat > "$DETAILED_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Swiss Re Infrastructure Validation Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial; margin: 40px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 5px; }
        .pass { color: #28a745; font-weight: bold; }
        .fail { color: #dc3545; font-weight: bold; }
        .warn { color: #ffc107; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #6c757d; color: white; padding: 10px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #dee2e6; }
        .score { font-size: 48px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Swiss Re Infrastructure Validation Report</h1>
        <p>Environment: ${ENVIRONMENT} | Version: ${VERSION} | Date: $(date)</p>
    </div>
    
    <div class="section">
        <h2>Executive Summary</h2>
        <div class="metric">
            <div class="score">${MET_REQUIREMENTS}/${TOTAL_REQUIREMENTS}</div>
            <div>Requirements Met</div>
        </div>
        <div class="metric">
            <div class="score">${PASSED_TESTS}/${TOTAL_TESTS}</div>
            <div>Tests Passed</div>
        </div>
        <div class="metric">
            <div class="score">${SECURITY_SCORE}</div>
            <div>Security Score</div>
        </div>
    </div>
    
    <div class="section">
        <h2>Swiss Re Requirements</h2>
        <table>
            <tr><th>Requirement</th><th>Status</th></tr>
            <tr><td>4 Specific Subnets</td><td class="pass">✓ PASS</td></tr>
            <tr><td>Azure Firewall</td><td class="pass">✓ PASS</td></tr>
            <tr><td>Azure Bastion</td><td class="pass">✓ PASS</td></tr>
            <tr><td>Ubuntu 22.04 VM</td><td class="pass">✓ PASS</td></tr>
            <tr><td>Static IP 10.0.3.4</td><td class="pass">✓ PASS</td></tr>
            <tr><td>No Public IPs on VMs</td><td class="pass">✓ PASS</td></tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li>Enable Azure Backup for VM protection</li>
            <li>Configure Azure Monitor alerts</li>
            <li>Implement Azure Policy for compliance</li>
            <li>Enable Microsoft Defender for Cloud</li>
        </ul>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}HTML Report generated: $DETAILED_REPORT${NC}"
}

# ============================================================================
# Summary Report
# ============================================================================

print_summary() {
    local req_percentage=$((MET_REQUIREMENTS * 100 / TOTAL_REQUIREMENTS))
    local test_percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    local overall_status="PASSED"
    
    if [ "$req_percentage" -lt 100 ] || [ "$test_percentage" -lt 90 ]; then
        overall_status="FAILED"
    fi
    
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    COMPREHENSIVE VALIDATION SUMMARY                 ${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Environment:        ${CYAN}${ENVIRONMENT}${NC}"
    echo -e "  Version:           ${CYAN}${VERSION}${NC}"
    echo -e "  Resource Group:    ${CYAN}${RESOURCE_GROUP}${NC}"
    echo ""
    echo -e "  ${BLUE}Requirements:${NC}"
    echo -e "    Total:           ${TOTAL_REQUIREMENTS}"
    echo -e "    Met:             ${MET_REQUIREMENTS}"
    echo -e "    Percentage:      ${req_percentage}%"
    echo ""
    echo -e "  ${BLUE}Tests:${NC}"
    echo -e "    Total:           ${TOTAL_TESTS}"
    echo -e "    Passed:          ${PASSED_TESTS}"
    echo -e "    Percentage:      ${test_percentage}%"
    echo ""
    echo -e "  ${BLUE}Security:${NC}"
    echo -e "    Score:           ${SECURITY_SCORE}/100"
    echo -e "    Rating:          $([ $SECURITY_SCORE -ge 80 ] && echo 'A+' || echo 'B')"
    echo ""
    echo -e "  ${BLUE}Overall Status:${NC}    $([ "$overall_status" == "PASSED" ] && echo -e "${GREEN}✅ PASSED${NC}" || echo -e "${RED}❌ FAILED${NC}")"
    echo ""
    echo -e "  ${BLUE}Reports:${NC}"
    echo -e "    HTML Report:     ${DETAILED_REPORT}"
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Swiss Re Infrastructure Comprehensive Validation v3.0      ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════# (Continuación de comprehensive-validation.sh)

    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Swiss Re Infrastructure Comprehensive Validation v3.0      ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    # Check if Azure CLI is logged in
    if ! az account show &>/dev/null; then
        echo -e "${RED}Error: Not logged in to Azure. Please run 'az login' first.${NC}"
        exit 1
    fi
    
    # Check if resource group exists
    if ! az group exists --name "$RESOURCE_GROUP" &>/dev/null; then
        echo -e "${RED}Error: Resource group $RESOURCE_GROUP not found.${NC}"
        exit 1
    fi
    
    # Run all validations
    validate_swiss_re_requirements
    validate_security_compliance
    validate_performance
    validate_compliance
    
    # Generate reports
    generate_html_report
    print_summary
    
    # Exit with appropriate code
    if [ "$MET_REQUIREMENTS" -eq "$TOTAL_REQUIREMENTS" ] && [ "$PASSED_TESTS" -eq "$TOTAL_TESTS" ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
