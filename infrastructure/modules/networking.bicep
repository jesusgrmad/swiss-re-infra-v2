// Module: Networking
// Author: Jesus Gracia

param location string
param vnetName string
param nsgVmName string
param nsgBastionName string
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
      {
        name: 'snet-vms'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        name: 'snet-endpoints'
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output firewallSubnetId string = vnet.properties.subnets[0].id
output bastionSubnetId string = vnet.properties.subnets[1].id
output vmSubnetId string = vnet.properties.subnets[2].id
output endpointsSubnetId string = vnet.properties.subnets[3].id