if (Test-Path 'c:\demo\settings.ps1') {
    
    # Running inside an AzureVM created by http://aka.ms/getbc
    
    . 'c:\demo\settings.ps1'

    $securePassword = ConvertTo-SecureString -String $adminPassword -Key $passwordKey
    $credential = New-Object System.Management.Automation.PSCredential($navAdminUsername, $securePassword)
}
else {

    $containerName = ""
    $adminUsername = ""
    $adminPassword = ""

    if ($containerName -eq "" -or $adminPassword -eq "" -or $adminPassword -eq "") {
        throw "You need to set containername and credentials to rebuild solution."
    }

    $securePassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($adminUsername, $securePassword)
}

if (Test-NavContainer $containerName) {
    $tempProjectFolder = "c:\programdata\navcontainerhelper\$([Guid]::NewGuid().ToString())"
    New-Item -Path $tempProjectFolder -ItemType Directory | Out-Null
    $appFolders = @()
    Get-ChildItem -Path $path | Where-Object { $_.psIsContainer -and $_.Name -notlike ".*" -and (Test-Path (Join-Path $_.FullName "app.json")) } | ForEach-Object {
        $appFolders += @($_.Name)
        Copy-Item -Path $_.FullName -Destination $tempProjectFolder -Recurse -Force
    }

    $appFolders = Sort-AppFoldersByDependencies -baseFolder $tempProjectFolder -appFolders $appFolders

    $appFolders | ForEach-Object {
        $appFile = Compile-AppInBCContainer `
            -containerName $containerName `
            -credential $credential `
            -appProjectFolder (Join-Path $tempProjectFolder $_) `
            -appOutputFolder  (Join-Path $tempProjectFolder $_) `
            -appSymbolsFolder (Join-Path $tempProjectFolder "$_\.alPackages") `
            -UpdateSymbols
        if ($appFile) {
            Publish-BCContainerApp `
                -containerName $containerName `
                -appFile $appFile `
                -skipVerification `
                -sync `
                -install `
                -useDevEndpoint `
                -credential $credential
        }
    }

    Get-ChildItem $tempProjectFolder -Recurse | ForEach-Object {
        $srcpath = $_.FullName
        if ($srcpath -like "$($tempProjectFolder)*") {
            $destPath = Join-Path $path $srcPath.Substring($tempProjectFolder.Length)
            if (!(Test-Path $destPath)) {
                Copy-Item -Path $srcPath -Destination $destPath -Force
            }
        }
    }
}
