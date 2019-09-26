Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [string] $run = "AzureDevOps",

    [Parameter(Mandatory=$true)]
    [string] $containerName,

    [Parameter(Mandatory=$true)]
    [pscredential] $credential
)

Remove-NavContainer -containerName $containerName
