// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cluster.name}.${substring(uniqueString(services.name, cluster.name, 'namespace'), 0, 8)}'
  location: cluster.location
  properties: {
    subnet: {
      id: resourceId(cluster.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatelink-servicebus-windows-net'
        properties: {
          privateLinkServiceId: serviceBus.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
  dependsOn: []
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: serviceBusZone.id
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

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}

resource serviceBusZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.servicebus.windows.net'
  scope: resourceGroup(zones.subscription, zones.resourceGroup)
}

// ----------
// Parameters
// ----------

param services object
param zones object
param cluster object
