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
      ipRules: [for inboundConnection in inboundConnections: {
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
    kubernetesVersion: kubernetesVersion
    nodeResourceGroup: 'Local-Nodes-${cluster.properties.country}'
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
  name: guid('ServiceBusDataReceiver', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.serviceBusDataReceiver)
  }
}
resource serviceBusSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ServiceBusDataSender', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.serviceBusDataSender)
  }
}

// Key Vault
resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('KeyVaultSecretsOfficer', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.keyVaultSecretsOfficer)
  }
}

// Storage Account
resource storageAccountBlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageBlobDataContributor', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageBlobDataContributor)
  }
}
resource storageAccountFileContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageFileDataContributor', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageFileDataContributor)
  }
}
resource storageAccountQueueContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageQueueDataContributor', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageQueueDataContributor)
  }
}
resource storageAccountTableContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('StorageTableDataContributor', applicationId)
  properties: {
    principalId: applicationId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageTableDataContributor)
  }
}

// -----------
// Deployments
// -----------

// Virtual Network Links
resource links 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'Microsoft.Bicep.Resources.Network'
  subscriptionId: services.subscription
  resourceGroup: services.resourceGroup
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
// NOTE: Workaround for cross resource group role assignments
resource authorization 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'Microsoft.Bicep.Authorization.Services'
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
            principalType: 'ServicePrincipal'
            principalId: managedCluster.properties.identityProfile.kubeletidentity.objectId
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
  name: 'Microsoft.Bicep.Resources.Diagnostics.${cluster.properties.country}'
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
  name: 'Microsoft.Bicep.Resources.Endpoints.${cluster.properties.country}'
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

var kubernetesVersion = '1.22.11'
var inboundConnections = [
  '20.37.194.0/24' // Australia East
  '20.42.226.0/24' // Australia South East
  '191.235.226.0/24' // Brazil South
  '52.228.82.0/24' // Central Canada
  '20.195.68.0/24' // Asia Pacific
  '20.41.194.0/24' // South India
  '20.37.158.0/23' // Central United States
  '52.150.138.0/24' // West Central United States
  '20.42.5.0/24' // East United States
  '20.41.6.0/23' // East 2 United States
  '40.80.187.0/24' // North United States
  '40.119.10.0/24' // South United States
  '40.82.252.0/24' // West United States
  '20.42.134.0/23' // West US 2 United States
  '40.74.28.0/23' // Western Europe
  '51.104.26.0/24' // United Kingdom South
]
var roleDefinitions = {
  serviceBusDataReceiver: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
  serviceBusDataSender: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  keyVaultSecretsOfficer: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
  storageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  storageFileDataContributor: '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
  storageQueueDataContributor: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  storageTableDataContributor: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
}

// ----------
// Parameters
// ----------

param services object
param cluster object
param applicationId string
