// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource registryDiagnostic 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: registry
  properties: {
    logs: [
      {
        enabled: true
        category: 'ContainerRegistryRepositoryEvents'
      }
      {
        enabled: true
        category: 'ContainerRegistryLoginEvents'
      }
    ]
    metrics: [
      {
        enabled: false
        category: 'AllMetrics'
      }
    ]
    workspaceId: workspace.id
  }
}
resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: workspace
  properties: {
    logs: [
      {
        enabled: true
        category: 'Audit'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
    workspaceId: workspace.id
  }
}

// TODO: Diagnostics Settings for Private DNS Zones

// ---------
// Resources
// ---------

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: services.name
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: services.name
}

// ----------
// Parameters
// ----------

param services object
