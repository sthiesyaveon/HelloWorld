Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $run = "AzureDevOps",

    [Parameter(Mandatory=$true)]
    [string] $containerName,

    [Parameter(Mandatory=$true)]
    [string] $imageName,

    [Parameter(Mandatory=$true)]
    [pscredential] $credential,

    [Parameter(Mandatory=$false)]
    [securestring] $licenseFile = $null,

    [switch] $alwaysPull,

    [switch] $hybrid
)

Write-Host "Create $containerName from $imageName"

$parameters = @{
    "Accept_Eula" = $true
    "Accept_Outdated" = $true
}

if ($hybrid) {
    $parameters += @{
        "includeCSide" = $true
        "doNotExportObjectsToText" = $true
        "enableSymbolLoading" = $true
    }
}

if ($licenseFile) {
    $unsecureLicenseFile = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($licenseFile)))
    $parameters += @{
        "licenseFile" = $unsecureLicenseFile
    }
}

if ($run -eq "Local") {
    $workspaceFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
    $additionalParameters = @("--volume ""${workspaceFolder}:C:\Source""") 
}
elseif ($run -eq "AzureDevOps") {
    $segments = "$PSScriptRoot".Split('\')
    $rootFolder = "$($segments[0])\$($segments[1])"
    $additionalParameters = @("--volume ""$($rootFolder):C:\Agent""")
    $parameters += @{ 
        "shortcuts" = "None"
    }
}
else {
    $workspaceFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
    $additionalParameters = @("--volume ""C:\DEMO:C:\DEMO""")
    $parameters += @{ 
        "shortcuts" = "None"
        "useTraefik" = $true
        "myscripts" = @(@{ "AdditionalOutput.ps1" = "copy-item -Path 'C:\Run\*.vsix' -Destination 'C:\ProgramData\navcontainerhelper\Extensions\$containerName' -force" })
    }

}

New-NavContainer @Parameters `
                 -doNotCheckHealth `
                 -updateHosts `
                 -useBestContainerOS `
                 -containerName $containerName `
                 -imageName $imageName `
                 -alwaysPull:$alwaysPull `
                 -auth "UserPassword" `
                 -Credential $credential `
                 -additionalParameters $additionalParameters
