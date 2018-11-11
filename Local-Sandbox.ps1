. (Join-Path $PSScriptRoot "Initialize.ps1")

$type = "dev"

$licenseFileParam = @{}
if ($licensefileSecret) {
    $licenseFileParam += @{"licensefile" = $licensefileSecret.SecretValue }
}

. (Join-Path $PSScriptRoot "scripts\Install-NavContainerHelper.ps1") -run Local
. (Join-Path $PSScriptRoot "scripts\Create-Container.ps1")           -run Local -version $version -type $type -credential $credential @licenseParam
. (Join-Path $PSScriptRoot "scripts\Import-TestToolkit.ps1")         -run Local -version $version -type $type -credential $credential

UpdateLaunchJson -name "Local Sandbox" -server "http://$($settings.name)-$type"
