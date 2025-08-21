// ============================================================================
// Swiss Re Infrastructure Challenge - Main Bicep Template
// Version: 3.0.0 | Author: Jesus Gracia | Date: 2025-08-21
// Description: Main orchestrator for progressive deployment versions
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Azure region for all resources')
@allowed([
  'westeurope'
  'northeurope'
  'switzerlandnorth'
])
param location string = 'westeurope'

@description('Environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Deployment version (1: Basic, 2: Web, 3: Enterprise)')
@allowed([1, 2, 3])
param deploymentVersion int = 3

@description('Admin username for the VM')
@minLength(5)
@maxLength(20)
param adminUsername string = 'swissreadmin'

@description('Admin password for the VM')
@secure()
@minLength(12)
param adminPassword string

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  Project: 'SwissRe-Challenge'
  Version: '${deploymentVersion}.0'
  ManagedBy: 'Bicep'
  Owner: 'Infrastructure-Team'
  CreatedDate: utcNow('yyyy-MM-dd')
}

// ============================================================================
// VARIABLES
// ============================================================================

var resourcePrefix = 'swissre'
var vnetName = 'vnet-${resourcePrefix}-${environment}'
var firewallName = 'fw-${resourcePrefix}-${environment}'
var bastionName = 'bastion-${resourcePrefix}-${environment}'
var vmName = 'vm-${resourcePrefix}-${environment}'
var nsgName = 'nsg-vms'
var routeTableName = 'rt-force-firewall'

// Key Vault and Storage (Version 3)
var keyVaultName = 'kv-${resourcePrefix}-${environment}-${uniqueString(resourceGroup().id)}'
var storageAccountName = 'st${resourcePrefix}${environment}${uniqueString(resourceGroup().id)}'
var logAnalyticsName = 'log-${resourcePrefix}-${environment}'

// Version-specific configurations
var enableWebServices = deploymentVersion >= 2
var enableEnterprise = deploymentVersion >= 3

// ============================================================================
// MODULE DEPLOYMENTS - VERSION 1 (BASIC INFRASTRUCTURE)
// ============================================================================

// Networking Module
module networking 'modules/networking.bicep' = {
  name: 'deploy-networking'
  params: {
    location: location
    vnetName: vnetName
    tags: tags
  }
}

// Network Security Groups
module nsg 'modules/nsg.bicep' = {
  name: 'deploy-nsg'
  params: {
    location: location
    nsgName: nsgName
    tags: tags
  }
}

// Route Table for Forced Tunneling
module routeTable 'modules/routeTable.bicep' = {
  name: 'deploy-routetable'
  params: {
    location: location
    routeTableName: routeTableName
    firewallPrivateIp: firewall.outputs.privateIpAddress
    tags: tags
  }
}

// Azure Firewall
module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    firewallName: firewallName
    subnetId: networking.outputs.firewallSubnetId
    enableDnatRules: enableWebServices
    vmPrivateIp: '10.0.3.4'
    tags: tags
  }
}

// Azure Bastion
module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    location: location
    bastionName: bastionName
    subnetId: networking.outputs.bastionSubnetId
    tags: tags
  }
}

// Virtual Machine
module vm 'modules/vm.bicep' = {
  name: 'deploy-vm'
  params: {
    location: location
    vmName: vmName
    subnetId: networking.outputs.vmSubnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
    nsgId: nsg.outputs.nsgId
    deploymentVersion: deploymentVersion
    keyVaultName: enableEnterprise ? keyVault.outputs.name : ''
    storageAccountName: enableEnterprise ? storage.outputs.name : ''
    logAnalyticsWorkspaceId: enableEnterprise ? monitoring.outputs.workspaceId : ''
    tags: tags
  }
  dependsOn: [
    routeTable
  ]
}

// ============================================================================
// MODULE DEPLOYMENTS - VERSION 3 (ENTERPRISE FEATURES)
// ============================================================================

// Managed Identity (Version 3)
module identity 'modules/identity.bicep' = if (enableEnterprise) {
  name: 'deploy-identity'
  params: {
    location: location
    vmName: vmName
    tags: tags
  }
}

// Key Vault (Version 3)
module keyVault 'modules/keyvault.bicep' = if (enableEnterprise) {
  name: 'deploy-keyvault'
  params: {
    location: location
    keyVaultName: keyVaultName
    tenantId: subscription().tenantId
    adminObjectId: identity.outputs.principalId
    subnetId: networking.outputs.privateEndpointSubnetId
    tags: tags
  }
  dependsOn: [
    identity
  ]
}

// Storage Account (Version 3)
module storage 'modules/storage.bicep' = if (enableEnterprise) {
  name: 'deploy-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    subnetId: networking.outputs.privateEndpointSubnetId
    tags: tags
  }
}

// Log Analytics (Version 3)
module monitoring 'modules/monitoring.bicep' = if (enableEnterprise) {
  name: 'deploy-monitoring'
  params: {
    location: location
    workspaceName: logAnalyticsName
    tags: tags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output deploymentVersion int = deploymentVersion
output vnetName string = networking.outputs.vnetName
output vnetId string = networking.outputs.vnetId
output firewallName string = firewall.outputs.name
output firewallPublicIp string = firewall.outputs.publicIpAddress
output bastionName string = bastion.outputs.name
output vmName string = vm.outputs.vmName
output vmPrivateIp string = vm.outputs.privateIpAddress

// Version 3 Outputs
output keyVaultName string = enableEnterprise ? keyVault.outputs.name : 'N/A'
output keyVaultUri string = enableEnterprise ? keyVault.outputs.vaultUri : 'N/A'
output storageAccountName string = enableEnterprise ? storage.outputs.name : 'N/A'
output logAnalyticsWorkspaceId string = enableEnterprise ? monitoring.outputs.workspaceId : 'N/A'
