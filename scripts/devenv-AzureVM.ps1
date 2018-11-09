. (Join-Path $PSScriptRoot "ReadSettings.ps1")

$type = "dev"

. (Join-Path $PSScriptRoot "DeployTo-AzureVM.ps1") -run Local -version $version -type $type -credential $credential -profile $azureprofile

. (Join-Path $PSScriptRoot "UpdateLaunchSettings") -name "AzureVM DevEnv" -server "https://$($azureprofile.Properties.vmName).$($azureprofile.domain)"
