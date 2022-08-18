// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './resources.groups.bicep' = {
  name: 'Microsoft.Resources.Groups'
  scope: subscription(services.subscription)
  params: {
    clusters: clusters
  }
}

// Public
module publicComponents './public/resources.components.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'public') {
  name: 'Microsoft.Resources.Components'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
    objectId: objectId
  }
}]
module publicDiagnostics './public/resources.diagnostics.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'public') {
  name: 'Microsoft.Resources.Diagnostics'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
}]

// Private
module privateComponents './private/resources.components.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: 'Microsoft.Resources.Components'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
    objectId: objectId
  }
}]
module privateDiagnostics './private/resources.diagnostics.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: 'Microsoft.Resources.Diagnostics'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
}]
module privateEndpoints './private/resources.endpoints.bicep' = [for cluster in clusters: if (cluster.properties.clusterType == 'private') {
  name: 'Microsoft.Resources.Endpoints'
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
}]

// ----------
// Parameters
// ----------

param services object
param clusters array
param objectId string
