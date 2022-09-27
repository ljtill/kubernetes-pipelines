###########################################################################################################
#           Generates local.settings.json file for runtime using PowerShell                               #
#           Example:                                                                                      #
#              If using Managed Identity:                                                                 #
#                    ./generateLocalSettingsJson.sh MI StorageAccountName ServiceBusName KubeConfigPath   #
#              If using Connection String:                                                                #
#                   ./generateLocalSettingsJson.sh CS KubeConfigPath                                      #
###########################################################################################################

#!/bin/bash

set -e

echo "=> Generating deployment files..."

echo "==> Copying kubernetes manifest..."
usemi=$1

if [[ $usemi == "MI" ]]; then
    cp ./local.settings.example.MI.json local.settings.json

    echo "==> Creating service bus connection string..."
    servicebusconnectionstring="${3}.servicebus.windows.net"

    echo "==> Replacing settings values..."
    sed -i "s/<StorageAccountName>/$2/g" ./local.settings.json
    sed -i "s/<ServiceBusConnectionString>/$servicebusconnectionstring/g" ./local.settings.json

else
    cp ./local.settings.example.json local.settings.json
fi

# Assumes path is input with forward slashes
kubeconfig=$(echo $4 | sed 's/\//\\\//g')
sed -i "s/<KubeConfigPath>/$kubeconfig/g" ./local.settings.json

echo "==> Done creating local.settings.json"