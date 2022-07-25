#!/bin/bash

set -e

#
# Variables
#

#
# Environment
#

environment()
{
    echo "=> Checking environment variables..."

    if [[ -z "$RESOURCE_GROUP" ]]; then
        echo "Missing required environment variable (RESOURCE_GROUP)"
        exit 1
    fi
    echo "==> Reading  variable - RESOURCE_GROUP :: $RESOURCE_GROUP"

    if [[ -z "$CLUSTER_NAME" ]]; then
        echo "Missing required environment variable (CLUSTER_NAME)"
        exit 1
    fi
    echo "==> Reading variable - CLUSTER_NAME :: $CLUSTER_NAME"

    if [[ -z "$REGISTRY_NAME" ]]; then
        echo "Missing required environment variable (REGISTRY_NAME)"
        exit 1
    fi
    echo "==> Reading variable - CLUSTER_NAME :: $REGISTRY_NAME"


    if [[ -z "$IMAGE_NAME" ]]; then
        echo "Missing required environment variable (CLUSTER_NAME)"
        exit 1
    fi
    echo "==> Reading variable - CLUSTER_NAME :: $IMAGE_NAME"
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

    command=$(echo "$1" | tr "[:upper:]" "[:lower:]")

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
            ;;
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

    #
    # Invocation
    #

    command=$(echo "$1" | tr "[:upper:]" "[:lower:]")

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
            ;;
        *)
            echo "Missing sub argument"
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
    "build")
        build "$2"
        ;;
    "push")
        push "$2"
        ;;
    *)
        echo "Missing argument"
        ;;
esac
