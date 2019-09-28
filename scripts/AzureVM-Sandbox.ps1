﻿. ".\Initialize.ps1"

$containername = "$($settings.name)-dev"

$azureVM = $userProfile.AzureVM
$azureVmCredential = New-Object PSCredential $azureVM.Username, ($azureVM.Password | ConvertTo-SecureString)
$sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
$vmSession = $null
$tempLicenseFile = ""
$vmFolder = ""

try {
    $vmSession = New-PSSession -ComputerName $azureVM.ComputerName -Credential $azureVmCredential -UseSSL -SessionOption $sessionOption
    $vmFolder = CopyFoldersToSession -session $vmSession -baseFolder $ProjectRoot -subFolders @("scripts")

    $tempLicenseFile = CopyFileToSession -session $vmSession -localFile $licenseFile -returnSecurestring

    Invoke-Command -Session $vmSession -ScriptBlock { Param($ProjectRoot, $containerName, $imageVersion, $credential, $licenseFile, $settings)
        $ErrorActionPreference = "Stop"
        cd (Join-Path $ProjectRoot "scripts")

        $run = "AzureVM"
        $navContainerHelperPath = "C:\DEMO\navcontainerhelper-dev\NavContainerHelper.ps1"

        . ".\Install-NavContainerHelper.ps1" -run $run -navContainerHelperPath $navContainerHelperPath
        . ".\Create-Container.ps1"           -run $run -containerName $containerName -imageName $imageversion.containerImage -credential $credential -licensefile $licensefile -alwaysPull:($imageversion.alwaysPull)

    } -ArgumentList $vmFolder, $containerName, $imageVersion, $credential, $tempLicenseFile, $settings

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
        if ($vmFolder) {
            try { RemoveFolderFromSession -session $vmSession -foldername $vmFolder } catch {}
        }
        Remove-PSSession -Session $vmSession
    }
}

UpdateLaunchJson -name "AzureVM Sandbox" -server "https://$($azureVM.ComputerName)" -port 443 -serverInstance "$($containername)dev"