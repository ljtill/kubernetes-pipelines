## ------------------------------------------------------------------------
## Input Parameters
## 
## ------------------------------------------------------------------------

param(
  [Parameter()]
  [String]$Action,
  [String]$OS
) 

#
# Environment
#

Function Environment
{
    Write-Output "=> Checking environment variables..."

    if ("$REGISTRY_NAME")
    {
        Write-Output "Missing required environment variable (REGISTRY_NAME)"
        exit 1
    }

    Write-Output "==> Reading variable - REGISTRY_NAME :: $REGISTRY_NAME"

    if("$IMAGE_NAME")
    {
        Write-Output "Missing required environment variable (IMAGE_NAME)"
        exit 1
    }

    Write-Output "==> Reading variable - IMAGE_NAME :: $IMAGE_NAME"
}

#
# Build
#

Function Build()
{
    Write-Output "=> Building..."

    #
    # Linux
    #

    Function BuildLinux
    {
        Write-Output "==> Building linux..."
    }

    #
    # Windows
    #

    Function BuildWindows
    {
        Write-Output "==> Building windows..."
    }

    #
    # Invocation
    #

    switch($OS){
        "windows" { BuildWindows }
        "linux"   { BuildLinux }
    }
}

#
# Push
#

Function Push
{
    Write-Output "=> Pushing..."

    if($OS -eq "linux")
    {
        Write-Output "==> Pushing linux image..."
    }

    if($OS -eq "windows")
    {
        Write-Output "==> Pushing windows image..."
    }
}

# TODO: Need to find a way to call it like "make deploy"
switch ($Action) {
    "Environment" { Write-Output "Environment Variables Set"; Environment }
    "Build" { Write-Output "Environment Variables Set"; Environment; Build }
    "Push" { Write-Output "Environment Variables Set"; Environment; Push}
     Default { Write-Output "Missing argument"}
}


