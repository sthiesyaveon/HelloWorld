Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    [String] $licenseFile = ""
)

$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$imageversion  = $settings.versions | Where-Object { $_.version -eq $version }
$containerName = "$($settings.name)-$type"
Write-Host "Create $containerName from $($imageversion.containerImage)"

$parameters = @{
                "accept_eula" = $true;
                "accept_outdated" = $true
               }

if ($run -eq "Local") {
    $workspaceFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
    $additionalParameters = @("--volume ""${workspaceFolder}:C:\Source""") 
    $myscripts = @()
    $shortcuts = "Desktop"
} else {
    $segments = "$PSScriptRoot".Split('\')
    $rootFolder = "$($segments[0])\$($segments[1])"
    $additionalParameters = @("--volume ""$($rootFolder):C:\Agent""")
    $myscripts = @(@{'MainLoop.ps1' = 'while ($true) { start-sleep -seconds 10 }'})
    $shortcuts = "None"
}

New-NavContainer @parameters `
                 -containerName $containerName `
                 -imageName $imageversion.containerImage `
                 -auth NAVUserPassword `
                 -Credential $credential `
                 -alwaysPull:$imageversion.alwaysPull `
                 -updateHosts `
                 -includeCSide `
                 -doNotExportObjectsToText `
                 -enableSymbolLoading `
                 -useBestContainerOS `
                 -shortcuts $shortcuts `
                 -licenseFile "$licenseFile" `
                 -additionalParameters $additionalParameters `
                 -myScripts $myscripts
