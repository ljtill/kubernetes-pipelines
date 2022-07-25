#!/bin/bash

set -e

#
# Variables
#

deployment_name="Microsoft.Bicep.Resources"
location="Norway East"
config_path="../config/platform.local.json"

#
# Environment
#

environment()
{
    echo "=> Checking environment variables..."

    if [[ -z "$TENANT_ID" ]]; then
        echo "Missing required environment variable (TENANT_ID)"
        exit 1
    fi
    echo "==> Reading variable - TENANT_ID :: $TENANT_ID"

    if [[ -z "$RESOURCE_GROUP" ]]; then
        echo "Missing required environment variable (RESOURCE_GROUP)"
        exit 1
    fi
    echo "==> Reading variable - RESOURCE_GROUP :: $RESOURCE_GROUP"

    if [[ -z "$CLUSTER_NAME" ]]; then
        echo "Missing required environment variable (CLUSTER_NAME)"
        exit 1
    fi
    echo "==> Reading variable - CLUSTER_NAME :: $CLUSTER_NAME"
}

#
# Deploy
#

deploy()
{
    echo "=> Deploying platform..."
    az deployment sub create \
        --name "$deployment_name" \
        --location "$location" \
        --template-file "./region.bicep"
}

#
# Delete
#

delete()
{
    echo "=> Deleting platform..."

    echo "==> Removing endpoint resources..."
    cat $config_path \
        | jq -r ".endpoints.resourceGroup" \
        | xargs -rtL1 az group delete --yes --name

    echo "==> Removing cluster resources..."
    cat $config_path \
        | jq -r ".clusters[].resourceGroup" \
        | xargs -rtL1 az group delete --yes --name

    echo "==> Removing service resources..."
    cat $config_path \
        | jq -r ".services.resourceGroup" \
        | xargs -rtL1 az group delete --yes --name

    echo "==> Removing zone resources..."
    cat $config_path \
        | jq -r ".zones.resourceGroup" \
        | xargs -rtL1 az group delete --yes --name
}

#
# Purge
#

purge()
{
    echo "=> Purging vaults..."
    az keyvault list-deleted --query "[].name" -o tsv \
        | xargs -rtL1 az keyvault purge --name
}

#
# Validate
#

validate()
{
    echo "=> Validating platform..."
    az deployment sub what-if \
        --name "$deployment_name" \
        --location "$location" \
        --template-file "./region.bicep"
}

#
# Bootstrap
#

bootstrap()
{
    bootstrap_autoscaler()
    {
        echo "=> Bootstrapping Kubernetes Event Driven Autoscaler..."

        status=$(helm status keda --namespace keda &>/dev/null)
        if [[ -z "$status" ]]; then
            echo "==> Skipping installation..."
            return
        fi

        echo "==> Adding Helm Repo..."
        helm repo add kedacore https://kedacore.github.io/charts

        echo "==> Updating Helm Repos..."
        helm repo update

        echo "==> Creating Kubernetes Namespace..."
        kubectl create namespace keda

        echo "==> Installing KEDA via Helm..."
        helm install keda kedacore/keda --namespace keda
    }

    bootstrap_identity()
    {
        echo "=> Bootstrapping Azure Workload Identity..."

        status=$(helm status workload-identity-webhook --namespace azure-workload-identity-system &>/dev/null)

        echo "==> Checking for existing Helm installation..."
        if [[ -z "$status" ]]; then
            echo "==> Skipping installation..."
            return
        fi

        echo "==> Adding helm repo..."
        helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts

        echo "==> Updating helm repos..."
        helm repo update

        echo "==> Installing workload identity via helm..."
        helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
            --namespace azure-workload-identity-system \
            --create-namespace \
            --set azureTenantID="$1"

        echo "==> Creating kubernetes namespace..."
        kubectl create namespace functions

        echo "==> Creating kubernetes service account..."
        kubectl create serviceaccount workload-identity-sa -n functions
        kubectl annotate serviceaccount workload-identity-sa -n functions azure.workload.identity/client-id="$2"
        kubectl label serviceaccount workload-identity-sa -n functions azure.workload.identity/use=true

        echo "=> Creating application..."
        az ad app create --display-name "Pipelines" --query "appId" --output none

        client_id=$(az ad app list --display-name "Pipelines" --query "[0].appId" --output tsv)
        object_id=$(az ad app list --display-name "Pipelines" --query "[0].id" --output tsv)

        echo "==> Creating service principal..."
        az ad sp create --id "$client_id" --output none

        issuer_url=$(az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" --output tsv)
        rest_body="{\"name\": \"kubernetes-federated-credential\", \"issuer\": \"$issuer_url\", \"subject\": \"system:serviceaccount:functions:workload-identity-sa\", \"description\": \"TBD\", \"audiences\": [\"api://AzureADTokenExchange\"]}"

        echo "==> Creating federated credentials..."
        az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$object_id/federatedIdentityCredentials" --body "$rest_body" --output none
    }

    # TODO: Implement component removal
    # delete_autoscaler()
    # {
    #     echo "==> Uninstalling helm chart...."
    #     helm uninstall keda --namespace keda

    #     echo "==> Deleting namespace..."
    #     kubectl delete namespace keda
    # }

    # TODO: Implement component removal
    # delete_identity()
    # {
    #     echo "==> Uninstall helm chart..."
    #     helm uninstall workload-identity-webhook --namespace azure-workload-identity-system

    #     echo "==> Deleting service account..."
    #     kubectl delete serviceaccount workload-identity-sa -n functions
    # }

    #
    # Invocation
    #

    command=$(echo "$1" | tr "[:upper:]" "[:lower:]")

    case $command in
        "autoscaler")
            bootstrap_autoscaler
            ;;
        "identity")
            bootstrap_identity "$1" "$2"
            ;;
        "all")
            bootstrap_autoscaler
            bootstrap_identity "$1" "$2"
            ;;
        *)
            echo "Missing argument"
            ;;
    esac

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
        bootstrap "$2"
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
