// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Container Registry
resource registry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: services.name
  location: services.location
  sku: {
    name: 'Premium'
  }
  properties: {
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [for ipRule in services.properties.clientAddresses: {
        action: 'Allow'
        value: replace(ipRule, '/32', '')
      }]
    }
  }
}

// Log Analytics
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: services.name
  location: services.location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Application Insights
resource component 'Microsoft.Insights/components@2020-02-02' = {
  name: services.name
  location: services.location
  kind: 'Web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

// DNS Zones
resource zoneContainerRegistry 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateClusters) {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {}
}
resource zoneServiceBus 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateClusters) {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
  properties: {}
}
resource zoneKeyVault 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateClusters) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
}
resource zoneStorageAccountBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateClusters) {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  properties: {}
}
resource zoneStorageAccountQueue 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateClusters) {
  name: 'privatelink.queue.core.windows.net'
  location: 'global'
  properties: {}
}
resource zoneStorageAccountTable 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateClusters) {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
  properties: {}
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
