// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Service Bus
resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: cluster.name
  location: cluster.location
  sku: {
    name: 'Premium'
  }
  properties: {}
  resource networkRuleSet 'networkRuleSets' = {
    name: 'default'
    properties: {
      defaultAction: 'Deny'
      ipRules: [for inboundConnection in defaults.inboundConnections: {
        action: 'Allow'
        ipMask: inboundConnection
      }]
      trustedServiceAccessEnabled: true
    }
  }
  resource processQueue 'queues' = {
    name: 'process'
    properties: {}
    resource accessPolicy 'authorizationRules' = {
      name: 'default'
      properties: {
        rights: [
          'Send'
          'Listen'
        ]
      }
    }
  }
  resource createQueue 'queues' = {
    name: 'create'
    properties: {}
    resource accessPolicy 'authorizationRules' = {
      name: 'default'
      properties: {
        rights: [
          'Send'
          'Listen'
        ]
      }
    }
  }
  resource deleteQueue 'queues' = {
    name: 'delete'
    properties: {}
    resource accessPolicy 'authorizationRules' = {
      name: 'default'
      properties: {
        rights: [
          'Send'
          'Listen'
        ]
      }
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: cluster.name
  location: cluster.location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      bypass: 'AzureServices'
    }
    enableRbacAuthorization: true
    enableSoftDelete: false
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: cluster.name
  location: cluster.location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      bypass: 'AzureServices'
    }
  }
}

// Kubernetes
resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: cluster.name
  location: cluster.location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.22.11'
    nodeResourceGroup: cluster.properties.nodes.resourceGroup
    dnsPrefix: cluster.name
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 3
        enableAutoScaling: true
        minCount: 1
        maxCount: 5
        vmSize: 'Standard_B4ms'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: []
        enableNodePublicIP: false
        tags: {}
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'default')
      }
    ]
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
    }
    oidcIssuerProfile: {
      enabled: true
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    addonProfiles: {
      azureKeyVaultSecretsProvider: {
        enabled: true
      }
    }
    autoUpgradeProfile: {
      upgradeChannel: 'rapid'
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
  }
}

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: cluster.name
  location: cluster.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.240.0.0/16'
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}

// Security Group
resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: cluster.name
  location: cluster.location
  properties: {}
}

// -----------
// Assignments
// -----------

// Service Bus
resource serviceBusReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ServiceBusDataReceiver', cluster.name, applicationId)
  scope: serviceBus
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.serviceBusDataReceiver)
  }
}
resource serviceBusSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ServiceBusDataSender', cluster.name, applicationId)
  scope: serviceBus
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.serviceBusDataSender)
  }
}

// Key Vault
resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('KeyVaultSecretsOfficer', cluster.name, applicationId)
  scope: keyVault
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.keyVaultSecretsOfficer)
  }
}

// Storage Account
resource storageAccountBlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageBlobDataContributor', cluster.name, applicationId)
  scope: storageAccount
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageBlobDataContributor)
  }
}
resource storageAccountFileContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageFileDataContributor', cluster.name, applicationId)
  scope: storageAccount
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageFileDataContributor)
  }
}
resource storageAccountQueueContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageQueueDataContributor', cluster.name, applicationId)
  scope: storageAccount
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageQueueDataContributor)
  }
}
resource storageAccountTableContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageTableDataContributor', cluster.name, applicationId)
  scope: storageAccount
  properties: {
    principalId: applicationId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', defaults.roleDefinitions.storageTableDataContributor)
  }
}

// -----------
// Deployments
// -----------

// NOTE: Workarounds to allow cross resource group deployments

// Virtual Network Links
resource links 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'Microsoft.Resources.Network'
  subscriptionId: services.subscription
  resourceGroup: services.properties.zones.resourceGroup
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: [
        {
          type: 'Microsoft.Network/privateDnsZones/virtualNetworkLinks'
          apiVersion: '2020-06-01'
          name: 'privatelink.azurecr.io/${cluster.name}'
          location: 'global'
          properties: {
            registrationEnabled: false
            virtualNetwork: {
              id: virtualNetwork.id
            }
          }
        }
        {
          type: 'Microsoft.Network/privateDnsZones/virtualNetworkLinks'
          apiVersion: '2020-06-01'
          name: 'privatelink.servicebus.windows.net/${cluster.name}'
          location: 'global'
          properties: {
            registrationEnabled: false
            virtualNetwork: {
              id: virtualNetwork.id
            }
          }
        }
        {
          type: 'Microsoft.Network/privateDnsZones/virtualNetworkLinks'
          apiVersion: '2020-06-01'
          name: 'privatelink.vaultcore.azure.net/${cluster.name}'
          location: 'global'
          properties: {
            registrationEnabled: false
            virtualNetwork: {
              id: virtualNetwork.id
            }
          }
        }
        {
          type: 'Microsoft.Network/privateDnsZones/virtualNetworkLinks'
          apiVersion: '2020-06-01'
          name: 'privatelink.blob.core.windows.net/${cluster.name}'
          location: 'global'
          properties: {
            registrationEnabled: false
            virtualNetwork: {
              id: virtualNetwork.id
            }
          }
        }
        {
          type: 'Microsoft.Network/privateDnsZones/virtualNetworkLinks'
          apiVersion: '2020-06-01'
          name: 'privatelink.queue.core.windows.net/${cluster.name}'
          location: 'global'
          properties: {
            registrationEnabled: false
            virtualNetwork: {
              id: virtualNetwork.id
            }
          }
        }
        {
          type: 'Microsoft.Network/privateDnsZones/virtualNetworkLinks'
          apiVersion: '2020-06-01'
          name: 'privatelink.table.core.windows.net/${cluster.name}'
          location: 'global'
          properties: {
            registrationEnabled: false
            virtualNetwork: {
              id: virtualNetwork.id
            }
          }
        }
      ]
    }
  }
}

// Role Assignments
resource authorization 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'Microsoft.Authorization.Services'
  subscriptionId: services.subscription
  resourceGroup: services.resourceGroup
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: [
        {
          type: 'Microsoft.Authorization/roleAssignments'
          apiVersion: '2020-10-01-preview'
          name: guid(cluster.name)
          scope: containerRegistry.id
          properties: {
            principalId: managedCluster.properties.identityProfile.kubeletidentity.objectId
            principalType: 'ServicePrincipal'
            roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
          }
        }
      ]
    }
  }
}

// ---------
// Resources
// ---------

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: services.name
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

// -------
// Modules
// -------

module diagnostics './resources.diagnostics.bicep' = {
  name: 'Microsoft.Resources.Diagnostics.${defaults.locations[cluster.location]}'
  params: {
    services: services
    cluster: cluster
  }
  dependsOn: [
    serviceBus
    keyVault
    storageAccount
    managedCluster
    virtualNetwork
    securityGroup
  ]
}

module endpoints './resources.endpoints.bicep' = {
  name: 'Microsoft.Resources.Endpoints.${defaults.locations[cluster.location]}'
  scope: resourceGroup(cluster.subscription, cluster.properties.endpoints.resourceGroup)
  params: {
    services: services
    cluster: cluster
  }
  dependsOn: [
    serviceBus
    keyVault
    storageAccount
    managedCluster
    virtualNetwork
    securityGroup
  ]
}

// ---------
// Variables
// ---------

var defaults = loadJsonContent('../../defaults.json')

// ----------
// Parameters
// ----------

param services object
param cluster object
param applicationId string
