Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $run = "AzureDevOps",

    [Parameter(Mandatory=$true)]
    [string] $containerName,
    
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    
    [switch] $includeTestCodeUnits
)

Import-TestToolkitToNavContainer -containerName $containerName -sqlCredential $credential -includeTestLibrariesOnly:(!$includeTestCodeUnits)

