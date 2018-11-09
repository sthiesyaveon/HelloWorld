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
    [switch] $skipVerification
)

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
$containerName = "$($settings.name)-$type"
$appFolders | ForEach-Object {
    Get-ChildItem -Path (Join-Path $buildArtifactFolder $_) | ForEach-Object {
        Publish-NavContainerApp -containerName $containerName -appFile $_.FullName -skipVerification:$skipVerification -sync -install
    }
}
