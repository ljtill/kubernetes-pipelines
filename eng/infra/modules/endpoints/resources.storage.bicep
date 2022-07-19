// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Private Endpooints
resource privateEndpointBlob 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cluster.name}.${substring(uniqueString(services.name, cluster.name, 'blob'), 0, 8)}'
  location: cluster.location
  properties: {
    subnet: {
      id: resourceId(cluster.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  dependsOn: []
}
resource privateEndpointQueue 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cluster.name}.${substring(uniqueString(services.name, cluster.name, 'queue'), 0, 8)}'
  location: cluster.location
  properties: {
    subnet: {
      id: resourceId(cluster.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatelink-queue-core-windows-net'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
  dependsOn: []
}
resource privateEndpointTable 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cluster.name}.${substring(uniqueString(services.name, cluster.name, 'table'), 0, 8)}'
  location: cluster.location
  properties: {
    subnet: {
      id: resourceId(cluster.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatelink-table-core-windows-net'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
  dependsOn: []
}

// Private Dns Zone Groups
resource privateDnsZoneGroupBlob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpointBlob
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZoneBlob.id
        }
      }
    ]
  }
  dependsOn: []
}
resource privateDnsZoneGroupQueue 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpointQueue
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZoneQueue.id
        }
      }
    ]
  }
  dependsOn: []
}
resource privateDnsZoneGroupTable 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpointTable
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZoneTable.id
        }
      }
    ]
  }
  dependsOn: []
}

// ---------
// Resources
// ---------

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}

resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.blob.core.windows.net'
  scope: resourceGroup(zones.subscription, zones.resourceGroup)
}
resource privateDnsZoneQueue 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.queue.core.windows.net'
  scope: resourceGroup(zones.subscription, zones.resourceGroup)
}
resource privateDnsZoneTable 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.table.core.windows.net'
  scope: resourceGroup(zones.subscription, zones.resourceGroup)
}

// ----------
// Parameters
// ----------

param services object
param zones object
param cluster object
