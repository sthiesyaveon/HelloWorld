Param(
    [Parameter(Mandatory=$false)]
    [string] $pipelineName = "$ENV:PipelineName",
    [Parameter(Mandatory=$false)]
    [string] $containerName = "$ENV:containerName",
    [Parameter(Mandatory=$false)]
    [string] $artifact = "$ENV:artifact",
    [Parameter(Mandatory=$false)]
    [string] $memoryLimit = "$ENV:memoryLimit",
    [Parameter(Mandatory=$false)]
    [string] $insiderSasToken = "$ENV:insiderSasToken",
    [Parameter(Mandatory=$false)]
    [string] $baseFolder = "$ENV:BUILD_REPOSITORY_LOCALPATH",
    [Parameter(Mandatory=$false)]
    [string] $licenseFile = "$ENV:licenseFile",
    [Parameter(Mandatory=$false)]
    [string] $installApps = "$ENV:installApps",
    [Parameter(Mandatory=$false)]
    [string] $appFolders = "$ENV:appFolders",
    [Parameter(Mandatory=$false)]
    [string] $testFolders = "$ENV:testFolders",
    [Parameter(Mandatory=$false)]
    [switch] $installTestFramework = "$ENV:installTestFramework" -eq "True",
    [Parameter(Mandatory=$false)]
    [switch] $installTestLibraries = "$ENV:installTestLibraries" -eq "True",
    [Parameter(Mandatory=$false)]
    [switch] $installPerformanceToolkit = "$ENV:installPerformanceToolkit" -eq "True",
    [Parameter(Mandatory=$false)]
    [switch] $enableCodeCop = "$ENV:enableCodeCop" -eq "True",
    [Parameter(Mandatory=$false)]
    [switch] $enableUICop = "$ENV:enableUICop" -eq "True",
    [Parameter(Mandatory=$false)]
    [switch] $enableAppSourceCop = "$ENV:enableAppSourceCop" -eq "True",
    [Parameter(Mandatory=$false)]
    [switch] $enablePerTenantExtensionCop = "$ENV:enablePerTenantExtensionCop" -eq "True",
    [Parameter(Mandatory=$false)]
    [string] $buildArtifactFolder = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY",
    [Parameter(Mandatory=$false)]
    [switch] $signapp = "$ENV:signapp" -eq "True",
    [Parameter(Mandatory=$false)]
    [string] $codeSigncertPfxFile = "$ENV:CodeSignCertPfxFile",
    [Parameter(Mandatory=$false)]
    [securestring] $codeSignCertPfxPassword = $null,
    [Parameter(Mandatory=$false)]
    [string] $appVersion = ""
)

$params = @{}
if ($signapp -and $codeSigncertPfxFile -ne "") {
    if ($codeSigncertPfxPassword) {
        $params = @{
            "codeSignCertPfxFile" = $codeSignCertPfxFile
            "codeSignCertPfxPassword" = $codeSignCertPfxPassword
        }
    }
    else {
        if ("$ENV:CodeSignCertPfxPassword" -ne "") {
            $codeSignCertPfxPassword = try { "$ENV:CodeSignCertPfxPassword" | ConvertTo-SecureString } catch { ConvertTo-SecureString -String "$ENV:CodeSignCertPfxPassword" -AsPlainText -Force }
            $params = @{
                "codeSignCertPfxFile" = $codeSignCertPfxFile
                "codeSignCertPfxPassword" = $codeSignCertPfxPassword
            }
        }
    }
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

