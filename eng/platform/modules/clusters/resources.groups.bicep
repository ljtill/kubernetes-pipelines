// ------
// Scopes
// ------

targetScope = 'subscription'

// ---------
// Resources
// ---------

resource clustersGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: {
  name: cluster.resourceGroup
  location: cluster.location
}]

resource endpointsGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: cluster.properties.endpoints.resourceGroup
  location: cluster.location
}]

// ----------
// Parameters
// ----------

param clusters array
