#!/bin/bash

set -e

#
# Variables
#

namespace="functions-system"
runtime="functions"

#
# Environment
#

environment()
{
    echo "=> Checking environment variables..."

    if [[ -z "$REGISTRY" ]]; then
        echo "Missing required environment variable (REGISTRY)"
        exit 1
    fi
    echo "==> Reading variable - REGISTRY :: $REGISTRY"
}

#
# Login
#

login()
{
    echo "=> Authenticating session..."
    az acr login --name "$REGISTRY"
}

#
# Build
#

build()
{
    echo "=> Building..."
    # TODO: Add dotnet build instructions
}

#
# Clean
#

clean()
{
    echo "=> Cleaning..."
    # TODO: Add dotnet clean instructions
}

#
# Run
#

run()
{
    echo "=> Running functions host..."
    # TODO: Add func host start instructions
}

#
# Deploy
#

deploy()
{
    echo "=> Deploying runtime..."
	kubectl create namespace "$namespace"
	func kubernetes deploy --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY.azurecr.io/runtime" --min-replicas 1 --namespace "$namespace" --write-config
	kubectl create serviceaccount "$runtime-host" -n "$namespace"
	kubectl create clusterrolebinding "$runtime" --clusterrole=cluster-admin --serviceaccount="$namespace:$runtime-host"
}

#
# Delete
#

delete()
{
    echo "=> Destroying runtime..."
	kubectl delete clusterrolebinding "$runtime" --ignore-not-found=true
	kubectl delete serviceaccount "$runtime-host" -n "$namespace" --ignore-not-found=true
	func kubernetes delete --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY.azurecr.io/runtime" --namespace "$namespace"
	kubectl delete namespace "$namespace"
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
    "clean")
        environment
        clean
        ;;
    "deploy")
        environment
        delete
        ;;
    "delete")
        environment
        delete
        ;;
    *)
        echo "Missing argument"
        ;;
esac
