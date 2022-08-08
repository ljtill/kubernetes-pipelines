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
      ipRules: [for ipRule in services.properties.clientAddresses: {
        action: 'Allow'
        value: ipRule
      }]
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

// DNS Zones
resource containerRegistry 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {}
}
resource serviceBus 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
  properties: {}
}
resource keyVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
}
resource storageAccountBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  properties: {}
}
resource storageAccountQueue 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.queue.core.windows.net'
  location: 'global'
  properties: {}
}
resource storageAccountTable 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
  properties: {}
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
