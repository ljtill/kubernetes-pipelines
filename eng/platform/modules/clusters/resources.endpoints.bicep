// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Service Bus
resource serviceBusPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
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
resource serviceBusPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: serviceBusPrivateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: serviceBusPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: []
}

// Container Registry
resource containerRegistryPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
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
resource containerRegistryPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: containerRegistryPrivateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: containerRegistryPrivateDnsZone.id
        }
      }
    ]
  }
}

// Key Vault
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
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
resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: keyVaultPrivateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: []
}

// Storage Accounts
resource storageAccountBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
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
resource storageAccountBlobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: storageAccountBlobPrivateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: storageAccountBlobPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: []
}
resource storageAccountQueuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
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
resource storageAccountPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: storageAccountQueuePrivateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: storageAccountQueuePrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: []
}
resource storageAccountTablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
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
resource storageAccountTablePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: storageAccountTablePrivateEndpoint
  name: cluster.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: storageAccountTablePrivateDnsZone.id
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
resource serviceBusPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.servicebus.windows.net'
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: services.name
  scope: resourceGroup(services.subscription, services.resourceGroup)
}
resource containerRegistryPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurecr.io'
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}
resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.vaultcore.azure.net'
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: cluster.name
  scope: resourceGroup(cluster.subscription, cluster.resourceGroup)
}
resource storageAccountBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.blob.core.windows.net'
  scope: resourceGroup(services.subscription, services.resourceGroup)
}
resource storageAccountQueuePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.queue.core.windows.net'
  scope: resourceGroup(services.subscription, services.resourceGroup)
}
resource storageAccountTablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.table.core.windows.net'
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

// ----------
// Parameters
// ----------

param services object
param cluster object
