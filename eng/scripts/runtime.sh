#!/bin/bash

set -e

#
# Variables
#

runtime="functions"

#
# Environment
#

environment()
{
    echo "=> Checking environment variables..."

    if [[ -z "$REGISTRY_NAME" ]]; then
        echo "Missing required environment variable (REGISTRY_NAME)"
        exit 1
    fi
    echo "==> Reading variable - REGISTRY_NAME :: $REGISTRY_NAME"
}

#
# Login
#

login()
{
    echo "=> Authenticating session..."
    az acr login --name "$REGISTRY_NAME"
}

#
# Build
#

build()
{
    echo -e "\n=> Building runtime..."
    dotnet build Pipelines.Runtime.csproj -c Release

    echo -e "\n=> Building image..."
    docker build -t $REGISTRY_NAME.azurecr.io/runtimes/functions:latest .
}

#
# Push
#

push()
{
    echo "=> Pushing image..."
    docker push $REGISTRY_NAME.azurecr.io/runtimes/functions:latest
}

#
# Clean
#

clean()
{
    echo "=> Cleaning..."
    dotnet build Pipelines.Runtime.csproj
}

#
# Run
#

run()
{
    echo "=> Running functions host..."
    func host start
}

#
# Deploy
#

deploy()
{
    echo "=> Deploying runtime..."

    if [[ -z "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "functions-system")')" ]]; then
        echo "==> Creating kubernetes namespace..."
        kubectl create namespace functions-system
    else
        echo "==> Skipping kubernetes namespace creation..."
    fi

    if [[ -z "$(kubectl get deployment -n functions-system -o json | jq -r '.items[] | select(.metadata.name == "functions")')" ]]; then
        echo "==> Creating kubernetes deployment..."
        kubectl apply -f ./functions.yaml
        # func kubernetes deploy --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY_NAME.azurecr.io/runtime" --min-replicas 1 --namespace "$namespace" --write-config
    else
        echo "==> Skipping kubernetes deployment creation..."
    fi

    # kubectl create serviceaccount "$runtime-host" -n "$namespace"
    # kubectl create clusterrolebinding "$runtime" --clusterrole=cluster-admin --serviceaccount="$namespace:$runtime-host"
}

#
# Delete
#

delete()
{
    echo "=> Destroying runtime..."

    if [[ -z "$(kubectl get clusterrolebinding -o json | jq -r '.items[] | select(.metadata.name == "functions")')" ]]; then
        echo "==> Deleting kubernetes cluster role binding..."
        kubectl delete clusterrolebinding functions
    else
        echo "==> Skipping kubernetes cluster role binding deletion..."
    fi

    if [[ -z "$(kubectl get serviceaccount -n functions-system -o json | jq -r '.items[] | select(.metadata.name == "functions")')" ]]; then
        echo "==> Deleting kubernetes service account..."
        kubectl delete serviceaccount functions -n functions-system
    else
        echo "==> Skipping kubernetes service account deletion..."
    fi

    if [[ -z "$(kubectl get deployment -n functions-system -o json | jq -r '.items[] | select(.metadata.name == "functions")')" ]]; then
        echo "==> Deleting kubernetes deployment..."
        kubectl delete -f ./functions.yaml
        #func kubernetes delete --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY_NAME.azurecr.io/runtime" --namespace "$namespace"
    else
        echo "==> Skipping kubernetes deployment deletion..."
    fi

    if [[ -z "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "functions-system")')" ]]; then
        echo "==> Deleting kubernetes namespace..."
        kubectl delete namespace functions-system
    else
        echo "==> Skipping kubernetes namespace deletion..."
    fi
}

#
# Invocation
#

command=$(echo "$1" | tr "[:upper:]" "[:lower:]")

case $command in
    "login")
        environment
        login
        ;;
    "build")
        environment
        build
        ;;
    "push")
        environment
        push
        ;;
    "clean")
        clean
        ;;
    "run")
        run
        ;;
    "deploy")
        environment
        deploy
        ;;
    "delete")
        environment
        delete
        ;;
    *)
        echo "Missing argument"
        ;;
esac
