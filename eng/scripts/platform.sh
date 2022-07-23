#!/bin/bash

set -e

#
# Environment
#

environment()
{
    echo "=> Checking environment variables..."
    if [[ -z "$(RESOURCE_GROUP)" || -z "$(CLUSTER_NAME)" || -z "$(TENANT_ID)" ]]; then \
        echo "Missing required environment variables"; \
        exit 1; \
    fi
}

#
# Deploy
#

deploy()
{
    echo '=> Deploying platform...'
    az deployment sub create \
        --name 'Microsoft.Bicep.Resources' \
        --location 'Norway East' \
        --template-file './region.bicep'
}

#
# Delete
#

delete()
{
    echo '=> Destroying platform...'

    echo '==> Destroying endpoints...'
    cat ../config/platform.local.json \
        | jq -r '.endpoints.resourceGroup' \
        | xargs -rtL1 az group delete --yes --name

    echo '==> Destroying clusters...'
    cat ../config/platform.local.json \
        | jq -r '.clusters[].resourceGroup' \
        | xargs -rtL1 az group delete --yes --name

    echo '==> Destroying services...'
    cat ../config/platform.local.json \
        | jq -r '.services.resourceGroup' \
        | xargs -rtL1 az group delete --yes --name

    echo '==> Destroying zones...'
    cat ../config/platform.local.json \
        | jq -r '.zones.resourceGroup' \
        | xargs -rtL1 az group delete --yes --name
}

#
# Purge
#

purge()
{
    echo '=> Purging vaults...'
    az keyvault list-deleted --query '[].name' -o tsv | xargs -rtL1 az keyvault purge --name
}

#
# Validate
#

validate()
{
    echo '=> Validating platform...'
    az deployment sub what-if --name 'Microsoft.Bicep.Resources' --location 'Norway East' --template-file './region.bicep'
}

#
# Bootstrap
#

bootstrap()
{

    deploy_kubernetes_autoscaler()
    {
        echo -e '==> Adding Helm Repo...'
        helm repo add kedacore https://kedacore.github.io/charts

        echo -e '==> Updating Helm Repos...'
        helm repo update

        echo -e '==> Creating Kubernetes Namespace...'
        kubectl create namespace keda

        echo -e '==> Installing KEDA via Helm...'
        helm install keda kedacore/keda --namespace keda
    }

    delete_kubernetes_autoscaler()
    {
        echo '==> Uninstalling helm chart....'
        helm uninstall keda --namespace keda

        echo '==> Deleting namespace...'
        kubectl delete namespace keda
    }

    deploy_workload_identity()
    {
        echo '==> Adding helm repo...'
        helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts

        echo '==> Updating helm repos...'
        helm repo update

        echo '==> Installing workload identity via helm...'
        helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
            --namespace azure-workload-identity-system \
            --create-namespace \
            --set azureTenantID=$1

        echo '==> Creating kubernetes namespace...'
        kubectl create namespace functions

        echo '==> Creating kubernetes service account...'
        kubectl create serviceaccount workload-identity-sa -n functions
        kubectl annotate serviceaccount workload-identity-sa -n functions azure.workload.identity/client-id=$2
        kubectl label serviceaccount workload-identity-sa -n functions azure.workload.identity/use=true

        echo '=> Creating application...'
        az ad app create --display-name 'Pipelines' --query 'appId' --output none
        CLIENT_ID=`az ad app list --display-name "Pipelines" --query '[0].appId' --output tsv`
        OBJECT_ID=`az ad app list --display-name "Pipelines" --query '[0].id' --output tsv`

        echo '==> Creating service principal...'
        az ad sp create --id $CLIENT_ID --output none

        ISSUER_URL=`az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query 'oidcIssuerProfile.issuerUrl' --output tsv`
        BODY="{\"name\": \"kubernetes-federated-credential\", \"issuer\": \"$(ISSUER_URL)\", \"subject\": \"system:serviceaccount:functions:workload-identity-sa\", \"description\": \"TBD\", \"audiences\": [\"api://AzureADTokenExchange\"]}"

        echo '==> Creating federated credentials...'
        az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$(OBJECT_ID)/federatedIdentityCredentials" --body $BODY --output none
    }

    delete_workload_identity()
    {
        echo '==> Uninstall helm chart...'
        helm uninstall workload-identity-webhook --namespace azure-workload-identity-system

        echo '==> Deleting service account...'
        kubectl delete serviceaccount workload-identity-sa -n functions
    }

    bootstrap_cluster()
    {
        echo -e '\n=> Bootstrapping Kubernetes Event Driven Autoscaler...'
        if helm status keda --namespace keda &>/dev/null; then
            echo -e "==> Skipping installation..."
            return
        else
            deploy_kubernetes_autoscaler()
        fi

        echo -e '\n=> Bootstrapping Azure Workload Identity...'
        if helm status workload-identity-webhook --namespace azure-workload-identity-system &>/dev/null; then
            echo -e "==> Skipping installation..."
            return
        else
            deploy_workload_identity()
        fi
    }
}

#
# Invocation
#

command=$(echo $1 | tr '[:upper:]' '[:lower:]')

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
    "purge")
        environment
        purge
        ;;
    *)
        echo "Missing argument"
        ;;
esac