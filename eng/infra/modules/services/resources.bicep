// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Container Registry
resource registry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: services.properties.clientAddress
        }
      ]
    }
  }
}

// Log Analytics
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Application Insights
resource component 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
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
  name: 'Microsoft.Bicep.Resources.Diagnostics'
  params: {
    services: services
  }
  dependsOn: [
    registry
    workspace
  ]
}

// ---------
// Variables
// ---------

var name = services.name
var location = services.location

// ----------
// Parameters
// ----------

param services object
