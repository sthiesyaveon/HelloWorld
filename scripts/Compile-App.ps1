Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $run = "AzureDevOps",

    [Parameter(Mandatory=$true)]
    [string] $containerName,
    
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    
    [Parameter(Mandatory=$true)]
    [string] $buildProjectFolder,

    [Parameter(Mandatory=$true)]
    [string] $buildSymbolsFolder,

    [Parameter(Mandatory=$true)]
    [string] $buildArtifactFolder,
    
    [Parameter(Mandatory=$true)]
    [string[]] $appFolders,
    
    [switch] $updateSymbols
)

$appFolders = Sort-AppFoldersByDependencies -appFolders $appFolders -baseFolder $buildProjectFolder -WarningAction SilentlyContinue
$appFolders | ForEach-Object {
    $appFile = Compile-AppInNavContainer -containerName $containerName -credential $credential -appProjectFolder (Join-Path $buildProjectFolder $_) -appSymbolsFolder $buildSymbolsFolder -appOutputFolder (Join-Path $buildArtifactFolder $_) -UpdateSymbols:$updateSymbols -AzureDevOps:($run -eq "AzureDevOps")
    if ($appFile -and (Test-Path $appFile)) {
        Copy-Item -Path $appFile -Destination $buildSymbolsFolder -Force
    }
}
