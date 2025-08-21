// ============================================================================
// Monitoring Module - Swiss Re Infrastructure (Version 3)
// Log Analytics workspace for centralized monitoring
// ============================================================================

@description('Azure region for resources')
param location string

@description('Log Analytics workspace name')
param workspaceName string

@description('Resource tags')
param tags object

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: tags.Environment == 'prod' ? 90 : 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: tags.Environment == 'prod' ? -1 : 5
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output workspaceId string = workspace.id
output workspaceName string = workspace.name
output customerId string = workspace.properties.customerId
