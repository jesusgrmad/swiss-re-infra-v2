// Module: Network Security Groups
// Author: Jesus Gracia

param location string
param nsgVmName string
param nsgBastionName string
param tags object = {}

resource nsgVm 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgVmName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'DenyInternetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgBastionName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

output nsgVmId string = nsgVm.id
output nsgBastionId string = nsgBastion.id