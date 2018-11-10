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
    [string] $buildProjectFolder,
    [Parameter(Mandatory=$true)]
    [string] $buildArtifactFolder,
    [Parameter(Mandatory=$true)]
    [string[]] $appFolders,
    [switch]$updateSymbols
)

$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$containerName = "$($settings.name)-$type"
$appFolders | ForEach-Object {
    Compile-AppInNavContainer -containerName $containerName -credential $credential -appProjectFolder (Join-Path $buildProjectFolder $_) -appOutputFolder (Join-Path $buildArtifactFolder $_) -UpdateSymbols:$updateSymbols -AzureDevOps:($run -eq "AzureDevOps") | Out-Null
}
