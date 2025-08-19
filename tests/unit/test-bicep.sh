#!/bin/bash

################################################################################
# Swiss Re Infrastructure - Unit Tests for Bicep Templates
# Author: Jesus Gracia
# Date: August 18, 2025
################################################################################

set -euo pipefail

TESTS_PASSED=0
TESTS_FAILED=0

echo "Running Unit Tests"
echo "Author: Jesus Gracia"
echo ""

# Test function
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -n "Testing $test_name... "
    
    if eval $test_command &> /dev/null; then
        echo "PASSED"
        ((TESTS_PASSED++))
    else
        echo "FAILED"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Main template syntax
run_test "main.bicep syntax" "az bicep build --file infrastructure/main.bicep --stdout"

# Test 2: Check modules exist
run_test "networking module exists" "test -f infrastructure/modules/networking.bicep"
run_test "firewall module exists" "test -f infrastructure/modules/firewall.bicep"
run_test "bastion module exists" "test -f infrastructure/modules/bastion.bicep"
run_test "vm module exists" "test -f infrastructure/modules/vm.bicep"

# Test 3: Check parameter files
run_test "dev parameters exist" "test -f infrastructure/parameters.dev.json"
run_test "test parameters exist" "test -f infrastructure/parameters.test.json"
run_test "prod parameters exist" "test -f infrastructure/parameters.prod.json"

# Summary
echo ""
echo "========================================"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "========================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed!"
    exit 1
fi