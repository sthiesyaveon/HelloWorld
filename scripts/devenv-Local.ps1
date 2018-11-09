. (Join-Path $PSScriptRoot "ReadSettings.ps1")

$type = "dev"

$licenseFileParam = @{}
if ($licensefileSecret) {
    $licenseFileParam += @{"licensefile" = $licensefileSecret.SecretValue }
}

. (Join-Path $PSScriptRoot "Install-NavContainerHelper.ps1") -run Local
. (Join-Path $PSScriptRoot "Create-Container.ps1")           -run Local -version $version -type $type -credential $credential @licenseParam
. (Join-Path $PSScriptRoot "Import-TestToolkit.ps1")         -run Local -version $version -type $type -credential $credential

. (Join-Path $PSScriptRoot "UpdateLaunchSettings") -name "Local DevEnv" -server "http://$($settings.name)-$type"
