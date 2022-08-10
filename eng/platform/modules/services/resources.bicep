// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Container Registry
resource registry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: services.name
  location: services.location
  sku: {
    name: 'Premium'
  }
  properties: {
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [for ipRule in services.properties.clientAddresses: {
        action: 'Allow'
        value: ipRule
      }]
    }
  }
}

// Log Analytics
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: services.name
  location: services.location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Application Insights
resource component 'Microsoft.Insights/components@2020-02-02' = {
  name: services.name
  location: services.location
  kind: 'Web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

// -------
// Modules
// -------

module diagnostics './resources.diagnostics.bicep' = {
  name: 'Microsoft.Resources.Diagnostics'
  params: {
    services: services
  }
  dependsOn: [
    registry
    workspace
  ]
}

module zones './resources.zones.bicep' = {
  name: 'Microsoft.Resources.Zones'
  scope: resourceGroup(services.subscription, services.properties.zones.resourceGroup)
  params: {}
}

// ----------
// Parameters
// ----------

param services object
