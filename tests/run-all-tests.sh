#!/bin/bash

################################################################################
# Swiss Re Infrastructure - Master Test Runner
# Author: Jesus Gracia
# Date: August 18, 2025
################################################################################

set -euo pipefail

echo "========================================"
echo "Swiss Re Infrastructure Test Suite"
echo "Author: Jesus Gracia"
echo "========================================"
echo ""

# Run unit tests
echo "Running unit tests..."
if bash tests/unit/test-bicep.sh; then
    echo "Unit tests passed"
else
    echo "Unit tests failed"
    exit 1
fi

echo ""

# Run security tests
echo "Running security tests..."
if bash tests/security/test-security.sh; then
    echo "Security tests passed"
else
    echo "Security tests failed"
    exit 1
fi

echo ""
echo "========================================"
echo "All tests passed successfully!"
echo "========================================"
exit 0