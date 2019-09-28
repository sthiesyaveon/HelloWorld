. ".\Initialize.ps1"

$containerName = "$($settings.name)-bld"

$run = "Local"
$navContainerHelperPath = $userProfile.navContainerHelperPath

$buildArtifactFolder = Join-Path $ProjectRoot ".output"
if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

$alPackagesFolder = Join-Path $ProjectRoot ".alPackages"
if (Test-Path $alPackagesFolder) { Remove-Item $alPackagesFolder -Force -Recurse }
New-Item -Path $alPackagesFolder -ItemType Directory -Force | Out-Null

. ".\Install-NavContainerHelper.ps1" -run $run -navContainerHelperPath $navContainerHelperPath
. ".\Create-Container.ps1"           -run $run -ContainerName $containerName -imageName $imageVersion.containerImage -alwaysPull:($imageversion.alwaysPull) -Credential $credential -licenseFile $licenseFile
. ".\Compile-App.ps1"                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ProjectRoot -buildSymbolsFolder $alPackagesFolder -appFolders $settings.appFolders
. ".\Compile-App.ps1"                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ProjectRoot -buildSymbolsFolder $alPackagesFolder -appFolders $settings.testFolders
if ($CodeSignPfxFile) {
    . ".\scripts\Sign-App.ps1"       -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders $settings.appFolders -pfxFile $CodeSignPfxFile -pfxPassword $CodeSignPfxPassword
}
. ".\Publish-App.ps1"                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders $settings.appFolders -skipVerification:(!($CodeSignPfxFile))
. ".\Publish-App.ps1"                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders $settings.testFolders -skipVerification
. ".\Run-Tests.ps1"                  -run $run -ContainerName $containerName -Credential $credential -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml")
. ".\Remove-Container.ps1"           -run $run -ContainerName $containerName -Credential $credential