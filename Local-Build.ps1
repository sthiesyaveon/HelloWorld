. (Join-Path $PSScriptRoot "Initialize.ps1")

$containerName = "$($settings.name)-bld"

$run = "Local"
$navContainerHelperPath = $userProfile.navContainerHelperPath

$buildArtifactFolder = Join-Path $ScriptRoot ".output"
if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

$alPackagesFolder = Join-Path $ScriptRoot ".alPackages"
if (Test-Path $alPackagesFolder) { Remove-Item $alPackagesFolder -Force -Recurse }
New-Item -Path $alPackagesFolder -ItemType Directory -Force | Out-Null

. (Join-Path $ScriptRoot "scripts\Install-NavContainerHelper.ps1") -run $run -navContainerHelperPath $navContainerHelperPath
. (Join-Path $ScriptRoot "scripts\Create-Container.ps1")           -run $run -ContainerName $containerName -imageName $imageVersion.containerImage -alwaysPull:($imageversion.alwaysPull) -hybrid:($settings.hybrid) -Credential $credential -licenseFile $licenseFile
. (Join-Path $ScriptRoot "scripts\Compile-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ScriptRoot -buildSymbolsFolder $alPackagesFolder -appFolders @("app")
. (Join-Path $ScriptRoot "scripts\Import-TestToolkit.ps1")         -run $run -ContainerName $containerName -Credential $credential
. (Join-Path $ScriptRoot "scripts\Compile-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ScriptRoot -buildSymbolsFolder $alPackagesFolder -appFolders @("test")
if ($CodeSignPfxFile) {
    . (Join-Path $ScriptRoot "scripts\Sign-App.ps1")               -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -pfxFile $CodeSignPfxFile -pfxPassword $CodeSignPfxPassword
}
. (Join-Path $ScriptRoot "scripts\Publish-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -skipVerification:(!($CodeSignPfxFile))
. (Join-Path $ScriptRoot "scripts\Publish-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("test") -skipVerification
. (Join-Path $ScriptRoot "scripts\Run-Tests.ps1")                  -run $run -ContainerName $containerName -Credential $credential -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml")  -reRunFailedTests
. (Join-Path $ScriptRoot "scripts\Remove-Container.ps1")           -run $run -ContainerName $containerName -Credential $credential
