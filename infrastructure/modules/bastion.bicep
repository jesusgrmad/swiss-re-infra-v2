// ============================================================================
// Azure Bastion Module - Swiss Re Infrastructure
// Standard SKU for secure VM access
// ============================================================================

@description('Azure region for resources')
param location string

@description('Bastion name')
param bastionName string

@description('Subnet ID for bastion')
param subnetId string

@description('Resource tags')
param tags object

// ============================================================================
// PUBLIC IP ADDRESS
// ============================================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-${bastionName}'
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
// AZURE BASTION
// ============================================================================

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    scaleUnits: 2
    enableTunneling: true
    enableIpConnect: true
    enableShareableLink: false
    enableKerberos: false
    disableCopyPaste: false
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
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output name string = bastion.name
output id string = bastion.id
output publicIpAddress string = publicIp.properties.ipAddress
