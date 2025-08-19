/*
Swiss Re Infrastructure Challenge - Main Bicep Template
Author: Jesus Gracia
Date: August 18, 2025
Version: 3.0.0
*/

targetScope = 'resourceGroup'

// Parameters
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Deployment version')
@allowed([1, 2, 3])
param deploymentVersion int = 3

@description('Admin username')
param adminUsername string = 'azureadmin'

@description('Admin password')
@secure()
@minLength(12)
param adminPassword string

@description('VM size')
param vmSize string = 'Standard_B2s'

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-swissre-\'
var fwName = 'fw-swissre-\'
var bastionName = 'bastion-swissre-\'
var vmName = 'vm-swissre-\'
var nsgVmName = 'nsg-vms-\'
var nsgBastionName = 'nsg-bastion-\'
var rtName = 'rt-swissre-\'
var storageAccountName = toLower('st\\')
var workspaceName = 'log-swissre-\'
var kvName = 'kv-\-\'
var identityName = 'id-swissre-\'

// Modules
module networking 'modules/networking.bicep' = {
  name: 'deploy-networking'
  params: {
    location: location
    vnetName: vnetName
    nsgVmName: nsgVmName
    nsgBastionName: nsgBastionName
    tags: {}
  }
}

module nsg 'modules/nsg.bicep' = {
  name: 'deploy-nsg'
  params: {
    location: location
    nsgVmName: nsgVmName
    nsgBastionName: nsgBastionName
    tags: {}
  }
}

module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    fwName: fwName
    subnetId: networking.outputs.firewallSubnetId
    vmPrivateIp: '10.0.3.4'
    deploymentVersion: deploymentVersion
    tags: {}
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
    tags: {}
  }
  dependsOn: [
    networking
    nsg
  ]
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
    tags: {}
  }
  dependsOn: [
    networking
    nsg
  ]
}

// Outputs
output vnetId string = networking.outputs.vnetId
output firewallPublicIp string = firewall.outputs.publicIp
output bastionFqdn string = bastion.outputs.fqdn
output vmPrivateIp string = vm.outputs.privateIp