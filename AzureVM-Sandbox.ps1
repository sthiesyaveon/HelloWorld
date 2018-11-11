. (Join-Path $PSScriptRoot "Initialize.ps1")

$type = "dev"

$deployment = . (Join-Path $PSScriptRoot "scripts\DeployTo-AzureVM.ps1") -run Local -version $version -type $type -credential $credential -profile $profile

if ($deployment.PSObject.Properties.Name -eq "Outputs") {
    if ($deployment.Outputs["landingPage"]) {
        $deployment
        Start-Process $deployment.Outputs["landingPage"].Value
        UpdateLaunchJson -name "AzureVM Sandbox" -server "https://$($azureprofile.Properties.vmName).$($azureprofile.domain)"
    } else {
        Write-Host "Deployment doesn't contain any Output"
    }
} else {
    Write-Host "Deployment failed"
}
