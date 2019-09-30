Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory=$false)]
    [string] $containerName = $ENV:CONTAINERNAME
)

Remove-NavContainer -containerName $containerName
