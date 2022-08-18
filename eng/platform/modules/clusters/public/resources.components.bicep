// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Public IP
resource ipAddress 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: cluster.name
  location: cluster.location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

// Kubernetes
resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: cluster.name
  location: cluster.location
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    nodeResourceGroup: cluster.properties.nodes.resourceGroup
    enableRBAC: true
    dnsPrefix: cluster.name
    disableLocalAccounts: false
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
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        nodeTaints: []
        enableNodePublicIP: false
        tags: {}
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'kubenet'
      outboundType: 'managedNATGateway'
      natGatewayProfile: {
        effectiveOutboundIPs: [
          {
            id: ipAddress.id
          }
        ]
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    autoUpgradeProfile: {
      upgradeChannel: 'rapid'
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azureKeyVaultSecretsProvider: {
        enabled: true
      }
    }
  }
}

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

// -----------
// Deployments
// -----------

// NOTE: Workaround for cross resource deployments

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

// ---------
// Variables
// ---------

var defaults = loadJsonContent('../../../defaults.json')

// ----------
// Parameters
// ----------

param services object
param cluster object
