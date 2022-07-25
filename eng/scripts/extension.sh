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
    echo "=> Publishing extension..."
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
