#!/bin/bash

set -e

#
# Environment
#

environment()
{
    echo "=> Loading configuration variables..."

    # TODO: Handle multiple cluster configurations
    config_data=$(cat ../../eng/configs/platform.local.json)
    service_name=$(echo "$config_data" | jq -r '.services.name')
    cluster_name=$(echo "$config_data" | jq -r '.clusters[0].name')

    # TODO: Handle multiple applications
    app_id=$(az ad app list --display-name 'Pipelines' -o json | jq -r '.[0].appId')
}

#
# Login
#

login()
{
    echo "=> Authenticating session..."
    az acr login --name "$service_name"
}

#
# Build
#

build()
{
    echo -e "\n=> Building runtime..."
    dotnet build Pipelines.Runtime.csproj -c Release

    echo -e "\n=> Building image..."
    docker build -t "$service_name".azurecr.io/runtimes/functions:latest .
}

#
# Generate
# Provides the ability to generate the Kubernetes manifest from the Configuration Metadata
#

generate()
{
    echo "=> Generating deployment files..."

    rm ./functions.local.yaml

    echo "==> Copying kubernetes manifest..."
    cp ./functions.yaml functions.local.yaml

    echo "==> Replacing manifest value..."
    sed -i "s/<StorageAccountName>/$cluster_name/g" ./functions.local.yaml
    sed -i "s/<ServiceBusName>/$cluster_name/g" ./functions.local.yaml
    sed -i "s/<RegistryName>/$service_name/g" ./functions.local.yaml
    sed -i "s/<ClientId>/$app_id/g" ./functions.local.yaml
}

#
# Push
#

push()
{
    echo "=> Pushing image..."
    docker push "$service_name".azurecr.io/runtimes/functions:latest
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
    echo "=> Starting functions host..."
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
}

#
# Delete
#

delete()
{
    echo "=> Destroying runtime..."

    if [[ -n "$(kubectl get deployment -n functions-system -o json | jq -r '.items[] | select(.metadata.name == "functions")')" ]]; then
        echo "==> Deleting kubernetes deployment..."
        kubectl delete -f ./functions.yaml
        #func kubernetes delete --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY_NAME.azurecr.io/runtime" --namespace "$namespace"
    else
        echo "==> Skipping kubernetes deployment deletion..."
    fi

    if [[ -n "$(kubectl get namespace -o json | jq -r '.items[] | select(.metadata.name == "functions-system")')" ]]; then
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
    "generate")
        environment
        generate
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
