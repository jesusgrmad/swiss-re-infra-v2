// ============================================================================
// Route Table Module - Swiss Re Infrastructure
// Forces all traffic through Azure Firewall
// ============================================================================

@description('Azure region for resources')
param location string

@description('Route table name')
param routeTableName string

@description('Firewall private IP address')
param firewallPrivateIp string

@description('Resource tags')
param tags object

// ============================================================================
// ROUTE TABLE
// ============================================================================

resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'ForceFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output id string = routeTable.id
output name string = routeTable.name
