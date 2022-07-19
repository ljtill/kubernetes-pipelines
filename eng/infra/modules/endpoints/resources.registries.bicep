// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cluster.name}.${substring(uniqueString(services.name, cluster.name, 'registry'), 0, 8)}'
  location: cluster.location
  properties: {
    subnet: {
      id: resourceId(cluster.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: dnsZone.id
        }
      }
    ]
  }
}

// ---------
// Resources
// ---------

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurecr.io'
  scope: resourceGroup(zones.subscription, zones.resourceGroup)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: services.name
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

// ----------
// Parameters
// ----------

param services object
param zones object
param cluster object
