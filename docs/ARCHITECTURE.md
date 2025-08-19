# Swiss Re Infrastructure Architecture

**Author:** Jesus Gracia  
**Date:** August 18, 2025  
**Version:** 3.0.0

## Executive Summary

This document describes the enterprise-grade Azure infrastructure architecture designed for the Swiss Re Senior Infrastructure Engineer challenge.

## Architecture Overview

### Core Components

1. **Virtual Network (VNet)**
   - Address Space: 10.0.0.0/16
   - 4 Subnets as specified:
     - AzureFirewallSubnet: 10.0.1.0/26
     - AzureBastionSubnet: 10.0.2.0/27
     - VM Subnet: 10.0.3.0/24
     - Private Endpoints Subnet: 10.0.4.0/24

2. **Azure Firewall**
   - Standard tier
   - Threat Intelligence enabled
   - DNAT rules for web traffic (Version 2+)
   - Forced tunneling for all VM traffic

3. **Azure Bastion**
   - Standard SKU
   - Secure RDP/SSH without public IPs
   - Tunneling enabled

4. **Virtual Machine**
   - Ubuntu 22.04 LTS
   - Static private IP: 10.0.3.4
   - Cloud-init configuration
   - Version-specific features

## Security Architecture

### Zero Trust Model

- No public IPs on VMs
- All traffic through Azure Firewall
- Network Security Groups (NSGs) with deny-by-default
- Bastion for secure management access

### Version 3 Enhancements

- Azure Key Vault integration
- Managed Identity authentication
- TLS 1.2+ enforcement
- Certificate management automation

## Network Flow

Internet - Azure Firewall - VM
         - Azure Bastion - VM
VM - Azure Firewall - Internet

## Deployment Versions

### Version 1: Foundation
- Basic infrastructure
- Security hardening
- UFW firewall

### Version 2: Web Services
- Apache HTTP Server
- HTTPS with self-signed certificates
- Firewall DNAT rules

### Version 3: Enterprise
- Key Vault integration
- Managed Identity
- Data disk for web content
- Advanced TLS configuration

## Scalability Considerations

- Parameterized templates for multiple environments
- Modular Bicep design for easy extension
- Tag-based resource management
- Centralized monitoring with Log Analytics

## Compliance and Governance

- Resource tagging strategy
- Audit logging enabled
- Network isolation
- Encryption in transit and at rest

---

Copyright 2025 Jesus Gracia. Developed for Swiss Re Infrastructure Challenge.