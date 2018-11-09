Param(
    [string] $version = "",
    [string] $profile = ""
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

$settings = (Get-Content (Join-Path $ScriptRoot "settings.json") | ConvertFrom-Json)

if (!($version)) {
    $version = Read-Host ("Select Version (" +(($settings.versions | ForEach-Object { $_.version }) -join ", ") + ") ")
    if (!($version)) {
        $version = $settings.versions[0].version
    }
}

if (!($profile)) {
    $profile = Read-Host ("Select profile (" +(($settings.profiles | ForEach-Object { $_.profile }) -join ", ") + ") ")
    if (!($profile)) {
        $profile = $settings.profiles[0].profile
    }
}

$imageversion = $settings.versions | Where-Object { $_.version -eq $version }
if (!($imageversion)) {
    throw "No version for $version in settings.json"
}

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

$licenseFileSecret = (Get-AzureKeyVaultSecret -VaultName $azureprofile.keyVault -Name "LicenseFile").SecretValue
$pfxFileSecret = Get-AzureKeyVaultSecret -VaultName $azureprofile.keyVault -Name "CodeSignPfxFile"
$pfxPasswordSecret = Get-AzureKeyVaultSecret -VaultName $azureprofile.keyVault -Name "CodeSignPfxPassword"
$usernameSecret = Get-AzureKeyVaultSecret -VaultName $azureprofile.keyVault -Name "Username"
$passwordSecret = Get-AzureKeyVaultSecret -VaultName $azureprofile.keyVault -Name "Password"

if (($usernameSecret) -and ($passwordSecret)) {
    $credential = New-Object System.Management.Automation.PSCredential($usernameSecret.SecretValueText, $passwordSecret.SecretValue)
} else {
    throw "Username and Password secrets should be set in the Azure KeyVault"
}

