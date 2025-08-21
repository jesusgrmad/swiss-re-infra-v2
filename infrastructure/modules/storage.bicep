// ============================================================================
// Storage Account Module - Swiss Re Infrastructure (Version 3)
// Secure storage with private endpoint
// ============================================================================

@description('Azure region for resources')
param location string

@description('Storage account name')
param storageAccountName string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Resource tags')
param tags object

// ============================================================================
// STORAGE ACCOUNT
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower(replace(storageAccountName, '-', ''))
  location: location
  tags: tags
  sku: {
    name: tags.Environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        table: {
          enabled: true
        }
        queue: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
    }
  }
}

// ============================================================================
// BLOB CONTAINERS
// ============================================================================

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'scripts'
  properties: {
    publicAccess: 'None'
  }
}

resource diagnosticsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'diagnostics'
  properties: {
    publicAccess: 'None'
  }
}

// ============================================================================
// PRIVATE ENDPOINT
// ============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-${storageAccountName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${storageAccountName}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output name string = storageAccount.name
output id string = storageAccount.id
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
