. (Join-Path $PSScriptRoot "Initialize.ps1")

$containername = "$($settings.name)-bld"
$buildArtifactFolder = Join-Path $ScriptRoot ".output"
if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

$azureVM = $userProfile.AzureVM
$azureVmCredential = New-Object PSCredential $azureVM.Username, ($azureVM.Password | ConvertTo-SecureString)
$sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
$vmSession = $null
$tempLicenseFile = ""
$tempCodeSignPfxFile = ""
$vmFolder = ""

try {
    $vmSession = New-PSSession -ComputerName $azureVM.ComputerName -Credential $azureVmCredential -UseSSL -SessionOption $sessionOption
    $vmFolder = CopyFoldersToSession -session $vmSession -baseFolder $ScriptRoot -subFolders @("scripts","app","test")

    $tempLicenseFile = CopyFileToSession -session $vmSession -LocalFile $licenseFile -returnSecureString
    $tempCodeSignPfxFile = CopyFileToSession -session $vmSession -LocalFile $codeSignPfxFile -returnSecureString

    Invoke-Command -Session $vmSession -ScriptBlock { Param($ScriptRoot, $containerName, $imageVersion, $credential, $licenseFile, $settings, $codeSignPfxFile, $codeSignPfxPassword)

        $ErrorActionPreference = "Stop"

        $run = "AzureVM"
        $navContainerHelperPath = "C:\DEMO\navcontainerhelper-dev\NavContainerHelper.ps1"

        $buildArtifactFolder = Join-Path $ScriptRoot ".output"
        if (Test-Path $buildArtifactFolder) { Remove-Item $buildArtifactFolder -Force -Recurse }
        New-Item -Path $buildArtifactFolder -ItemType Directory -Force | Out-Null

        $alPackagesFolder = Join-Path $ScriptRoot ".alPackages"
        if (Test-Path $alPackagesFolder) { Remove-Item $alPackagesFolder -Force -Recurse }
        New-Item -Path $alPackagesFolder -ItemType Directory -Force | Out-Null

        . (Join-Path $ScriptRoot "scripts\Install-NavContainerHelper.ps1") -run $run -navContainerHelperPath $navContainerHelperPath
        . (Join-Path $ScriptRoot "scripts\Create-Container.ps1")           -run $run -ContainerName $containerName -imageName $imageVersion.containerImage -alwaysPull:($imageversion.alwaysPull) -Credential $credential -licenseFile $licenseFile
        . (Join-Path $ScriptRoot "scripts\Compile-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ScriptRoot -buildSymbolsFolder $alPackagesFolder -appFolders @("app")
        . (Join-Path $ScriptRoot "scripts\Compile-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -buildProjectFolder $ScriptRoot -buildSymbolsFolder $alPackagesFolder -appFolders @("test")
        if ($CodeSignPfxFile) {
            . (Join-Path $ScriptRoot "scripts\Sign-App.ps1")               -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -pfxFile $CodeSignPfxFile -pfxPassword $CodeSignPfxPassword
        }
        . (Join-Path $ScriptRoot "scripts\Publish-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("app") -skipVerification:(!($CodeSignPfxFile))
        . (Join-Path $ScriptRoot "scripts\Publish-App.ps1")                -run $run -ContainerName $containerName -Credential $credential -buildArtifactFolder $buildArtifactFolder -appFolders @("test") -skipVerification
        . (Join-Path $ScriptRoot "scripts\Run-Tests.ps1")                  -run $run -ContainerName $containerName -Credential $credential -testResultsFile (Join-Path $buildArtifactFolder "TestResults.xml")  -reRunFailedTests
        . (Join-Path $ScriptRoot "scripts\Remove-Container.ps1")           -run $run -ContainerName $containerName -Credential $credential

    } -ArgumentList $vmFolder, $containerName, $imageVersion, $credential, $tempLicenseFile, $settings, $tempCodeSignPfxFile, $codeSignPfxPassword
    
    Copy-Item -FromSession $vmSession -Path (Join-Path $vmFolder ".output") -Destination $ScriptRoot -Force -recurse
}
catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
    try { $myip = ""; $myip = (Invoke-WebRequest -Uri http://ifconfig.me/ip).Content } catch { }
    throw "Could not connect to $($azureVM.ComputerName). Maybe port 5986 (WinRM) is not open for your IP address $myip"
}
finally {
    if ($vmSession) {
        if ($tempLicenseFile) {
            try { RemoveFileFromSession -session $vmSession -filename $tempLicenseFile } catch {}
        }
        if ($tempCodeSignPfxfile) {
            try { RemoveFileFromSession -session $vmSession -filename $tempCodeSignPfxFile } catch {}
        }
        if ($vmFolder) {
            try { RemoveFolderFromSession -session $vmSession -foldername $vmFolder } catch {}
        }
        Remove-PSSession -Session $vmSession
    }
}
