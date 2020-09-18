Param(
    [Parameter(Mandatory=$true)]
    [string] $version,
    [Parameter(Mandatory=$false)]
    [string] $appVersion = ""
)

if ($appVersion) {
    Write-Host "Set BuildNumber = $appVersion"
    write-host "##vso[build.updatebuildnumber]$appVersion" 
}

$buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY
$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -local -version $version

$params = @{}
$insiderSasToken = "$ENV:insiderSasToken"
$licenseFile = "$ENV:licenseFile"
$codeSigncertPfxFile = "$ENV:CodeSignCertPfxFile"
if ($signapp -and $codeSigncertPfxFile) {
    if ("$ENV:CodeSignCertPfxPassword" -ne "") {
        $codeSignCertPfxPassword = try { "$ENV:CodeSignCertPfxPassword" | ConvertTo-SecureString } catch { ConvertTo-SecureString -String "$ENV:CodeSignCertPfxPassword" -AsPlainText -Force }
        $params = @{
            "codeSignCertPfxFile" = $codeSignCertPfxFile
            "codeSignCertPfxPassword" = $codeSignCertPfxPassword
        }
    }
    else {
        $codeSignCertPfxPassword = $null
    }
}

$testResultsFile = Join-Path $baseFolder "TestResults.xml"
if (Test-Path $testResultsFile) {
    Remove-Item $testResultsFile -Force
}

Run-AlPipeline @params `
    -pipelinename $pipelineName `
    -containerName $containerName `
    -artifact $artifact.replace('{INSIDERSASTOKEN}',$insiderSasToken) `
    -memoryLimit $memoryLimit `
    -baseFolder $baseFolder `
    -licenseFile $LicenseFile `
    -installApps $installApps `
    -appFolders $appFolders `
    -testFolders $testFolders `
    -testResultsFile $testResultsFile `
    -installTestFramework:$installTestFramework `
    -installTestLibraries:$installTestLibraries `
    -installPerformanceToolkit:$installPerformanceToolkit `
    -enableCodeCop:$enableCodeCop `
    -enableUICop:$enableUICop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -buildArtifactFolder $buildArtifactFolder `
    -CreateRuntimePackages `
    -appVersion $appVersion

if (Test-Path $testResultsFile) {
    Write-Host "##vso[task.setvariable variable=TestResultsAvailable]True"
}

