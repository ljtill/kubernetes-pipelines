##################################################################################################
#           Generates local.settings.json file for runtime using PowerShell                      #
#           Example:                                                                             #
#              ./generateLocalSettingsJson.sh StorageAccountName ServiceBusName KubeConfigPath   #
##################################################################################################

echo "=> Generating deployment files..."

echo "==> Copying kubernetes manifest..."
cp ./local.settings.example.json local.settings.json

echo "==> Creating service bus connection string..."
servicebusconnectionstring="${2}.servicebus.windows.net"

# Assumes path is input with forward slashes
kubeconfig=$(echo $3 | sed 's/\//\\\//g')

echo "==> Replacing settings values..."
sed -i "s/<StorageAccountName>/$1/g" ./local.settings.json
sed -i "s/<ServiceBusConnectionString>/$servicebusconnectionstring/g" ./local.settings.json
sed -i "s/<KubeConfigPath>/$kubeconfig/g" ./local.settings.json

echo "==> Done creating local.settings.json"