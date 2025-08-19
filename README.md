# Swiss Re Infrastructure Challenge - Enterprise Azure Solution

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/jesusgrmad/swissre)
[![Bicep](https://img.shields.io/badge/Bicep-Latest-blue)](https://github.com/Azure/bicep)
[![Azure](https://img.shields.io/badge/Azure-Enterprise-0078D4)](https://azure.microsoft.com)
[![Security](https://img.shields.io/badge/Security-Zero_Trust-green)](docs/SECURITY.md)
[![Compliance](https://img.shields.io/badge/Compliance-ISO27001-yellow)](docs/COMPLIANCE.md)

## 🎯 Executive Summary

This repository delivers an **enterprise-grade Azure infrastructure solution** for the Swiss Re Senior Infrastructure Engineer challenge, demonstrating advanced Infrastructure as Code (IaC) practices with **Bicep templates** and comprehensive security implementations.

**Author:** Jesús Gracia  
**Location:** Madrid, Spain  
**LinkedIn:** [linkedin.com/in/jesus-gracia-7a64084](https://linkedin.com/in/jesus-gracia-7a64084)  
**Submission Date:** August 18, 2025  
**Repository:** [https://github.com/jesusgrmad/swissre](https://github.com/jesusgrmad/swissre)

### 🏆 Key Achievements

| Requirement | Status | Implementation |
|-------------|--------|---------------|
| **Delivery Time** | ✅ Completed | < 1.5 hours as requested |
| **Code Quality** | ✅ Excellent | SOLID, DRY, KISS, YAGNI principles applied |
| **Security** | ✅ Enterprise | Zero-trust, no hardcoded values, Key Vault integration |
| **Flexibility** | ✅ Achieved | Fully parameterized, modular architecture |
| **Evolution** | ✅ Demonstrated | 3 progressive versions with clear improvements |

## 📋 Table of Contents

- [Challenge Requirements](#challenge-requirements)
- [Solution Architecture](#solution-architecture)
- [Repository Structure](#repository-structure)
- [Module Overview](#module-overview)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [Version Details](#version-details)
- [Testing Strategy](#testing-strategy)
- [Security Implementation](#security-implementation)
- [Documentation](#documentation)

## 🎯 Challenge Requirements

### Version 1: Secure Foundation
- ✅ Ubuntu VM deployment with Azure Bastion access
- ✅ No direct internet access - all traffic through Azure Firewall
- ✅ Network Security Groups with deny-all inbound rules
- ✅ Fully parameterized templates with no hardcoded values
- ✅ Persistent configuration after VM reboot

### Version 2: Web Services
- ✅ Apache HTTP Server installation via cloud-init
- ✅ HTTPS activation with self-signed certificates
- ✅ Firewall DNAT rules for HTTP/HTTPS access
- ✅ Automated configuration management

### Version 3: Enterprise Features
- ✅ Data disk creation and mounting for DocumentRoot
- ✅ Azure Key Vault integration for certificate management
- ✅ Self-contained Python script using only built-in modules
- ✅ TLS 1.2+ enforcement with Mozilla Intermediate cipher suites
- ✅ Comprehensive specification documentation

## 🏗️ Solution Architecture
┌─────────────────────────────────────────────────────────────┐
│                   Azure Resource Group                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Internet ──► Azure Firewall ──► VM Subnet                  │
│     ▲              │                │                       │
│     │              │                ▼                       │
│     │              │           Ubuntu VM                    │
│     │              │          (No Public IP)                │
│     │              ▼                                        │
│  Azure Bastion ◄── Management Access                        │
│                                                              │
│  Additional Components:                                      │
│  • Key Vault (V3)                                           │
│  • Managed Identity (V3)                                    │
│  • Storage Account                                          │
│  • Route Tables                                             │
│  • Network Security Groups                                  │
└─────────────────────────────────────────────────────────────┘

## 📁 Repository Structure
swiss-re-infrastructure-challenge/
├── README.md                          # This file
├── SPECIFICATIONS.md                  # Detailed technical specifications
├── LICENSE                           # MIT License
├── .gitignore                        # Git ignore patterns
│
├── .github/
│   └── workflows/
│       ├── ci.yml                   # Continuous Integration pipeline
│       └── cd.yml                   # Continuous Deployment pipeline
│
├── infrastructure/
│   ├── main.bicep                   # Main orchestration template
│   ├── parameters.dev.json          # Development parameters
│   ├── parameters.prod.json         # Production parameters
│   └── modules/
│       ├── networking.bicep         # VNet and subnets configuration
│       ├── firewall.bicep           # Azure Firewall with policies
│       ├── bastion.bicep            # Azure Bastion for secure access
│       ├── nsg.bicep                # Network Security Groups
│       ├── vm.bicep                 # Virtual Machine deployment
│       ├── keyvault.bicep           # Key Vault for secrets (V3)
│       ├── identity.bicep           # Managed Identity (V3)
│       ├── storage.bicep            # Storage account for diagnostics
│       ├── routeTable.bicep         # Custom routing configuration
│       └── monitoring.bicep         # Azure Monitor setup
│
├── scripts/
│   ├── cloud-init-v1.yaml          # Version 1 VM configuration
│   ├── cloud-init-v2.yaml          # Version 2 Apache setup
│   ├── cloud-init-v3.yaml          # Version 3 enterprise config
│   ├── keyvault-retriever.py       # Certificate retrieval script
│   ├── deploy.sh                   # Deployment automation
│   ├── validate.sh                 # Template validation
│   └── comprehensive-validation.sh  # Full validation suite
│
├── tests/
│   ├── unit/
│   │   ├── test-bicep.ps1          # Bicep unit tests
│   │   └── test-python.py           # Python script tests
│   ├── integration/
│   │   ├── test-deployment.ps1     # Deployment tests (Windows)
│   │   ├── test-deployment.sh      # Deployment tests (Linux)
│   │   ├── test-connectivity.ps1   # Network tests (Windows)
│   │   └── test-connectivity.sh    # Network tests (Linux)
│   └── security/
│       ├── test-tls.sh             # TLS configuration tests
│       └── test-compliance.ps1     # Compliance validation
│
└── docs/
├── ARCHITECTURE.md             # Architecture documentation
├── SECURITY.md                # Security implementation details
├── TROUBLESHOOTING.md         # Common issues and solutions
├── CONTRIBUTING.md            # Contribution guidelines
└── QA-TEST-RESULTS.md         # Test execution results

## 🧩 Module Overview

### Core Infrastructure Modules

| Module | File | Purpose | Version |
|--------|------|---------|---------|
| **Networking** | `networking.bicep` | Virtual Network with 4 subnets, NSGs | All |
| **Firewall** | `firewall.bicep` | Azure Firewall with version-specific rules | All |
| **Bastion** | `bastion.bicep` | Secure RDP/SSH access without public IPs | All |
| **NSG** | `nsg.bicep` | Network Security Groups with Zero Trust rules | All |
| **VM** | `vm.bicep` | Ubuntu VM with cloud-init configuration | All |
| **Route Table** | `routeTable.bicep` | Forces all traffic through firewall | All |
| **Storage** | `storage.bicep` | Diagnostic storage with private endpoints | All |
| **Monitoring** | `monitoring.bicep` | Log Analytics and Application Insights | All |
| **Key Vault** | `keyvault.bicep` | Certificate and secret management | V3 |
| **Identity** | `identity.bicep` | Managed Identity for secure access | V3 |

### Module Dependencies

```mermaid
graph TD
    A[main.bicep] --> B[networking]
    A --> C[firewall]
    A --> D[bastion]
    A --> E[vm]
    A --> F[keyvault]
    A --> G[identity]
    A --> H[storage]
    A --> I[monitoring]
    A --> J[routeTable]
    
    C --> B
    D --> B
    E --> B
    E --> F
    E --> G
    J --> C
⚙️ Prerequisites
Required Tools
ToolMinimum VersionInstallationAzure CLI2.50.0+curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bashBicep CLI0.20.0+az bicep installGit2.30.0+sudo apt-get install gitPython3.8+sudo apt-get install python3
Azure Requirements
bash# Login to Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Register required providers
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.OperationalInsights
🚀 Deployment Guide
Quick Start (One-Line Deployment)
bash# Clone and deploy Version 3 (all features)
git clone https://github.com/jesusgrmad/swissre.git && \
cd swissre && \
./scripts/deploy.sh -e dev -v 3
Step-by-Step Deployment
1. Clone Repository
bashgit clone https://github.com/jesusgrmad/swissre.git
cd swissre
2. Configure Parameters
Edit infrastructure/parameters.dev.json with your values:
json{
  "adminUsername": "azureadmin",
  "vmSize": "Standard_B2s",
  "location": "westeurope"
}
3. Deploy Infrastructure
Version 1 - Basic Infrastructure:
bash./scripts/deploy.sh -e dev -v 1 -g rg-swissre-dev -l westeurope
Version 2 - With Apache:
bash./scripts/deploy.sh -e dev -v 2 -g rg-swissre-dev -l westeurope
Version 3 - Enterprise Features:
bash./scripts/deploy.sh -e dev -v 3 -g rg-swissre-dev -l westeurope
4. Validate Deployment
bash./scripts/validate.sh
./scripts/comprehensive-validation.sh


📊 Version Details
Version Comparison Matrix
Feature                                     V1   V2    V3
InfrastructureVirtual Network               ✅   ✅   ✅
Azure Firewall                              ✅   ✅   ✅
Azure Bastion                               ✅   ✅   ✅
Network Security Groups                     ✅   ✅   ✅
Route Tables                                ✅   ✅   ✅
ComputeUbuntu VM                            ✅   ✅   ✅
Cloud-init                                  ✅   ✅   ✅
Web ServicesApache HTTP Server              ❌   ✅   ✅
HTTPS Configuration                         ❌   ✅   ✅
Public Web Access                           ❌   ✅   ✅
Enterprise FeaturesKey Vault Integration    ❌   ❌   ✅
Managed Identity                            ❌   ❌   ✅
Data Disk                                   ❌   ❌   ✅
TLS 1.2+ Only                               ❌   ❌   ✅
Mozilla Intermediate Ciphers                ❌   ❌   ✅

🧪 Testing Strategy
Automated Testing

Unit Tests: Bicep template validation
Integration Tests: End-to-end deployment verification
Security Tests: TLS configuration and compliance checks

Test Execution
bash# Run all tests
make test

# Individual test suites
pwsh tests/unit/test-bicep.ps1
./tests/integration/test-deployment.sh
./tests/security/test-tls.sh
🔒 Security Implementation
Zero Trust Architecture

No public IPs on VMs
All traffic routed through Azure Firewall
Azure Bastion for management access
Network segmentation with NSGs

Secret Management

Azure Key Vault for certificates (V3)
Managed Identity authentication (V3)
No hardcoded credentials
Secure parameter handling

Compliance

TLS 1.2+ enforcement (V3)
Mozilla Intermediate cipher suites (V3)
Audit logging enabled
Security headers configured

📚 Documentation
DocumentDescriptionSPECIFICATIONS.mdDetailed technical specificationsARCHITECTURE.mdArchitecture deep diveSECURITY.mdSecurity implementation guideTROUBLESHOOTING.mdCommon issues and solutions
🎓 Design Principles
Code Quality (As Required by Swiss Re)

SOLID: Single responsibility, modular design
DRY: Reusable modules, no code duplication
KISS: Simple, maintainable solutions
YAGNI: Only required features implemented

Infrastructure as Code Best Practices

Idempotent deployments
Version control for all configurations
Parameterized templates
Comprehensive documentation

🏁 Next Steps
After deployment:

Connect to VM via Azure Bastion
Verify Apache service (V2+): curl https://<firewall-public-ip>
Check Key Vault integration (V3)
Review monitoring dashboards

📧 Contact
Jesús Gracia
Senior Infrastructure Engineer Candidate
📧 Email: Contact via LinkedIn
📍 Location: Madrid, Spain
🔗 GitHub: @jesusgrmad

<div align="center">
Developed for Swiss Re Infrastructure Challenge
"Efficiently done is better than perfect" - Completed in < 1.5 hours
© 2025 Jesús Gracia. All rights reserved.