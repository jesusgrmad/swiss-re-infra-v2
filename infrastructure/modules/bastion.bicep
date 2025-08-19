// Module: Azure Bastion
// Author: Jesus Gracia

param location string
param bastionName string
param subnetId string
param nsgId string
param tags object = {}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: '\-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-06-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastion.id
output fqdn string = 'bastion.azure.com'