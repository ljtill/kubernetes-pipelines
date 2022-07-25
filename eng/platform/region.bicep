// ------
// Scopes
// ------

targetScope = 'subscription'

// -----
// Notes
// -----

// -------
// Modules
// -------

//
// Groups
//

module groups 'modules/groups/resources.bicep' = {
  name: 'Microsoft.Bicep.Resources.Groups'
  params: {
    services: config.services
    zones: config.zones
    clusters: config.clusters
    endpoints: config.endpoints
  }
}

//
// Services
//

module services 'modules/services/resources.bicep' = {
  name: 'Microsoft.Bicep.Resources.Services'
  scope: resourceGroup(config.services.subscription, config.services.resourceGroup)
  params: {
    services: config.services
  }
  dependsOn: [
    groups
  ]
}

//
// Zones
//

module zones 'modules/zones/resources.bicep' = {
  name: 'Microsoft.Bicep.Resources.Zones'
  scope: resourceGroup(config.zones.subscription, config.zones.resourceGroup)
  params: {}
  dependsOn: [
    groups
  ]
}

//
// Clusters
//

@batchSize(1)
module clusters 'modules/clusters/resources.bicep' = [for cluster in config.clusters: {
  name: 'Microsoft.Bicep.Resources.Clusters.${cluster.properties.country}'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: config.services
    zones: config.zones
    cluster: cluster
  }
  dependsOn: [
    services
    zones
  ]
}]

//
// Endpoints
//

module endpoints 'modules/endpoints/resources.bicep' = {
  name: 'Microsoft.Bicep.Resources.Endpoints'
  scope: resourceGroup(config.endpoints.subscription, config.endpoints.resourceGroup)
  params: {
    services: config.services
    zones: config.zones
    clusters: config.clusters
  }
  dependsOn: [
    clusters
  ]
}

// ---------
// Variables
// ---------

var config = json(loadTextContent('../configs/platform.local.json'))
