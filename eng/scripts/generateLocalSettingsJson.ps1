###########################################################################################################################################
#           Generates local.settings.json file for runtime using PowerShell                                                               #
#           Example:                                                                                                                      #
#              ./generateLocalSettingsJson.ps1 -StorageAccountName exampleSA -ServiceBusName exampleSB -KubeConfigPath C:/example/path    #
###########################################################################################################################################

param(
    [Parameter()]
    [String]$ServiceBusName,
    [String]$StorageAccountName,
    [String]$KubeConfigPath
)

Copy-Item ./local.settings.example.json local.settings.json

Write-Output "==> Replacing local settings values..."

$ServiceBusConnectionString = "$($ServiceBusName).servicebus.windows.net" 


(Get-Content local.settings.json) -replace "<StorageAccountName>", "$($StorageAccountName)" | Set-Content local.settings.json
(Get-Content local.settings.json) -replace "<ServiceBusConnectionString>", "$ServiceBusConnectionString" | Set-Content local.settings.json
(Get-Content local.settings.json) -replace "<KubeConfigPath>", "$KubeConfigPath" | Set-Content local.settings.json

Write-Output "==> Done creating local.settings.json"
