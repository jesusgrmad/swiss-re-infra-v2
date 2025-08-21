// ============================================================================
// Networking Module - Swiss Re Infrastructure
// Creates VNet with 4 specific subnets as per requirements
// ============================================================================

@description('Azure region for resources')
param location string

@description('Virtual Network name')
param vnetName string

@description('Resource tags')
param tags object

// ============================================================================
// VIRTUAL NETWORK
// ============================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
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
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.0.4.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output vnetName string = vnet.name
output vnetId string = vnet.id
output firewallSubnetId string = vnet.properties.subnets[0].id
output bastionSubnetId string = vnet.properties.subnets[1].id
output vmSubnetId string = vnet.properties.subnets[2].id
output privateEndpointSubnetId string = vnet.properties.subnets[3].id
