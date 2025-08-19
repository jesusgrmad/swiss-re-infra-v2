#!/bin/bash
################################################################################
# Swiss Re Infrastructure - Validation Script
# Author: Jesus Gracia
# Date: August 18, 2025
################################################################################

set -euo pipefail

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

ERRORS=0
WARNINGS=0

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}Swiss Re Infrastructure - Template Validation${NC}"
echo -e "${BLUE}Author: Jesus Gracia${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check Bicep CLI
echo -e "${BLUE}Checking Bicep CLI...${NC}"
if command -v az bicep &> /dev/null; then
    echo -e "${GREEN}Bicep CLI available${NC}"
else
    echo -e "${RED}Bicep CLI not found. Installing...${NC}"
    az bicep install
fi

# Validate main template
echo -e "${BLUE}Validating main.bicep...${NC}"
if az bicep build --file infrastructure/main.bicep --stdout > /dev/null 2>&1; then
    echo -e "${GREEN}main.bicep syntax valid${NC}"
else
    echo -e "${RED}main.bicep syntax invalid${NC}"
    ((ERRORS++))
fi

# Validate all modules
echo -e "${BLUE}Validating modules...${NC}"
for module in infrastructure/modules/*.bicep; do
    if [[ -f "$module" ]]; then
        module_name=$(echo "$module" | xargs -n 1 basename)
        echo -n "  Checking $module_name... "
        if az bicep build --file "$module" --stdout > /dev/null 2>&1; then
            echo -e "${GREEN}valid${NC}"
        else
            echo -e "${RED}invalid${NC}"
            ((ERRORS++))
        fi
    fi
done

# Summary
echo ""
echo -e "${BLUE}================================================================${NC}"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All validations passed!${NC}"
    echo -e "${GREEN}Author: Jesus Gracia${NC}"
    exit 0
else
    echo -e "${RED}Validation failed: $ERRORS errors found${NC}"
    exit 1
fi