// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './resources.groups.bicep' = {
  name: 'Microsoft.Resources.Clusters.Groups'
  scope: subscription(services.subscription)
  params: {
    clusters: clusters
  }
}

// Public
module publicComponents './public/resources.components.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'public') {
  name: 'Microsoft.Resources.Clusters.Public.Components.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
    objectId: objectId
  }
  dependsOn: [
    groups
  ]
}]
module publicDiagnostics './public/resources.diagnostics.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'public') {
  name: 'Microsoft.Resources.Clusters.Publc.Diagnostics.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
  dependsOn: [
    groups
    publicComponents
  ]
}]

// Private
@batchSize(1)
module privateComponents './private/resources.components.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: 'Microsoft.Resources.Clusters.Private.Components.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
    objectId: objectId
  }
  dependsOn: [
    groups
  ]
}]
@batchSize(1)
module privateDiagnostics './private/resources.diagnostics.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: 'Microsoft.Resources.Clusters.Private.Diagnostics.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
  dependsOn: [
    groups
    privateComponents
  ]
}]
@batchSize(1)
module privateEndpoints './private/resources.endpoints.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: 'Microsoft.Resources.Clusters.Private.Endpoints.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.properties.endpoints.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
  dependsOn: [
    groups
    privateComponents
  ]
}]

// ---------
// Variables
// ---------

var defaults = loadJsonContent('../../defaults.json')

// ----------
// Parameters
// ----------

param services object
param clusters array
param objectId string
