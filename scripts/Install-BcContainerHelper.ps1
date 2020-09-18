[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
if ("$version" -eq "")  {
    $version = $settings.versions[0].version
    Write-Host "Version not defined, using $version"
}

$bcContainerHelperVersion = "latest"
if ($settings.PSObject.Properties.Name -eq 'bcContainerHelperVersion' -and $settings.bcContainerHelperVersion) {
    $bcContainerHelperVersion = $settings.bcContainerHelperVersion
}
Write-Host "Set bcContainerHelperVersion = $bcContainerHelperVersion"
if (!$local) { Write-Host "##vso[task.setvariable variable=bcContainerHelperVersion]$bcContainerHelperVersion" }

Write-Host "Version: $bcContainerHelperVersion"

if ($bcContainerHelperVersion -like "https://*") {

    Remove-Module BcContainerHelper -ErrorAction SilentlyContinue
    UnInstall-Module BcContainerHelper -allVersions -ErrorAction SilentlyContinue

    $modulesFolder = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules"
    if (!(Test-Path $modulesFolder)) {
        New-Item -Path $modulesFolder -ItemType Directory | Out-Null
    }
    $bcContainerHelperFolder = Join-Path $modulesFolder "bcContainerHelper"
    if (Test-Path $bcContainerHelperFolder) {
        Remove-Item $bcContainerHelperFolder -recurse -force
    }
    $tempFolder = $env:TEMP
    $zipFileName = Join-Path $tempFolder "bccontainerhelper.zip"
    if (Test-Path $zipFileName) {
        Remove-Item $zipFileName -Force
    }
    $bcContainerHelperTempFolder = Join-Path $tempFolder "bcContainerHelper"
    if (Test-Path $bcContainerHelperTempFolder) {
        Remove-Item $bcContainerHelperTempFolder -recurse -force
    }

    Write-Host "Downloading $bcContainerHelperVersion"
    (New-Object System.Net.WebClient).DownloadFile($bcContainerHelperVersion, $zipFileName)
    Expand-Archive -Path $zipFileName -DestinationPath $bcContainerHelperTempFolder
    $modulePath = (Get-Item -Path (Join-Path $bcContainerHelperTempFolder "*\bcContainerHelper.psd1")).Directory
    Write-Host $modulePath
    Move-Item -Path $modulePath -Destination (Join-Path $modulesFolder "bcContainerHelper")
    Import-Module bcContainerHelper -DisableNameChecking
}
else {
    $module = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue
    if ($module) {
        $versionStr = $module.Version.ToString()
        Write-Host "BcContainerHelper $VersionStr is installed"
        if ($bcContainerHelperVersion -eq "preview") {
            Write-Host "Determine latest BcContainerHelper preview version"
            $latestVersion = (Find-Module -Name bccontainerhelper -AllowPrerelease).Version
            $bcContainerHelperVersion = $latestVersion.ToString()
            Write-Host "BcContainerHelper $bcContainerHelperVersion is the latest preview version"
        }
        elseif ($bcContainerHelperVersion -eq "latest") {
            Write-Host "Determine latest BcContainerHelper version"
            $latestVersion = (Find-Module -Name bccontainerhelper).Version
            $bcContainerHelperVersion = $latestVersion.ToString()
            Write-Host "BcContainerHelper $bcContainerHelperVersion is the latest version"
        }
        if ($bcContainerHelperVersion -ne $module.Version) {
            Write-Host "Updating BcContainerHelper to $bcContainerHelperVersion"
            Remove-Module bccontainerhelper -ErrorAction SilentlyContinue
            Update-Module -Name bccontainerhelper -Force -RequiredVersion $bcContainerHelperVersion -AllowPrerelease
            Write-Host "BcContainerHelper updated"
        }
    }
    else {
        if (!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Write-Host "Installing NuGet Package Provider"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -WarningAction SilentlyContinue | Out-Null
        }
        if ($bcContainerHelperVersion -eq "preview") {
            Write-Host "Installing BcContainerHelper"
            Install-Module -Name bccontainerhelper -Force -AllowPrerelease
        }
        elseif ($bcContainerHelperVersion -eq "latest") {
            Write-Host "Installing BcContainerHelper"
            Install-Module -Name bccontainerhelper -Force
        }
        else {
            Write-Host "Installing BcContainerHelper version $bcContainerHelperVersion"
            Install-Module -Name bccontainerhelper -Force -RequiredVersion $bcContainerHelperVersion
        }
        $module = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue
        $versionStr = $module.Version.ToString()
        Write-Host "BcContainerHelper $VersionStr installed"
    }
}

