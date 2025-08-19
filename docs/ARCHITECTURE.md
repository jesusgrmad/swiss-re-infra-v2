Architecture Documentation
Author: Jesus Gracia
Version: 4.0.0
Vision
Cloud-native infrastructure excellence for Swiss Re.
Principles

Security by Design
Zero Trust Architecture
Operational Excellence
Cost Optimization
Scalability Ready

Network Design
yamlVNet: 10.0.0.0/16
  AzureFirewallSubnet: 10.0.1.0/26
  AzureBastionSubnet: 10.0.2.0/27
  VM Subnet: 10.0.3.0/24
  Private Endpoints: 10.0.4.0/24
Security Layers

Perimeter: Azure Firewall
Network: NSGs
Identity: Managed Identity
Application: Hardening
Data: Encryption

Compute
EnvSizeCPURAMDevB2s24GBProdD2s_v328GB
Technology Stack

IaC: Bicep
OS: Ubuntu 22.04
Web: Apache 2.4
Security: Key Vault
Monitor: Log Analytics


Copyright 2025 Jesus Gracia