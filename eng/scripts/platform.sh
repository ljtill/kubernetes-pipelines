#!/bin/bash

set -e

#
# Environment
#

environment()
{
    echo "=> Loading runtime variables..."

    tenant_id=$(az account show -o json | jq -r '.tenantId')
    config_path="../configs/platform.local.json"
    config_data=$(cat $config_path)
    deployment_name="Microsoft.Bicep.Resources"
    location="Norway East"
    app_name="Pipelines"

    # TODO(ljtill): Check environment connection - kubectl & helm
}

#
# Deploy
#

deploy()
{
    echo "=> Deploying platform..."

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
    az deployment sub create --name "$deployment_name" --location "$location" --template-file "./region.bicep"
}

#
# Delete
#

delete()
{
    echo "=> Deleting platform..."

    echo "==> Removing cluster resources..."
    echo "$config_data" | jq -r ".clusters[].resourceGroup" | xargs -rtL1 az group delete --yes --name

    echo "==> Removing service resources..."
    echo "$config_data" | jq -r ".services.resourceGroup" | xargs -rtL1 az group delete --yes --name

    if [[ -z "$(az ad app list --display-name "$app_name" -o json | jq -r '.[]')" ]]; then
        echo "==> Deleting azure ad application..."
        app_id=$(az ad app list --display-name "$app_name" -o json | jq -r '.[].appId')
        az ad app delete --id "" -o none
    else
        echo "==> Skipping azure ad application deletion..."
    fi

    echo "=> Purging vaults..."
    az keyvault list-deleted -o json | jq -r '.[].name' | xargs -rtL1 az keyvault purge --name
}

delete_autoscaler()
{
    if [[ -n "$(helm list --namespace keda-system -o json | jq -r '.[] | select(.name == "keda")')" ]]; then
        echo "==> Uninstalling helm chart...."
        helm uninstall keda --namespace keda-system
    else
        echo "==> Skipping helm chart installation..."
    fi

    if [[ -n "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "keda-system")')" ]]; then
        echo "==> Deleting kubernetes namespace..."
        kubectl delete namespace keda-system
    else
        echo "==> Skipping kubernetes namespace deletion..."
    fi
}

delete_identity()
{
    if [[ -n "$(helm list --namespace workload-identity-system -o json | jq -r '.[] | select(.name == "workload-identity-webhook")')" ]]; then
        echo "==> Uninstall helm chart..."
        helm uninstall workload-identity-webhook --namespace azure-workload-identity-system
    else
        echo "==> Skipping helm chart installation..."
    fi

    if [[ -n "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "workload-identity-system")')" ]]; then
        echo "==> Deleting kubernetes namespace..."
        kubectl delete namespace workload-identity-system
    else
        echo "==> Skipping kubernetes namespace deletion..."
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

bootstrap_autoscaler()
{
    echo -e "\n=> Bootstrapping kubernetes autoscaler..."

    # Kubernetes

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
}

bootstrap_identity()
{
    echo -e "\n=> Bootstrapping azure workload identity..."

    # Azure Active Directory

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

    # Kubernetes

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
    "environment")
        environment
        ;;
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
        bootstrap_autoscaler
        bootstrap_identity
        ;;
    "delete")
        environment
        delete
        ;;
    "purge")
        environment
        purge
        ;;
    *)
        echo "Missing argument"
        ;;
esac
