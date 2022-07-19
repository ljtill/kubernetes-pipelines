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

resource zonesGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: zones.resourceGroup
  location: services.location
}

resource clustersGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for cluster in clusters: {
  name: cluster.resourceGroup
  location: cluster.location
}]

resource endpointsGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: endpoints.resourceGroup
  location: endpoints.location
}

// ----------
// Parameters
// ----------

param services object
param zones object
param clusters array
param endpoints object
