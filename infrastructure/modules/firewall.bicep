// ============================================================================
// Azure Firewall Module - Swiss Re Infrastructure
// Standard SKU with optional DNAT rules for Version 2+
// ============================================================================

@description('Azure region for resources')
param location string

@description('Firewall name')
param firewallName string

@description('Subnet ID for firewall')
param subnetId string

@description('Enable DNAT rules for web services')
param enableDnatRules bool = false

@description('VM private IP for DNAT')
param vmPrivateIp string = '10.0.3.4'

@description('Resource tags')
param tags object

// ============================================================================
// PUBLIC IP ADDRESS
// ============================================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-${firewallName}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// ============================================================================
// AZURE FIREWALL
// ============================================================================

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'AllowWebOutbound'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowHTTP'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '10.0.3.0/24'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '80'
                '443'
              ]
            }
          ]
        }
      }
    ]
    natRuleCollections: enableDnatRules ? [
      {
        name: 'WebDNAT'
        properties: {
          priority: 100
          action: {
            type: 'Dnat'
          }
          rules: [
            {
              name: 'HTTPInbound'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                publicIp.properties.ipAddress
              ]
              destinationPorts: [
                '80'
              ]
              translatedAddress: vmPrivateIp
              translatedPort: '80'
            }
            {
              name: 'HTTPSInbound'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                publicIp.properties.ipAddress
              ]
              destinationPorts: [
                '443'
              ]
              translatedAddress: vmPrivateIp
              translatedPort: '443'
            }
          ]
        }
      }
    ] : []
    applicationRuleCollections: [
      {
        name: 'AllowAzureServices'
        properties: {
          priority: 300
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowAzure'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              sourceAddresses: [
                '10.0.3.0/24'
              ]
              targetFqdns: [
                '*.azure.com'
                '*.microsoft.com'
                '*.windowsupdate.com'
                '*.ubuntu.com'
              ]
            }
          ]
        }
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output name string = firewall.name
output id string = firewall.id
output publicIpAddress string = publicIp.properties.ipAddress
output privateIpAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
