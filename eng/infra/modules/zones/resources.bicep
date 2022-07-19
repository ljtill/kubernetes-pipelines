// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource containerRegistry 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {}
}

resource serviceBus 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
  properties: {}
}

resource keyVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
}

resource storageAccountBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  properties: {}
}
resource storageAccountQueue 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.queue.core.windows.net'
  location: 'global'
  properties: {}
}
resource storageAccountTable 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
  properties: {}
}
