param(
    [Parameter()]
    [String]$InfraAction
)

function Environment {
    $tenantId = $(az account show -o json --query "tenantId")
    $configPath = "../configs/platform.local.json"
    $configData = $(cat $configPath)
    $deploymentName = "Microsoft.Resources"
    $location = "eastus2"
    $appName = "Pipelines2"

    $props = @{
        TenantId       = $tenantId
        ConfigPath     = $configPath
        ConfigData     = $configData
        DeploymentName = $deploymentName
        Location       = $location
        AppName        = $appName
    }

    $envVariables = new-object psobject -Property $props

    return $envVariables
}

function Bootstrap($environmentVariables) {
    $tenantId = $environmentVariables.TenantId
    $appName = $environmentVariables.AppName

    Write-Output "\n=> Bootstrapping platform..."

    # NOTE: Kubernetes Event Driven Autoscaler

    Write-Output "==> Installing kubernetes autoscaler..."

    # Kubernetes
    $checkHelmRepo = $(helm repo list -o json | ConvertFrom-Json) | Where-Object { $_.name -eq "kedacore" }

    if (!$checkHelmRepo) {
        Write-Output "==> Adding helm chart repo..."
        helm repo add kedacore https://kedacore.github.io/charts
    }
    else {
        Write-Output "==> Skipping helm chart repo addition..."
    }

    Write-Output "==> Updating helm chart information..."
    helm repo update

    $checkKubeNS = $(kubectl get namespace -o json | ConvertFrom-Json).items | Where-Object { $_.metadata.name -eq "keda-system" }

    if (!$checkKubeNS) {
        Write-Output "==> Creating kubernetes namespace..."
        kubectl create namespace keda-system
    }
    else {
        Write-Output "==> Skipping kubernetes namespace creation..."
    }


    $checkWINS = $(helm list --namespace keda-system -o json | ConvertFrom-Json) | Where-Object { $_.name -eq "keda" }

    if (!$checkWINS) {
        Write-Output "==> Installing helm chart..."
        helm install keda kedacore/keda --namespace keda-system
    }
    else {
        Write-Output "==> Skipping helm chart installation..."
    }


    # NOTE: Azure Workload Identity

    Write-Output "==> Installing azure workload identity..."

    $appMetadata = $(az ad app list --display-name "$appName" -o json | ConvertFrom-Json)
    $appId = $appMetadata.appId
    $objectId = $appMetadata.id

    $checkFedCreds = $(az rest --method GET --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" | ConvertFrom-Json)

    if ($checkFedCreds.value -eq {}) {
        Write-Output "==> Creating federated credentials..."
        issuerUrl=$(az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "oidcIssuerProle.issuerUrl" -o tsv)
        restBody="{\"name\": \"kubernetes-federated-credential\", \"issuer\": \"$issuerUrl\", \"subject\": \"system:serviceaccount:functions-system:functions\", \"description\": \"TBD\", \"audiences\": [\"api://AzureADTokenExchange\"]}"
        az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body "$restBody" -o none
    }
    else {
        Write-Output "==> Skipping federated credentials creation..."
    }

    # Kubernetes
    $checkHelmRepo = $(helm repo list -o json | ConvertFrom-Json).name

    if ($checkHelmRepo -ne "azure-workload-identity") {
        Write-Output "==> Adding helm chart repo..."
        helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
    }
    else {
        Write-Output "==> Skipping helm chart repo addition..."
    }

    Write-Output "==> Updating helm repo index..."
    helm repo update

    $checkKubeNS = $(kubectl get namespace -o json | ConvertFrom-Json).items | Where-Object { $_.metadata.name -eq "workload-identity-system" }
    if (!$checkKubeNS) {
        Write-Output "==> Creating kubernetes namespace..."
        kubectl create namespace workload-identity-system
    }
    else {
        Write-Output "==> Skipping kubernetes namespace creation..."
    }


    $checkWINS = $(helm list --namespace workload-identity-system -o json | ConvertFrom-Json) | Where-Object { $_.name -eq "workload-identity-webhook" }

    if (!$checkWINS) {
        Write-Output "==> Installing helm chart..."
        helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook --namespace workload-identity-system --set azureTenantID="$tenantId"
    }
    else {
        Write-Output "==> Skipping helm chart installation..."
    }
}

function Deploy($environmentVariables) {
    $configData = $environmentVariables.ConfigData
    $deploymentName = $environmentVariables.DeploymentName
    $location = $environmentVariables.Location
    $appName = $environmentVariables.AppName

    # Deploy Platform
    Write-Output "=> Deploying platform..."

    # Checking if Azure AD Application exists, create if not
    $checkApp = az ad app list --display-name "$appName" | ConvertFrom-Json

    if (!$checkApp) {
        Write-Output "==> Creating azure ad application..."
        az ad app create --display-name "$appName" -o none
    }

    else {
        Write-Output "==> Skipping azure ad application creation..."
    }

    # Checking if Azure AD Service Principal exists, create if not
    $checkSP = az ad sp list --display-name "$appName" | ConvertFrom-Json
    $appId = $(az ad app list --display-name "$appName" -o json | ConvertFrom-Json).appId

    if (!$checkSP) {
        Write-Output "==> Creating azure ad service principal..."
        az ad sp create --id "$appId" -o none
    }
    else {
        Write-Output "==> Skipping azure ad service principal creation..."
    }

    # Deploy Bicep Resources
    Write-Output "==> Deploying azure resources..."
    $subscriptionId = ($configData | ConvertFrom-Json).services.subscription
    $objectId = $(az ad app list --display-name "$appName" -o json | ConvertFrom-Json).id
    az account set --subscription $subscriptionId
    az deployment sub create --name $deploymentName --location $location --template-file "../platform/main.bicep" --parameters objectId=$objectId

}

function Validate($environmentVariables) {
    $deploymentName = $environmentVariables.DeploymentName
    $location = $environmentVariables.Location
    Write-Output "=> Validating platform..."
    az deployment sub what-if --name "$deploymentName" --location "$location" --template-file "./region.bicep"
}

function Delete($environmentVariables) {
    $configData = $environmentVariables.ConfigData
    $appName = $environmentVariables.AppName
    $config = $configData | ConvertFrom-Json

    Write-Output "=> Deleting platform..."

    Write-Output "==> Removing cluster resources..."
    $subscriptionId = $config.clusters.subscription
    az account set --subscription $subscriptionId

    foreach ($cluster in $config.clusters) {
        az group delete --yes --name $cluster.resourceGroup
    }

    Write-Output "==> Removing service resources..."
    $subscriptionId = $config.services.subscription
    az account set --subscription $subscriptionId

    foreach ($service in $config.services) {
        az group delete --yes --name $service.resourceGroup
    }


    Write-Output "=> Purging vaults..."
    $keyVaultName = $(az keyvault list-deleted -o json | ConvertFrom-Json).name
    az keyvault purge --name $keyVaultName

    $check = $(az ad app list --display-name "$appName" -o json) | ConvertFrom-Json
    if ($check) {
        Write-Output "==> Deleting azure ad application..."
        $appId = $(az ad app list --display-name "$appName" -o json | ConvertFrom-Json).appId
        az ad app delete --id $appId -o none
    }
    else {
        Write-Output "==> Skipping azure ad application deletion..."
    }
}

#
# Invocation
#

switch ($infraAction) {
    "Environment" { Write-Output "Environment Variables Set"; $envVariables = Environment; Write-Output $envVariables }
    "Deploy" { Write-Output "Environment Variables Set"; $envVariables = Environment; Deploy($envVariables) }
    "Validate" { Write-Output "Environment Variables Set"; $envVariables = Environment; Validate($envVariables) }
    "Bootstrap" { Write-Output "Environment Variables Set"; $envVariables = Environment; Bootstrap($envVariables) }
    "Delete" { Write-Output "Environment Variables Set"; $envVariables = Environment; Delete($envVariables) }
    Default { Write-Output "Missing argument" }
}
