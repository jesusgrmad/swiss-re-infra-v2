# Swiss Re Infrastructure Challenge - Enterprise Azure Solution

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/jesusgrmad/swissre)
[![Azure](https://img.shields.io/badge/Azure-Enterprise-0078D4)](https://azure.microsoft.com)

## Executive Summary

This repository delivers an **enterprise-grade Azure infrastructure solution** for the Swiss Re Senior Infrastructure Engineer challenge.

**Author:** Jesus Gracia  
**Location:** Madrid, Spain  
**LinkedIn:** [linkedin.com/in/jesus-gracia-7a64084](https://linkedin.com/in/jesus-gracia-7a64084)  
**Submission Date:** August 18, 2025

## Quick Start

### Prerequisites

- Azure CLI v2.50+
- Bicep CLI latest
- Azure Subscription
- Git Bash or WSL

### Deployment

\\\ash
# Clone repository
git clone https://github.com/jesusgrmad/swissre.git
cd swissre

# Deploy to development
./scripts/deploy.sh dev 3
\\\

## Architecture

### Network Architecture

- **VNet:** 10.0.0.0/16
- **Subnets:**
  - AzureFirewallSubnet: 10.0.1.0/26
  - AzureBastionSubnet: 10.0.2.0/27
  - VM Subnet: 10.0.3.0/24
  - Private Endpoints: 10.0.4.0/24

### Security Features

- Zero-trust network model
- No public IPs on VMs
- Azure Firewall for all traffic
- Bastion for secure access
- NSG with deny-by-default
- Key Vault integration (v3)
- Managed Identity (v3)

## Features by Version

### Version 1: Foundation
- Virtual Network with 4 subnets
- Azure Firewall
- Azure Bastion
- Ubuntu 22.04 LTS VM

### Version 2: Web Services
- Apache HTTP Server
- HTTPS with certificates
- Firewall DNAT rules

### Version 3: Enterprise
- Azure Key Vault
- Managed Identity
- 128GB data disk
- TLS 1.2+ enforcement

## Testing

\\\ash
# Validate templates
az bicep build --file infrastructure/main.bicep

# Run tests
make test
\\\

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Security Documentation](docs/SECURITY.md)
- [Operations Runbook](docs/RUNBOOK.md)

---

**Copyright 2025 Jesus Gracia. Developed for Swiss Re.**