Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    [Parameter(Mandatory=$true)]
    [string] $buildArtifactFolder,
    [Parameter(Mandatory=$true)]
    [string[]] $appFolders,
    [Parameter(Mandatory=$true)]
    [securestring] $pfxFile,
    [Parameter(Mandatory=$true)]
    [securestring] $pfxPassword
)

$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$containerName = "$($settings.name)-$type"

$unsecurepfxFile = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxFile)))
$appFolders | ForEach-Object {
    Get-ChildItem -Path (Join-Path $buildArtifactFolder $_) | ForEach-Object {
        Sign-NavContainerApp -containerName $containerName -appFile $_.FullName -pfxFile $unsecurePfxFile -pfxPassword $pfxPassword
    }
}