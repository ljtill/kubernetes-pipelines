#!/bin/bash

set -e

#
# Environment
#

environment()
{
    echo "=> Setting runtime variables..."

    # TODO: Application name needs to be unique

    tenant_id=$(az account show -o json | jq -r '.tenantId')
    config_path="../configs/platform.local.json"
    config_data=$(cat $config_path)
    deployment_name="Microsoft.Bicep.Resources"
    location="Norway East"
    app_name="Pipelines"
}

#
# Deploy
#

deploy()
{
    echo "=> Deploying platform..."

    # TODO: Handle duplicate application names

    if [[ -z "$(az ad app list --display-name "$app_name" -o json | jq -r '.[]')" ]]; then
        echo "==> Creating azure ad application..."
        az ad app create --display-name "$app_name" -o none
    else
        echo "==> Skipping azure ad application creation..."
    fi

    if [[ -z "$(az ad sp list --display-name "$app_name" -o json | jq -r '.[]')" ]]; then
        echo "==> Creating azure ad service principal..."
        app_id=$(az ad app list --display-name "$app_name" -o json | jq -r '.[].appId')
        az ad sp create --id "$app_id" -o none
    else
        echo "==> Skipping azure ad service principal creation..."
    fi

    echo "==> Deploying azure resources..."
    echo "$config_data" | jq -r '.services.subscription' | xargs -rtL1 az account set --subscription
    az deployment sub create --name "$deployment_name" --location "$location" --template-file "./region.bicep" --parameters applicationId=$app_id
}

#
# Delete
#

delete()
{
    echo "=> Deleting platform..."

    # TODO: Iterate over all cluster subscriptions
    # TODO: Check if deletion is necessary

    echo "==> Removing cluster resources..."
    echo "$config_data" | jq -r '.clusters[0].subscription' | xargs -rtL1 az account set --subscription
    echo "$config_data" | jq -r ".clusters[].resourceGroup" | xargs -rtL1 az group delete --yes --name

    echo "==> Removing service resources..."
    echo "$config_data" | jq -r '.services.subscription' | xargs -rtL1 az account set --subscription
    echo "$config_data" | jq -r ".services.resourceGroup" | xargs -rtL1 az group delete --yes --name

    echo "==> Purging key vaults..."
    az keyvault list-deleted -o json | jq -r '.[].name' | xargs -rtL1 az keyvault purge --name

    if [[ -n "$(az ad app list --display-name "$app_name" -o json | jq -r '.[]')" ]]; then
        echo "==> Deleting azure ad application..."
        app_id=$(az ad app list --display-name "$app_name" -o json | jq -r '.[].appId')
        az ad app delete --id "$app_id" -o none
    else
        echo "==> Skipping azure ad application deletion..."
    fi
}

#
# Validate
#

validate()
{
    echo "=> Validating platform..."
    az deployment sub what-if --name "$deployment_name" --location "$location" --template-file "./region.bicep"
}

#
# Bootstrap
#

bootstrap()
{
    echo -e "\n=> Bootstrapping platform..."

    # NOTE: Kubernetes Event Driven Autoscaler

    echo "==> Installing kubernetes autoscaler..."

    if [[ -z "$(helm repo list -o json | jq -r '.[] | select(.name == "kedacore")')" ]]; then
        echo "==> Adding helm chart repo..."
        helm repo add kedacore https://kedacore.github.io/charts
    else
        echo "==> Skipping helm chart repo addition..."
    fi

    echo "==> Updating helm chart information..."
    helm repo update 1>/dev/null

    if [[ -z "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "keda-system")')" ]]; then
        echo "==> Creating kubernetes namespace..."
        kubectl create namespace keda-system
    else
        echo "==> Skipping kubernetes namespace creation..."
    fi

    if [[ -z "$(helm list --namespace keda-system -o json | jq -r '.[] | select(.name == "keda")')" ]]; then
        echo "==> Installing helm chart..."
        helm install keda kedacore/keda --namespace keda-system
    else
        echo "==> Skipping helm chart installation..."
    fi

    # NOTE: Azure Workload Identity

    echo "==> Installing azure workload identity..."

    app_metadata=$(az ad app list --display-name "$app_name" -o json)
    app_id=$(echo "$app_metadata" | jq -r ".[].appId")
    object_id=$(echo "$app_metadata" | jq -r ".[].id")

    if [[ -z "$(az rest --method GET --uri "https://graph.microsoft.com/beta/applications/$object_id/federatedIdentityCredentials" | jq -r '.value[]')" ]]; then
        echo "==> Creating federated credentials..."
        issuer_url=$(az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "oidcIssuerProfile.issuerUrl" -o tsv)
        rest_body="{\"name\": \"kubernetes-federated-credential\", \"issuer\": \"$issuer_url\", \"subject\": \"system:serviceaccount:functions-system:functions\", \"description\": \"TBD\", \"audiences\": [\"api://AzureADTokenExchange\"]}"
        az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$object_id/federatedIdentityCredentials" --body "$rest_body" -o none
    else
        echo "==> Skipping federated credentials creation..."
    fi

    if [[ -z "$(helm repo list -o json | jq -r '.[] | select(.name == "azure-workload-identity")')" ]]; then
        echo "==> Adding helm chart repo..."
        helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
    else
        echo "==> Skipping helm chart repo addition..."
    fi

    echo "==> Updating helm repo index..."
    helm repo update 1>/dev/null

    if [[ -z "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "workload-identity-system")')" ]]; then
        echo "==> Creating kubernetes namespace..."
        kubectl create namespace workload-identity-system
    else
        echo "==> Skipping kubernetes namespace creation..."
    fi

    if [[ -z "$(helm list --namespace workload-identity-system -o json | jq -r '.[] | select(.name == "workload-identity-webhook")')" ]]; then
        echo "==> Installing helm chart..."
        helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook --namespace workload-identity-system --set azureTenantID="$tenant_id"
    else
        echo "==> Skipping helm chart installation..."
    fi
}

#
# Invocation
#

command=$(echo "$1" | tr "[:upper:]" "[:lower:]")

case $command in
    "deploy")
        environment
        deploy
        ;;
    "validate")
        environment
        validate
        ;;
    "bootstrap")
        environment
        bootstrap
        ;;
    "delete")
        environment
        delete
        ;;
    *)
        echo "Missing argument"
        ;;
esac
