#!/bin/bash

set -e

#
# Variables
#

deployment_name="Microsoft.Bicep.Resources"
location="Norway East"
config_path="../configs/platform.local.json"

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

    # TODO(ljtill): Check environment connection - kubectl & helm
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

bootstrap_autoscaler()
{
    echo -e "\n=> Bootstrapping kubernetes autoscaler..."

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
        helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook --namespace workload-identity-system --set azureTenantID="$TENANT_ID"
    else
        echo "==> Skipping helm chart installation..."
    fi

    if [[ -z "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "functions-system")')" ]]; then
        echo "==> Creating kubernetes namespace..."
        kubectl create namespace functions-system
    else
        echo "==> Skipping kubernetes namespace creation..."
    fi

    if [[ -z "$(az ad app list --display-name "Pipelines" -o json | jq -r '.[]')" ]]; then
        echo "==> Creating azure ad application..."
        az ad app create --display-name "Pipelines" -o none
    else
        echo "==> Skipping azure ad application creation..."
    fi

    app_metadata=$(az ad app list --display-name "Pipelines" -o json)
    app_id=$(echo "$app_metadata" | jq -r ".[].appId")
    object_id=$(echo "$app_metadata" | jq -r ".[].id")

    if [[ -z "$(az ad sp list --display-name "Pipelines" -o json | jq -r '.[]')" ]]; then
        echo "==> Creating azure ad service principal..."
        az ad sp create --id "$app_id" -o none
    else
        echo "==> Skipping azure ad service principal creation..."
    fi

    if [[ -z "$(kubectl get serviceaccount -n functions-system -o json | jq -r '.items[] | select(.metadata.name == "workload-identity-sa")')" ]]; then
        echo "==> Creating kubernetes service account..."
        kubectl create serviceaccount workload-identity-sa --namespace functions-system
        kubectl annotate serviceaccount workload-identity-sa --namespace functions-system azure.workload.identity/client-id="$appId"
        kubectl label serviceaccount workload-identity-sa --namespace functions-system azure.workload.identity/use=true
    else
        echo "==> Skipping kubernetes service account creation..."
    fi


    if [[ -z "$(az rest --method GET --uri "https://graph.microsoft.com/beta/applications/$object_id/federatedIdentityCredentials" | jq -r '.value[]')" ]]; then
        echo "==> Creating federated credentials..."
        issuer_url=$(az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)
        rest_body="{\"name\": \"kubernetes-federated-credential\", \"issuer\": \"$issuer_url\", \"subject\": \"system:serviceaccount:functions-system:workload-identity-sa\", \"description\": \"TBD\", \"audiences\": [\"api://AzureADTokenExchange\"]}"
        az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$object_id/federatedIdentityCredentials" --body "$rest_body" -o none
    else
        echo "==> Skipping federated credentials creation..."
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
        deploy
        ;;
    "validate")
        validate
        ;;
    "bootstrap")
        environment
        bootstrap_autoscaler
        bootstrap_identity
        ;;
    "delete")
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
