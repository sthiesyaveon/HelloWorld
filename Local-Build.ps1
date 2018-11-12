. (Join-Path $PSScriptRoot "Initialize.ps1")

$type = "bld"

$buildArtifactFolder = Join-Path $ScriptRoot ".output"
if (Test-Path $buildArtifactFolder) {
    Remove-Item $buildArtifactFolder -Force -Recurse
}
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

. (Join-Path $ScriptRoot "scripts\Install-NavContainerHelper.ps1") -run Local
. (Join-Path $ScriptRoot "scripts\Create-Container.ps1")           -run Local -version $version -type $type -Credential $credential -licenseFile $licensefileSecret.SecretValueText
. (Join-Path $ScriptRoot "scripts\Compile-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ScriptRoot -appFolders @("app")
$signApp = (($CodeSignPfxFileSecret.SecretValueText) -and ($CodeSignPfxPasswordSecret.SecretValueText))
if ($signApp) {
    . (Join-Path $ScriptRoot "scripts\Sign-App.ps1")               -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -pfxFile $CodeSignPfxFileSecret.SecretValue -pfxPassword $CodeSignPfxPasswordSecret.SecretValue
}
. (Join-Path $ScriptRoot "scripts\Publish-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -skipVerification:(!($signApp))
. (Join-Path $ScriptRoot "scripts\Import-TestToolkit.ps1")         -run Local -version $version -type $type -Credential $credential
. (Join-Path $ScriptRoot "scripts\Compile-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ScriptRoot -appFolders @("test")
. (Join-Path $ScriptRoot "scripts\Publish-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("test") -skipVerification 
. (Join-Path $ScriptRoot "scripts\Run-Tests.ps1")                  -run Local -version $version -type $type -Credential $credential -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml") -test "unittests"
. (Join-Path $ScriptRoot "scripts\Remove-Container.ps1")           -run Local -version $version -type $type -Credential $credential
