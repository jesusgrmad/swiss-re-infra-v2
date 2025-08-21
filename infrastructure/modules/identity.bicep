// ============================================================================
// Managed Identity Module - Swiss Re Infrastructure (Version 3)
// System-assigned identity for VM
// ============================================================================

@description('Azure region for resources')
param location string

@description('VM name to assign identity')
param vmName string

@description('Resource tags')
param tags object

// ============================================================================
// USER ASSIGNED IDENTITY
// ============================================================================

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mi-${vmName}'
  location: location
  tags: tags
}

// ============================================================================
// OUTPUTS
// ============================================================================

output identityId string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
