// Module: Storage Account
// Author: Jesus Gracia

param location string
param storageAccountName string
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower(take(storageAccountName, 24))
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output primaryEndpoints object = storageAccount.properties.primaryEndpoints