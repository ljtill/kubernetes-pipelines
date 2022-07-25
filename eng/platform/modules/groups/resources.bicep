// ------
// Scopes
// ------

targetScope = 'subscription'

// ---------
// Resources
// ---------

resource servicesGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: services.resourceGroup
  location: services.location
}

resource clustersGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: {
  name: cluster.resourceGroup
  location: cluster.location
}]

// ----------
// Parameters
// ----------

param services object
param clusters array
