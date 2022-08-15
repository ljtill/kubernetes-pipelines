param(
    [Parameter()]
    [String]$Action,
    [String]$OS
)

#
# Environment
#

function Environment {
    Write-Output "=> Checking environment variables..."

    if ("$REGISTRY_NAME") {
        Write-Output "Missing required environment variable (REGISTRY_NAME)"
        exit 1
    }

    Write-Output "==> Reading variable - REGISTRY_NAME :: $REGISTRY_NAME"

    if ("$IMAGE_NAME") {
        Write-Output "Missing required environment variable (IMAGE_NAME)"
        exit 1
    }

    Write-Output "==> Reading variable - IMAGE_NAME :: $IMAGE_NAME"
}

#
# Build
#

function Build() {
    Write-Output "=> Building..."

    #
    # Linux
    #

    function BuildLinux {
        Write-Output "==> Building linux..."
    }

    #
    # Windows
    #

    function BuildWindows {
        Write-Output "==> Building windows..."
    }

    #
    # Invocation
    #

    switch ($OS) {
        "windows" { BuildWindows }
        "linux" { BuildLinux }
    }
}

#
# Push
#

function Push {
    Write-Output "=> Pushing..."

    if ($OS -eq "linux") {
        Write-Output "==> Pushing linux image..."
    }

    if ($OS -eq "windows") {
        Write-Output "==> Pushing windows image..."
    }
}

#
# Invocation
#

switch ($Action) {
    "Environment" { Write-Output "Environment Variables Set"; Environment }
    "Build" { Write-Output "Environment Variables Set"; Environment; Build }
    "Push" { Write-Output "Environment Variables Set"; Environment; Push }
    Default { Write-Output "Missing argument" }
}


