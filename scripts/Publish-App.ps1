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
    [string] $appFolders,

    [switch] $skipVerification
)

Sort-AppFoldersByDependencies -appFolders $appFolders.Split(',') -baseFolder $buildProjectFolder -WarningAction SilentlyContinue | ForEach-Object {
    Write-Host "Publishing $_"
    Get-ChildItem -Path (Join-Path $buildArtifactFolder $_) | ForEach-Object {
        Publish-NavContainerApp -containerName $containerName -appFile $_.FullName -skipVerification:$skipVerification -sync -install
    }
}
