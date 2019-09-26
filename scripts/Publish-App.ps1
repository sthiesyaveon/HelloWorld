Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $run = "AzureDevOps",

    [Parameter(Mandatory=$true)]
    [string] $containerName,

    [Parameter(Mandatory=$true)]
    [pscredential] $credential,

    [Parameter(Mandatory=$true)]
    [string] $buildArtifactFolder,

    [Parameter(Mandatory=$true)]
    [string[]] $appFolders,

    [switch] $skipVerification
)

$appFolders = Sort-AppFoldersByDependencies -appFolders $appFolders -baseFolder $buildProjectFolder -WarningAction SilentlyContinue
$appFolders | ForEach-Object {
    Get-ChildItem -Path (Join-Path $buildArtifactFolder $_) | ForEach-Object {
        Publish-NavContainerApp -containerName $containerName -appFile $_.FullName -skipVerification:$skipVerification -sync -install
    }
}
