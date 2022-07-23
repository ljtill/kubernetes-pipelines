#!/bin/bash

set -e

#
# Variables
#

namespace=""
runtime=""

#
# Environment
#

environment()
{
    echo "=> Checking environment variables..."
	if [[ -z "$(NAMESPACE)" || -z "$(RUNTIME_NAME)" || -z "$(REGISTRY_NAME)" ]]; then \
		echo "Missing required environment variables"; \
		exit 1; \
	fi
}

#
# Login
#

login()
{
    echo '=> Authenticating session...'
    az acr login --name $(REGISTRY_NAME)
}

#
# Build
#

build()
{
    echo '=> Building...'
    # TODO: Add dotnet build instructions
}

#
# Clean
#

clean()
{
    echo '=> Cleaning...'
    # TODO: Add dotnet clean instructions
}

#
# Deploy
#

deploy()
{
    echo "=> Deploying runtime..."
	kubectl create namespace $(NAMESPACE)
	func kubernetes deploy --name $(RUNTIME_NAME) --image-name runtime/$(RUNTIME_NAME) --registry $(REGISTRY_NAME).azurecr.io/runtime --min-replicas 1 --namespace $(NAMESPACE) --write-config
	kubectl create serviceaccount $(RUNTIME_NAME)-host -n $(NAMESPACE)
	kubectl create clusterrolebinding $(RUNTIME_NAME) --clusterrole=cluster-admin --serviceaccount=$(NAMESPACE):$(RUNTIME_NAME)-host
}

#
# Delete
#

delete()
{
    echo "=> Destroying runtime..."
	kubectl delete clusterrolebinding $(RUNTIME_NAME) --ignore-not-found=true
	kubectl delete serviceaccount $(RUNTIME_NAME)-host -n $(NAMESPACE) --ignore-not-found=true
	func kubernetes delete --name $(RUNTIME_NAME) --image-name runtime/$(RUNTIME_NAME) --registry $(REGISTRY_NAME).azurecr.io/runtime --namespace $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE)
}

#
# Invocation
#

command=$(echo $1 | tr '[:upper:]' '[:lower:]')

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
