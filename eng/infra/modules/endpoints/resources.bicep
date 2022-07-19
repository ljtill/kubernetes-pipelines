// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// -------
// Modules
// -------

module registries './resources.registries.bicep' = [for cluster in clusters: {
  name: 'Microsoft.Bicep.Resources.Endpoints.${cluster.properties.country}.Registries'
  params: {
    services: services
    zones: zones
    cluster: cluster
  }
}]

module namespaces './resources.namespaces.bicep' = [for cluster in clusters: {
  name: 'Microsoft.Bicep.Resources.Endpoints.${cluster.properties.country}.Namespaces'
  params: {
    services: services
    zones: zones
    cluster: cluster
  }
}]

module vaults './resources.vaults.bicep' = [for cluster in clusters: {
  name: 'Microsoft.Bicep.Resources.Endpoints.${cluster.properties.country}.Vaults'
  params: {
    services: services
    zones: zones
    cluster: cluster
  }
}]

module storage './resources.storage.bicep' = [for cluster in clusters: {
  name: 'Microsoft.Bicep.Resources.Endpoints.${cluster.properties.country}.Storage'
  params: {
    services: services
    zones: zones
    cluster: cluster
  }
}]

// ----------
// Parameters
// ----------

param services object
param zones object
param clusters array
