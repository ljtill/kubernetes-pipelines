// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './resources.groups.bicep' = {
  name: 'Microsoft.Resources.Groups'
  scope: subscription(services.subscription)
  params: {
    services: services
    clusters: clusters
  }
}

module components './resources.components.bicep' = {
  name: 'Microsoft.Resources.Components'
  scope: resourceGroup(services.subscription, services.resourceGroup)
  params: {
    services: services
    clusters: clusters
  }
}

module diagnostics './resources.diagnostics.bicep' = {
  name: 'Microsoft.Resources.Diagnostics'
  scope: resourceGroup(services.subscription, services.resourceGroup)
  params: {
    services: services
  }
}

// ----------
// Parameters
// ----------

param services object
param clusters array
