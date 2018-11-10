Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [pscredential] $credential
)

$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$containerName = "$($settings.name)-$type"
Remove-NavContainer -containerName $containerName
