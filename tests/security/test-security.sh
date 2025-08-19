#!/bin/bash

################################################################################
# Swiss Re Infrastructure - Security Tests
# Author: Jesus Gracia
# Date: August 18, 2025
################################################################################

set -euo pipefail

echo "Swiss Re Security Tests"
echo "Author: Jesus Gracia"
echo ""

ISSUES_FOUND=0

# Test 1: Check for exposed secrets
echo "Checking for exposed secrets..."
if grep -r "password\|secret\|key" . \
    --exclude-dir=.git \
    --exclude-dir=logs \
    --exclude="*.log" \
    --exclude="*.md" | \
    grep -v "@secure\|param\|#\|//" | \
    grep "=" ; then
    echo "Warning: Possible exposed secrets found"
    ((ISSUES_FOUND++))
else
    echo "No exposed secrets found"
fi

# Test 2: Check HTTPS enforcement
echo "Checking HTTPS enforcement..."
if grep -r "http://" infrastructure/ --include="*.bicep" | grep -v "https://" | grep -v "#"; then
    echo "Warning: Non-HTTPS URLs found"
    ((ISSUES_FOUND++))
else
    echo "HTTPS enforced"
fi

# Summary
echo ""
echo "========================================"
if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo "All security tests passed!"
    exit 0
else
    echo "Security issues found: $ISSUES_FOUND"
    exit 1
fi