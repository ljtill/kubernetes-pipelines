// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cluster.name}.${substring(uniqueString(services.name, cluster.name, 'vault'), 0, 8)}'
  location: cluster.location
  properties: {
    subnet: {
      id: resourceId(cluster.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
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
          privateDnsZoneId: privateDnsZone.id
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.vaultcore.azure.net'
  scope: resourceGroup(zones.subscription, zones.resourceGroup)
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}

// ----------
// Parameters
// ----------

param services object
param zones object
param cluster object
