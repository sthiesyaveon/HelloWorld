. (Join-Path $PSScriptRoot "Initialize.ps1")

$type = "dev"

. (Join-Path $PSScriptRoot "scripts\DeployTo-AzureVM.ps1") -run Local -version $version -type $type -credential $credential -profile $profile

UpdateLaunchJson -name "AzureVM DevEnv" -server "https://$($azureprofile.Properties.vmName).$($azureprofile.domain)"
