## ------------------------------------------------------------------------
## Input Parameters
## 
## ------------------------------------------------------------------------

param(
  [Parameter()]
  [String]$ExtensionAction
)

#
# Build
#

function Build
{
    Write-Output "=> Building extension..."
    Set-Location ../../src/Pipelines.Extension
    tfx extension create --manifest-globs vss-extension.json --output-path ./bin/
}

#
# Publish
#

Function publish
{
    # NOTE: Implement the publish function

    Write-Output "=> Publishing extension..."
    tfx extension publish
}

#
# Invocation
#

switch ($ExtensionAction) {
    "Build" { Build }
    "Publish" { Publish }
     Default { Write-Output "Missing argument"}
}