#!/bin/bash

bootstrap_kubernetes_autoscaler()
{
    if helm status keda --namespace keda &>/dev/null; then
        echo -e "==> Skipping installation..."
        return
    else
        echo -e '==> Adding Helm Repo...'
        helm repo add kedacore https://kedacore.github.io/charts

        echo -e '==> Updating Helm Repos...'
        helm repo update

        echo -e '==> Creating Kubernetes Namespace...'
        kubectl create namespace keda

        echo -e '==> Installing KEDA via Helm...'
        helm install keda kedacore/keda --namespace keda
    fi
}

bootstrap_workload_identity()
{
    if helm status workload-identity-webhook --namespace azure-workload-identity-system &>/dev/null; then
        echo -e "==> Skipping installation..."
        return
    else
        echo -e '==> Adding Helm Repo...'
        helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts

        echo -e '==> Updating Helm Repos...'
        helm repo update

        echo -e '==> Installing Workload Identity via Helm...'
        helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
            --namespace azure-workload-identity-system \
            --create-namespace \
            --set azureTenantID=$1
    fi
}

echo -e '\n=> Bootstrapping Kubernetes Event Driven Autoscaler...'
bootstrap_kubernetes_autoscaler
# helm uninstall keda --namespace keda

echo -e '\n=> Bootstrapping Azure Workload Identity...'
bootstrap_workload_identity $1
# helm uninstall workload-identity-webhook --namespace azure-workload-identity-system