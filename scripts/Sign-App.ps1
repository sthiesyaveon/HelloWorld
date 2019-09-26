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

    [Parameter(Mandatory=$true)]
    [securestring] $pfxFile,

    [Parameter(Mandatory=$true)]
    [securestring] $pfxPassword
)

$unsecurepfxFile = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxFile)))
$appFolders | ForEach-Object {
    Get-ChildItem -Path (Join-Path $buildArtifactFolder $_) | ForEach-Object {
        Sign-NavContainerApp -containerName $containerName -appFile $_.FullName -pfxFile $unsecurePfxFile -pfxPassword $pfxPassword
    }
}