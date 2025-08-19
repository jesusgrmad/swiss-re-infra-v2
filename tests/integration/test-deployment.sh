#!/bin/bash

################################################################################
# Swiss Re Infrastructure - Integration Tests
# Author: Jesus Gracia
# Date: August 18, 2025
################################################################################

set -euo pipefail

ENVIRONMENT=${1:-test}
RESOURCE_GROUP="rg-swissre-${ENVIRONMENT}-test"

echo "Swiss Re Integration Tests"
echo "Author: Jesus Gracia"
echo "Environment: $ENVIRONMENT"
echo ""

# Test deployment validation
echo "Test 1: Deployment validation"
az deployment group validate \
    --resource-group $RESOURCE_GROUP \
    --template-file infrastructure/main.bicep \
    --parameters @infrastructure/parameters.${ENVIRONMENT}.json \
    --parameters deploymentVersion=1 \
    --output none
echo "Deployment validation passed"

echo ""
echo "All integration tests completed successfully!"