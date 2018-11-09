. (Join-Path $PSScriptRoot "ReadSettings.ps1")

$type = "bld"

$licenseFileParam = @{}
if ($licensefileSecret) {
    $licenseFileParam += @{"licensefile" = $licensefileSecret.SecretValue }
}

$buildProjectFolder = (Get-Item (Join-Path $ScriptRoot "..")).FullName
$buildArtifactFolder = Join-Path $buildProjectFolder ".output"
if (Test-Path $buildArtifactFolder) {
    Remove-Item $buildArtifactFolder -Force -Recurse
}
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

. (Join-Path $ScriptRoot "Install-NavContainerHelper.ps1") -run Local
. (Join-Path $ScriptRoot "Create-Container.ps1")           -run Local -version $version -type $type -Credential $credential @licenseFileParam
. (Join-Path $ScriptRoot "Compile-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $buildProjectFolder -appFolders @("app")
if (($pfxFileSecret) -and ($pfxPasswordSecret)) {
    . (Join-Path $ScriptRoot "Sign-App.ps1")               -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -pfxFile $pfxFileSecret.SecretValue -pfxPassword $pfxPasswordSecret.SecretValue
    . (Join-Path $ScriptRoot "Publish-App.ps1")            -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app")
} else {
    . (Join-Path $ScriptRoot "Publish-App.ps1")            -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -skipVerification
}
. (Join-Path $ScriptRoot "Import-TestToolkit.ps1")         -run Local -version $version -type $type -Credential $credential
. (Join-Path $ScriptRoot "Compile-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $buildProjectFolder -appFolders @("test")
. (Join-Path $ScriptRoot "Publish-App.ps1")                -run Local -version $version -type $type -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("test") -skipVerification 
#. (Join-Path $ScriptRoot "Run-Tests.ps1")                  -run Local -version $version -type $type -Credential $credential -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml")
. (Join-Path $ScriptRoot "Remove-Container.ps1")           -run Local -version $version -type $type -Credential $credential
