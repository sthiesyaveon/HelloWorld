Param(
    [string] $bcContainerHelperVersion = "",
    [string] $genericImageName = ""
)

if ($bcContainerHelperVersion -eq "") {
    $bcContainerHelperVersion = "latest"
}
Write-Host "Use bcContainerHelper Version: '$bcContainerHelperVersion'"

$buildMutexName = "bcContainerHelper"
$buildMutex = New-Object System.Threading.Mutex($false, $buildMutexName)
try {
    try {
        if (!$buildMutex.WaitOne(1000)) {
            Write-Host "Waiting for other process to update BcContainerHelper"
            $buildMutex.WaitOne() | Out-Null
            Write-Host "Other process completed"
        }
    }
    catch [System.Threading.AbandonedMutexException] {
       Write-Host "Other process terminated abnormally"
    }

    $bcContainerHelperVersion = $bcContainerHelperVersion.Replace('{HOME}',$HOME.TrimEnd('\'))
    if ($bcContainerHelperVersion -like "?:\*") {
        if (Test-Path $bcContainerHelperVersion) {
            $bch = Get-Item (Join-Path $bcContainerHelperVersion '*ContainerHelper.ps1')
            if ($bch) {
                Write-Host "Using $bch"
                . "$bch"
                return
            }
        }
        $bcContainerHelperVersion = "https://github.com/microsoft/navcontainerhelper/archive/dev.zip"
    }

    if ($bcContainerHelperVersion -like "https://*") {
        Remove-Module BcContainerHelper -ErrorAction SilentlyContinue
        $tempName = Join-Path $env:TEMP $containerName
        Remove-Item $tempName -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$tempName.zip" -Force -ErrorAction SilentlyContinue
        Write-Host "Downloading $bcContainerHelperVersion"
        (New-Object System.Net.WebClient).DownloadFile($bcContainerHelperVersion, "$tempName.zip")
        Expand-Archive -Path "$tempName.zip" -DestinationPath $tempName
        $modulePath = (Get-Item (Join-Path $tempName "*\BcContainerHelper.psm1")).FullName
        Write-Host $modulePath
        Import-Module $modulePath -DisableNameChecking
    }
    else {
        Remove-Module -Name BcContainerHelper -Force -ErrorAction SilentlyContinue
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
        $modules = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue -AllVersions -AllowPrerelease
        if ($modules | Where-Object { $_.Version -eq $bcContainerHelperVersion }) {
            if ($bcContainerHelperVersion -like "*preview*") {
                Import-Module -Name BcContainerHelper -DisableNameChecking
            }
            else {
                Import-Module -Name BcContainerHelper -RequiredVersion $bcContainerHelperVersion -DisableNameChecking
            }
        }
        else {
            if ($bcContainerHelperVersion -like "*preview*") {
                Install-Module -Name BcContainerHelper -AllowPrerelease -Force
                Import-Module -Name BcContainerHelper -Force -DisableNameChecking
            }
            else {
                Install-Module -Name BcContainerHelper -RequiredVersion $bcContainerHelperVersion -Force
                Import-Module -Name BcContainerHelper -RequiredVersion $bcContainerHelperVersion -Force -DisableNameChecking
            }
        }
    }
}
finally {
    $buildMutex.ReleaseMutex()
}

if ($genericImageName) {
    $bcContainerHelperConfig.genericImageName = $genericImageName
}
