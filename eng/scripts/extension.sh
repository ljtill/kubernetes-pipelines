#!/bin/bash

set -e

#
# Build
#

build()
{
    echo "=> Building extension..."
    tfx extension create --manifest-globs vss-extension.json --output-path ./bin/
}

#
# Publish
#

publish()
{
    # NOTE: Implement the publish function

    echo "=> Publishing extension..."
    tfx extension publish
}

#
# Invocation
#

command=$(echo "$1" | tr "[:upper:]" "[:lower:]")

case $command in
    "build")
        build
        ;;
    "publish")
        publish
        ;;
    *)
        echo "Missing argument"
        ;;
esac
