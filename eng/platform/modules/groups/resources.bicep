// ------
// Scopes
// ------

targetScope = 'subscription'

// ---------
// Resources
// ---------

// Services

resource servicesGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: services.resourceGroup
  location: services.location
}

resource zonesGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: services.properties.zones.resourceGroup
  location: services.location
}

// Clusters

resource clustersGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: {
  name: cluster.resourceGroup
  location: cluster.location
}]

// NOTE: AKS RP will handle RG creation
// resource nodesGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: {
//   name: cluster.properties.nodes.resourceGroup
//   location: cluster.location
// }]

resource endpointsGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: {
  name: cluster.properties.endpoints.resourceGroup
  location: cluster.location
}]

// ----------
// Parameters
// ----------

param services object
param clusters array
