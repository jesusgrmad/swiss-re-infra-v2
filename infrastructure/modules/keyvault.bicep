// Module: Key Vault
// Author: Jesus Gracia

param location string
param kvName string
param subnetId string
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

output vaultId string = keyVault.id
output vaultUri string = keyVault.properties.vaultUri
output vaultName string = keyVault.name