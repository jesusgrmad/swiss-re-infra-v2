# Swiss Re Infrastructure Runbook

**Author:** Jesus Gracia  
**Date:** August 18, 2025  
**Version:** 3.0.0

## Quick Start Guide

### Prerequisites

1. Azure CLI installed (v2.50+)
2. Bicep CLI installed
3. Azure subscription with appropriate permissions
4. Git Bash or WSL for running scripts

### Initial Setup

Clone repository:
git clone https://github.com/jesusgrmad/swissre.git
cd swissre

Make scripts executable:
chmod +x scripts/*.sh
chmod +x tests/**/*.sh

Login to Azure:
az login
az account set --subscription <subscription-id>

### Deployment

#### Development Environment

Deploy Version 3 (Enterprise) to dev:
./scripts/deploy.sh dev 3

#### Test Environment

Deploy Version 2 (Web Services) to test:
./scripts/deploy.sh test 2

#### Production Environment

Deploy Version 3 (Enterprise) to prod:
./scripts/deploy.sh prod 3

### Validation

Run template validation:
./scripts/validate.sh

Run all tests:
./tests/run-all-tests.sh

Post-deployment validation:
./scripts/comprehensive-validation.sh rg-swissre-dev dev

## Common Operations

### Connect to VM via Bastion

1. Navigate to Azure Portal
2. Go to the VM resource
3. Click Connect - Bastion
4. Enter credentials

### Update Firewall Rules

Get current rules:
az network firewall policy rule-collection-group show \
  --resource-group rg-swissre-dev \
  --policy-name fw-swissre-dev-policy \
  --name NetworkRules

Update rules in Bicep and redeploy:
./scripts/deploy.sh dev 3

### Certificate Management (Version 3)

Run certificate retriever on VM:
sudo python3 /usr/local/bin/keyvault-retriever.py

Check certificate:
openssl x509 -in /etc/ssl/certs/swissre.crt -text -noout

## Troubleshooting

### Deployment Failures

1. Check deployment logs:
az deployment group list \
  --resource-group rg-swissre-dev \
  --query '[0].properties.error'

2. Validate templates:
./scripts/validate.sh

3. Check Azure service health

### VM Connection Issues

1. Verify Bastion is running
2. Check NSG rules
3. Verify VM is running
4. Check firewall rules

### Apache Issues (Version 2+)

Check Apache status:
sudo systemctl status apache2

Check Apache logs:
sudo tail -f /var/log/apache2/error.log

Restart Apache:
sudo systemctl restart apache2

## Monitoring

### Check Resource Health

az resource list \
  --resource-group rg-swissre-dev \
  --query '[].{Name:name, Type:type, State:provisioningState}'

### View Logs

Deployment logs:
cat logs/deployment-*.log

VM boot diagnostics:
az vm boot-diagnostics get-boot-log \
  --resource-group rg-swissre-dev \
  --name vm-swissre-dev

## Cleanup

Delete entire resource group:
az group delete --name rg-swissre-dev --yes --no-wait

---

Copyright 2025 Jesus Gracia. Developed for Swiss Re Infrastructure Challenge.