. (Join-Path $PSScriptRoot "Read-Settings.ps1")

$bcContainerHelperVersion = "latest"
if ($settings.PSObject.Properties.Name -eq 'bcContainerHelperVersion' -and $settings.bcContainerHelperVersion) {
    $bcContainerHelperVersion = $settings.bcContainerHelperVersion
}
Write-Host "Use bcContainerHelper Version: $bcContainerHelperVersion"
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion

Remove-BcContainer -containerName $containerName
Flush-ContainerHelperCache -KeepDays 7

Remove-Module BcContainerHelper
$path = Join-Path $ENV:Temp $containerName
if (Test-Path $path) {
    Remove-Item $path -Recurse -Force
}
