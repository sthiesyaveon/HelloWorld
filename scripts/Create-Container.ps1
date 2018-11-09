Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    [SecureString] $licenseFile = $null
)

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
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
    $additionalParameters = @("--volume ""C:\Agent:C:\Agent""", "--env httpSite=N", "--env WebClient=N")
    $myscripts = @(@{'MainLoop.ps1' = 'while ($true) { start-sleep -seconds 10 }'})
    $shortcuts = "None"
}

$licenseFileParam = ""
if ($licenseFile) {
    $licenseFileParam = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($licenseFile))
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
                 -licenseFile $licenseFileParam `
                 -additionalParameters $additionalParameters `
                 -myScripts $myscripts
