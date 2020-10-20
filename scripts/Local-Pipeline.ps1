﻿Param(
    [Parameter(Mandatory=$false)]
    [string] $version = "ci",
    [Parameter(Mandatory=$false)]
    [int] $appBuild = ([int32]::MaxValue),
    [Parameter(Mandatory=$false)]
    [int] $appRevision = 0
)

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -version $version

$bcContainerHelperVersion = "latest"
if ($settings.PSObject.Properties.Name -eq 'bcContainerHelperVersion' -and $settings.bcContainerHelperVersion) {
    $bcContainerHelperVersion = $settings.bcContainerHelperVersion
}
Write-Host "Use bcContainerHelper Version: $bcContainerHelperVersion"
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion

if ($genericImageName) {
    $bcContainerHelperConfig.genericImageName = $genericImageName
}

$vaultName = "BuildVariables"
$licenseFileSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "licenseFile"
if ($licenseFileSecret) { $licenseFile = $licenseFileSecret.SecretValueText } else { $licenseFile = "" }
$insiderSasTokenSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "insiderSasToken"
if ($insiderSasTokenSecret) { $insiderSasToken = $insiderSasTokenSecret.SecretValueText } else { $insiderSasToken = "" }
$passwordSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name "password"
if ($passwordSecret) { $credential = New-Object pscredential 'admin', $passwordSecret.SecretValue } else { $credential = $null }

$allTestResults = "testresults*.xml"
$testResultsFile = Join-Path $baseFolder "TestResults.xml"
$testResultsFiles = Join-Path $baseFolder $allTestResults
if (Test-Path $testResultsFiles) {
    Remove-Item $testResultsFiles -Force
}

Run-AlPipeline `
    -pipelineName $pipelineName `
    -containerName $containerName `
    -imageName $imageName `
    -artifact $artifact.replace('{INSIDERSASTOKEN}',$insiderSasToken) `
    -memoryLimit $memoryLimit `
    -baseFolder $baseFolder `
    -licenseFile $licenseFile `
    -installApps $installApps `
    -previousApps $previousApps `
    -appFolders $appFolders `
    -testFolders $testFolders `
    -doNotRunTests:$doNotRunTests `
    -testResultsFile $testResultsFile `
    -testResultsFormat 'JUnit' `
    -installTestFramework:$installTestFramework `
    -installTestLibraries:$installTestLibraries `
    -installPerformanceToolkit:$installPerformanceToolkit `
    -enableCodeCop:$enableCodeCop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -enableUICop:$enableUICop `
    -AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
    -AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
    -additionalCountries $additionalCountries `
    -credential $credential `
    -appBuild $appBuild -appRevision $appRevision
