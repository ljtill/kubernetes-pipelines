param(
    [Parameter()]
    [String]$Action
)

#
# Environment
#

function Environment {
    Write-Output "=> Loading configuration variables..."

    # TODO: Handle multiple cluster configurations
    # TODO: Handle multiple applications

    $configData = $(Get-Content ../../eng/configs/platform.local.json) | ConvertFrom-Json
    $serviceName = $configData.services.name
    $clusterName = $configData.clusters[0].name
    $appName = "Pipelines2"
    $appId = $(az ad app list --display-name $appName -o json | ConvertFrom-Json)[0].appId

    $props = @{
        ServiceName = $serviceName
        ConfigPath  = $configPath
        ConfigData  = $configData
        ClusterName = $clusterName
        AppId       = $appId
        AppName     = $appName
    }

    $envVariables = new-object psobject -Property $props

    return $envVariables
}

#
# Login
#

function Login($environmentVariables) {
    Write-Output "=> Authenticating session..."
    az acr login --name $environmentVariables.ServiceName
}

#
# Build
#

function Build($environmentVariables) {
    Set-Location ../../src/Pipelines.Runtime

    Write-Output "\n=> Building runtime..."
    dotnet build Pipelines.Runtime.csproj -c Release

    Write-Output "\n=> Building image..."
    docker build -t "$($environmentVariables.ServiceName)".azurecr.io/runtimes/functions:latest .
}

#
# Generate
#

function Generate($environmentVariables) {
    Set-Location ../../src/Pipelines.Runtime
    Write-Output "=> Generating deployment files..."

    Write-Output "==> Removing existing kubernetes manifest..."
    Remove-Item ./functions.local.yaml

    Write-Output "==> Copying kubernetes manifest..."
    Copy-Item ./functions.yaml functions.local.yaml

    Write-Output "==> Replacing manifest value..."

    (Get-Content functions.local.yaml) -replace "<StorageAccountName>", "$($environmentVariables.ClusterName)" | Set-Content functions.local.yaml
    (Get-Content functions.local.yaml) -replace "<ServiceBusName>", "$($environmentVariables.ClusterName)" | Set-Content functions.local.yaml
    (Get-Content functions.local.yaml) -replace "<RegistryName>", "$($environmentVariables.ServiceName)" | Set-Content functions.local.yaml
    (Get-Content functions.local.yaml) -replace "<ClientId>", "$($environmentVariables.AppId)" | Set-Content functions.local.yaml
}

#
# Push
#

function Push($environmentVariables) {
    Set-Location ../../src/Pipelines.Runtime

    Write-Output "=> Pushing image..."
    docker push "$($environmentVariables.ServiceName)".azurecr.io/runtimes/functions:latest
}

#
# Clean
#

Function Clean {
    Set-Location ../../src/Pipelines.Runtime

    Write-Output "=> Cleaning..."
    dotnet build Pipelines.Runtime.csproj
}

#
# Run
#

function Run {
    Set-Location ../../src/Pipelines.Runtime

    Write-Output "=> Starting functions host..."
    func host start
}

#
# Deploy
#

function Deploy {
    Set-Location ../../src/Pipelines.Runtime

    Write-Output "=> Deploying runtime..."

    $checkKubeNS = $(kubectl get namespace -o json | ConvertFrom-Json).items | Where-Object { $_.metadata.name -eq "functions-system" }

    if (!$checkKubeNS) {
        Write-Output "==> Creating kubernetes namespace..."
        kubectl create namespace functions-system
    }
    else {
        Write-Output "==> Skipping kubernetes namespace creation..."
    }

    $checkKubeDeployment = $(kubectl get deployment -n functions-system -o json | ConvertFrom-Json).items | Where-Object { $_.metadata.name -eq "functions" }

    if (!$checkKubeDeployment) {
        Write-Output "==> Creating kubernetes deployment..."
        kubectl apply -f ./functions.yaml
        # NOTE: Following command is included as an archive for future reference
        #func kubernetes deploy --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY_NAME.azurecr.io/runtime" --min-replicas 1 --namespace "$namespace"
    }
    else {
        Write-Output "==> Skipping kubernetes deployment creation..."
    }
}

#
# Delete
#

function Delete {
    Write-Output "=> Destroying runtime..."

    $checkKubeDeployment = $(kubectl get deployment -n functions-system -o json  | ConvertFrom-Json).items | Where-Object { $_.metadata.name -eq "functions" }

    if ($checkKubeDeployment) {
        Write-Output "==> Deleting kubernetes deployment..."
        kubectl delete -f ./functions.yaml
        # NOTE: Following command is included as an archive for future reference
        #func kubernetes delete --name "$runtime" --image-name "runtime/$runtime" --registry "$REGISTRY_NAME.azurecr.io/runtime" --namespace "$namespace"
    }
    else {
        Write-Output "==> Skipping kubernetes deployment deletion..."
    }

    $checkKubeNS = $(kubectl get namespace -o json  | ConvertFrom-Json).items | Where-Object { $_.metadata.name -eq "functions-system" }
    if ($checkKubeNS) {
        Write-Output "==> Deleting kubernetes namespace..."
        kubectl delete namespace functions-system
    }
    else {
        Write-Output "==> Skipping kubernetes namespace deletion..."
    }
}

#
# Invocation
#

switch ($Action) {
    "Login" { Write-Output "Environment Variables Set"; $envVariables = Environment; Login($envVariables) }
    "Build" { Write-Output "Environment Variables Set"; $envVariables = Environment; Build($envVariables) }
    "Generate" { Write-Output "Environment Variables Set"; $envVariables = Environment; Generate($envVariables) }
    "Push" { Write-Output "Environment Variables Set"; $envVariables = Environment; Push($envVariables) }
    "Clean" { Write-Output "Environment Variables Set"; $envVariables = Environment; Clean }
    "Run" { Write-Output "Environment Variables Set"; $envVariables = Environment; Run }
    "Deploy" { Write-Output "Environment Variables Set"; $envVariables = Environment; Deploy }
    "Delete" { Write-Output "Environment Variables Set"; $envVariables = Environment; Delete }
    Default { Write-Output "Missing argument" }
}
