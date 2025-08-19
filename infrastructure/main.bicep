/*
################################################################################
# Swiss Re Infrastructure Challenge - Main Bicep Template
# Author: Jesus Gracia
# Date: August 18, 2025
# Version: 3.0.0
################################################################################
*/

targetScope = 'resourceGroup'

// Parameters
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name for deployment')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Deployment version controlling feature set')
@allowed([1, 2, 3])
param deploymentVersion int = 3

@description('Administrator username for the VM')
@minLength(5)
@maxLength(20)
param adminUsername string = 'azureadmin'

@description('Administrator password for the VM')
@secure()
@minLength(12)
param adminPassword string

@description('Size of the virtual machine')
param vmSize string = environment == 'prod' ? 'Standard_D2s_v3' : 'Standard_B2s'

@description('Resource tags for governance')
param tags object = {
  Environment: environment
  ManagedBy: 'Bicep'
  Author: 'Jesus_Gracia'
  Repository: 'swissre'
  Version: string(deploymentVersion)
  DeploymentDate: utcNow('yyyy-MM-dd')
}

// Variables
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 6)
var vnetName = 'vnet-swissre-${environment}'
var fwName = 'fw-swissre-${environment}'
var bastionName = 'bastion-swissre-${environment}'
var vmName = 'vm-swissre-${environment}'
var nsgVmName = 'nsg-vms-${environment}'
var nsgBastionName = 'nsg-bastion-${environment}'
var rtName = 'rt-swissre-${environment}'
var storageAccountName = toLower('st${environment}${uniqueSuffix}')
var workspaceName = 'log-swissre-${environment}'
var kvName = take('kv-${environment}-${uniqueSuffix}', 24)
var identityName = 'id-swissre-${environment}'

// Modules
module nsg 'modules/nsg.bicep' = {
  name: 'deploy-nsg'
  params: {
    location: location
    nsgVmName: nsgVmName
    nsgBastionName: nsgBastionName
    tags: tags
  }
}

module networking 'modules/networking.bicep' = {
  name: 'deploy-networking'
  params: {
    location: location
    vnetName: vnetName
    tags: tags
  }
  dependsOn: [
    nsg
  ]
}

module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    fwName: fwName
    subnetId: networking.outputs.firewallSubnetId
    vmPrivateIp: '10.0.3.4'
    deploymentVersion: deploymentVersion
    tags: tags
  }
  dependsOn: [
    networking
  ]
}

module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    location: location
    bastionName: bastionName
    subnetId: networking.outputs.bastionSubnetId
    nsgId: nsg.outputs.nsgBastionId
    tags: tags
  }
  dependsOn: [
    networking
    nsg
  ]
}

module routeTable 'modules/routeTable.bicep' = {
  name: 'deploy-routetable'
  params: {
    location: location
    rtName: rtName
    firewallPrivateIp: firewall.outputs.privateIp
    vmSubnetId: networking.outputs.vmSubnetId
    tags: tags
  }
  dependsOn: [
    firewall
    networking
  ]
}

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    tags: tags
  }
  dependsOn: [
    networking
  ]
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'deploy-monitoring'
  params: {
    location: location
    workspaceName: workspaceName
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = if (deploymentVersion == 3) {
  name: 'deploy-keyvault'
  params: {
    location: location
    kvName: kvName
    tags: tags
  }
  dependsOn: [
    networking
  ]
}

module identity 'modules/identity.bicep' = if (deploymentVersion == 3) {
  name: 'deploy-identity'
  params: {
    location: location
    identityName: identityName
    tags: tags
  }
}

module vm 'modules/vm.bicep' = {
  name: 'deploy-vm'
  params: {
    location: location
    vmName: vmName
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: networking.outputs.vmSubnetId
    nsgId: nsg.outputs.nsgVmId
    deploymentVersion: deploymentVersion
    managedIdentityId: deploymentVersion == 3 ? identity.outputs.identityId : ''
    storageAccountUri: storage.outputs.primaryBlobEndpoint
    tags: tags
  }
  dependsOn: [
    networking
    nsg
    routeTable
    storage
    monitoring
  ]
}

// Outputs
output vnetId string = networking.outputs.vnetId
output firewallPublicIp string = firewall.outputs.publicIp
output bastionFqdn string = bastion.outputs.fqdn
output vmPrivateIp string = vm.outputs.privateIp
output storageAccountName string = storage.outputs.name
output workspaceId string = monitoring.outputs.workspaceId
output keyVaultUri string = deploymentVersion == 3 ? keyvault.outputs.vaultUri : 'N/A'
output deployedVersion int = deploymentVersion