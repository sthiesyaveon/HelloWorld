. ".\Initialize.ps1"

$containername = "$($settings.name)-dev"

. ".\Install-NavContainerHelper.ps1" -run Local -navContainerHelperPath $userProfile.navContainerHelperPath
. ".\Create-Container.ps1"           -run Local -containerName $containerName -imageName $imageversion.containerImage -credential $credential -licensefile $licensefile -alwaysPull:($imageversion.alwaysPull)

UpdateLaunchJson -name "Local Sandbox" -server "http://$containername"
