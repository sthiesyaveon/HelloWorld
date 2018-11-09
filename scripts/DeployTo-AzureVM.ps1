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
    [string] $profile = "freddyk",
    [string] $AppUrl
)

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
$imageversion = $settings.versions | Where-Object { $_.version -eq $version }
$azureprofile = $settings.profiles | Where-Object { $_.profile -eq $profile }
if (!($azureprofile)) {
    throw "No profile for $profile in settings.json"
}

Import-Module -Name "AzureRM.Resources"
Import-Module -Name "AzureRM.Compute"

try {
    if ((Get-AzureRmContext).Subscription.Id -ne $azureprofile.subscriptionId) {
        Set-AzureRmContext -SubscriptionID $azureprofile.subscriptionId
    }
} catch {
    Add-AzureRmAccount -Environment $azureprofile.environment
    Set-AzureRmContext -SubscriptionID $azureprofile.subscriptionId
}

if (Get-AzureRmResourceGroup -name $azureprofile.resourceGroup -ErrorAction Ignore) {
    Write-Host "Removing $($azureprofile.resourceGroup)"
    Remove-AzureRmResourceGroup -Name $azureprofile.resourceGroup -force -Erroraction Ignore
}

# ARM template
if ($azureprofile.psObject.properties.match('templateUri')) {
    $templateUri = $azureprofile.templateUri
} else {
    $templateUri = "https://raw.githubusercontent.com/microsoft/nav-arm-templates/master/getbcext.json"
}

# ARM Parameters, can't use @{ } due to securestring password
$Parameters = (New-Object -TypeName Hashtable)
$Parameters.Add("bcAdminUsername", $credential.Username)
$Parameters.Add("bcDockerImage", $imageversion.containerImage)
$Parameters.Add("adminPassword", $credential.Password)
$Parameters.Add("IncludeAppUris", "$AppUrl")
$azureprofile.properties | Get-Member -MemberType NoteProperty | ForEach-Object { 
    $Name = $_.Name
    $Parameters.Add("$Name", $azureprofile.Properties."$Name")
}

Write-Host "Deploying $($azureprofile.resourceGroup)"
# GO!
$resourceGroup = New-AzureRmResourceGroup -Name $azureprofile.resourceGroup -Location $azureprofile.location -Force -ErrorAction Ignore
$err = $resourceGroup | Test-AzureRmResourceGroupDeployment -TemplateUri $templateUri -TemplateParameterObject $Parameters
if ($err) {
    throw $err
}
$resourceGroup | New-AzureRmResourceGroupDeployment -TemplateUri $templateUri -TemplateParameterObject $Parameters -Name $azureprofile.resourceGroup
