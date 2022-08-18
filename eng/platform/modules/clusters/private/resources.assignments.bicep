// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Service Bus
resource serviceBusReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ServiceBusDataReceiver', cluster.name, objectId)
  scope: serviceBus
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.serviceBusDataReceiver)
  }
}
resource serviceBusSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ServiceBusDataSender', cluster.name, objectId)
  scope: serviceBus
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.serviceBusDataSender)
  }
}

// Key Vault
resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('KeyVaultSecretsOfficer', cluster.name, objectId)
  scope: keyVault
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.keyVaultSecretsOfficer)
  }
}

// Storage Account
resource storageAccountBlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageBlobDataContributor', cluster.name, objectId)
  scope: storageAccount
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageBlobDataContributor)
  }
}
resource storageAccountFileContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageFileDataContributor', cluster.name, objectId)
  scope: storageAccount
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageFileDataContributor)
  }
}
resource storageAccountQueueContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageQueueDataContributor', cluster.name, objectId)
  scope: storageAccount
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageQueueDataContributor)
  }
}
resource storageAccountTableContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageTableDataContributor', cluster.name, objectId)
  scope: storageAccount
  properties: {
    principalId: objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageTableDataContributor)
  }
}

// ---------
// Resources
// ---------

// Cluster
resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: cluster.name
}
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: cluster.name
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: cluster.name
}

// ---------
// Variables
// ---------

var defaults = loadJsonContent('../../../defaults.json')

// ----------
// Parameters
// ----------

param cluster object
param objectId string
