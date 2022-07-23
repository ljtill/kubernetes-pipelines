#!/bin/bash

set -e

#
# Environment
#

environment()
{
    echo "=> Environment..."
	if [[ -z "$(RESOURCE_GROUP)" || -z "$(CLUSTER_NAME)" || -z "$(REGISTRY_NAME)" || -z "$(IMAGE_NAME)" ]]; then \
		echo "Missing required environment variables"; \
		exit 1; \
	fi
}

#
# Build
#

build()
{
    echo "=> Building..."

    #
    # Linux
    #

    build-linux()
    {
        echo "==> Building linux..."
    }

    #
    # Windows
    #

    build-windows()
    {
        echo "==> Building windows..."
    }

    #
    # Invocation
    #

    command=$(echo $1 | tr '[:upper:]' '[:lower:]')

    case $command in
        "linux")
            build-linux
            ;;
        "windows")
            build-windows
            ;;
        "all")
            build-linux
            build-windows
        *)
            echo "Missing sub argument"
            ;;
    esac
}

#
# Push
#

push()
{
    echo "=> Pushing..."

    push-linux()
    {
        echo "==> Pushing linux image..."
    }

    push-windows()
    {
        echo "==> Pushing windows image..."
    }

    command=$(echo $1 | tr '[:upper:]' '[:lower:]')

    case $command in
        "linux")
            push-linux
            ;;
        "windows")
            push-windows
            ;;
        "all")
            push-linux
            push-windows
        *)
            echo "Missing sub argument"
            ;;
    esac
}

#
# Invocation
#

command=$(echo $1 | tr '[:upper:]' '[:lower:]')

case $command in
    "environment")
        environment
        ;;
    "build")
        build $2
        ;;
    "push")
        push $2
        ;;
    *)
        echo "Missing argument"
        ;;
esac
