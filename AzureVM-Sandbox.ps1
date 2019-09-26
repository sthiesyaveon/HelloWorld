. (Join-Path $PSScriptRoot "Initialize.ps1")

$containername = "$($settings.name)-dev"

$azureVM = $userProfile.AzureVM
$azureVmCredential = New-Object PSCredential $azureVM.Username, ($azureVM.Password | ConvertTo-SecureString)
$sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck
$vmSession = $null
$tempLicenseFile = ""
$vmFolder = ""

try {
    $vmSession = New-PSSession -ComputerName $azureVM.ComputerName -Credential $azureVmCredential -UseSSL -SessionOption $sessionOption
    $vmFolder = CopyFoldersToSession -session $vmSession -baseFolder $ScriptRoot -subFolders @("scripts")

    $tempLicenseFile = CopyFileToSession -session $vmSession -localFile $licenseFile -returnSecurestring

    Invoke-Command -Session $vmSession -ScriptBlock { Param($ScriptRoot, $containerName, $imageVersion, $credential, $licenseFile, $settings)
        $ErrorActionPreference = "Stop"

        . (Join-Path $ScriptRoot "scripts\Install-NavContainerHelper.ps1") -run AzureVM
        . (Join-Path $ScriptRoot "scripts\Create-Container.ps1")           -run AzureVM -containerName $containerName -imageName $imageversion.containerImage -credential $credential -licensefile $licensefile -alwaysPull:($imageversion.alwaysPull)

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
