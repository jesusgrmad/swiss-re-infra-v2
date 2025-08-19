// Module: Route Table
// Author: Jesus Gracia

param location string
param rtName string
param firewallPrivateIp string
param vmSubnetId string
param tags object = {}

resource routeTable 'Microsoft.Network/routeTables@2023-06-01' = {
  name: rtName
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

output id string = routeTable.id
output name string = routeTable.name