// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

resource serviceBusDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: serviceBus
  properties: {
    logs: [
      {
        enabled: true
        category: 'OperationalLogs'
      }
      {
        enabled: true
        category: 'RuntimeAuditLogs'
      }
      {
        enabled: true
        category: 'ApplicationMetricsLogs'
      }
    ]
    metrics: [
      {
        enabled: false
        category: 'AllMetrics'
      }
    ]
    workspaceId: workspace.id
  }
}
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: keyVault
  properties: {
    logs: [
      {
        enabled: true
        category: 'AuditEvent'
      }
    ]
    metrics: [
      {
        enabled: false
        category: 'AllMetrics'
      }
    ]
    workspaceId: workspace.id
  }
}
resource storageAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: storageAccount
  properties: {
    logs: []
    metrics: []
    workspaceId: workspace.id
  }
}
resource managedClusterDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: managedCluster
  properties: {
    logs: [
      {
        enabled: true
        category: 'kube-apiserver'
      }
      {
        enabled: true
        category: 'kube-audit'
      }
      {
        enabled: true
        category: 'kube-audit-admin'
      }
      {
        enabled: true
        category: 'kube-controller-manager'
      }
      {
        enabled: true
        category: 'kube-scheduler'
      }
      {
        enabled: true
        category: 'cluster-autoscaler'
      }
      {
        enabled: true
        category: 'cloud-controller-manager'
      }
      {
        enabled: true
        category: 'guard'
      }
      {
        enabled: true
        category: 'csi-azuredisk-controller'
      }
      {
        enabled: true
        category: 'csi-azurefile-controller'
      }
      {
        enabled: true
        category: 'csi-snapshot-controller'
      }
    ]
    metrics: [
      {
        enabled: false
        category: 'AllMetrics'
      }
    ]
    workspaceId: workspace.id
  }
}
resource virtualNetworkDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: virtualNetwork
  properties: {
    logs: [
      {
        enabled: true
        category: 'VMProtectionAlerts'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
    workspaceId: workspace.id
  }
}
resource securityGroupDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'default'
  scope: securityGroup
  properties: {
    logs: [
      {
        enabled: true
        category: 'NetworkSecurityGroupEvent'
      }
      {
        enabled: true
        category: 'NetworkSecurityGroupRuleCounter'
      }
    ]
    workspaceId: workspace.id
  }
}

// ---------
// Resources
// ---------

// Services
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: services.name
  scope: resourceGroup(services.subscription, services.resourceGroup)
}

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
resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-03-02-preview' existing = {
  name: cluster.name
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: cluster.name
}
resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' existing = {
  name: cluster.name
}

// ----------
// Parameters
// ----------

param services object
param cluster object
