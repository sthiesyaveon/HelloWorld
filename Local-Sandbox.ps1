. (Join-Path $PSScriptRoot "Initialize.ps1")

$containername = "$($settings.name)-dev"

. (Join-Path $ScriptRoot "scripts\Install-NavContainerHelper.ps1") -run Local -navContainerHelperPath $userProfile.navContainerHelperPath
. (Join-Path $ScriptRoot "scripts\Create-Container.ps1")           -run Local -containerName $containerName -imageName $imageversion.containerImage -credential $credential -licensefile $licensefile -alwaysPull:($imageversion.alwaysPull) -hybrid:($settings.hybrid)
. (Join-Path $ScriptRoot "scripts\Import-TestToolkit.ps1")         -run Local -containerName $containerName -credential $credential

UpdateLaunchJson -name "Local Sandbox" -server "http://$containername"
