// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './resources.groups.bicep' = {
  name: 'Microsoft.Resources.Services.Groups'
  scope: subscription(services.subscription)
  params: {
    services: services
    clusters: clusters
  }
}

module components './resources.components.bicep' = {
  name: 'Microsoft.Resources.Services.Components'
  scope: resourceGroup(services.subscription, services.resourceGroup)
  params: {
    services: services
    clusters: clusters
  }
  dependsOn: [
    groups
  ]
}

module diagnostics './resources.diagnostics.bicep' = {
  name: 'Microsoft.Resources.Services.Diagnostics'
  scope: resourceGroup(services.subscription, services.resourceGroup)
  params: {
    services: services
  }
  dependsOn: [
    groups
    components
  ]
}

// ----------
// Parameters
// ----------

param services object
param clusters array
