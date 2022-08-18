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

resource zonesGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (privateClusters) {
  name: services.properties.zones.resourceGroup
  location: services.location
}

// ---------
// Variables
// ---------

var clusterTypes = [for item in clusters: item.properties.clusterType]
var privateClusters = contains(clusterTypes, 'private')

// ----------
// Parameters
// ----------

param services object
param clusters array
