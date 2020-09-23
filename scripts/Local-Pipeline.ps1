﻿Param(
    [Parameter(Mandatory=$false)]
    [string] $version = "Current"
)

$vaultName = "BuildVariables"
$licenseFileSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "licenseFile"
if ($licenseFileSecret) { $licenseFile = $licenseFileSecret.SecretValueText } else { $licenseFile = "" }
$insiderSasTokenSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "insiderSasToken"
if ($insiderSasTokenSecret) { $insiderSasToken = $insiderSasTokenSecret.SecretValueText } else { $insiderSasToken = "" }
$passwordSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "password"
if ($passwordSecret) { $credential = New-Object pscredential 'admin', $passwordSecret.SecretValue } else { $credential = $null }

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -local -version $version

Run-AlPipeline `
    -pipelineName $pipelineName `
    -containerName $containerName `
    -artifact $artifact.replace('{INSIDERSASTOKEN}',$insiderSasToken) `
    -memoryLimit $memoryLimit `
    -credential $credential `
    -baseFolder $baseFolder `
    -licenseFile $licenseFile `
    -installApps $installApps `
    -appFolders $appFolders `
    -testFolders $testFolders `
    -installTestFramework:$installTestFramework `
    -installTestLibraries:$installTestLibraries `
    -installPerformanceToolkit:$installPerformanceToolkit `
    -enableCodeCop:$enableCodeCop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -enableUICop:$enableUICop `
    -useDevEndpoint -updateLaunchJson "Local Sandbox" -keepContainer