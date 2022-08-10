// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

// Groups
module groups 'modules/groups/resources.bicep' = {
  name: 'Microsoft.Resources.Groups'
  params: {
    services: config.services
    clusters: config.clusters
  }
}

// Services
module services 'modules/services/resources.bicep' = {
  name: 'Microsoft.Resources.Services'
  scope: resourceGroup(config.services.subscription, config.services.resourceGroup)
  params: {
    services: config.services
  }
  dependsOn: [
    groups
  ]
}

// Clusters
@batchSize(1)
module clusters 'modules/clusters/resources.bicep' = [for cluster in config.clusters: {
  name: 'Microsoft.Resources.Clusters.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: config.services
    cluster: cluster
    applicationId: applicationId
  }
  dependsOn: [
    services
  ]
}]

// ---------
// Variables
// ---------

var defaults = loadJsonContent('./defaults.json')
var config = loadJsonContent('../configs/platform.local.json')

// ----------
// Parameters
// ----------

param applicationId string
