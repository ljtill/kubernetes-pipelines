// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

// Services
module services 'modules/services/resources.bicep' = {
  name: 'Microsoft.Resources.Services'
  scope: subscription(config.services.subscription)
  params: {
    services: config.services
    clusters: config.clusters
  }
}

// Clusters
module clusters 'modules/clusters/resources.bicep' = {
  name: 'Microsoft.Resources.Clusters'
  scope: subscription(config.clusters[0].subscription)
  params: {
    services: config.services
    clusters: config.clusters
    objectId: objectId
  }
  dependsOn: [
    services
  ]
}

// ---------
// Variables
// ---------

var config = loadJsonContent('../configs/platform.local.json')

// ----------
// Parameters
// ----------

param objectId string
