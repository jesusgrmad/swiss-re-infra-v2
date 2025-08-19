// Module: Azure Firewall
// Author: Jesus Gracia

param location string
param fwName string
param subnetId string
param vmPrivateIp string = '10.0.3.4'
param deploymentVersion int
param tags object = {}

resource fwPublicIp 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
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

resource fwPolicy 'Microsoft.Network/firewallPolicies@2023-06-01' = {
  name: '\-policy'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-06-01' = {
  name: fwName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: fwPublicIp.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: fwPolicy.id
    }
  }
}

output firewallId string = firewall.id
output publicIp string = fwPublicIp.properties.ipAddress
output privateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress