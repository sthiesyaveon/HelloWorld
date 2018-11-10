Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps"
)

$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$navContainerHelperPath = ""
if ($settings.PSObject.Properties.name -match "navContainerHelperPath") {
    $navContainerHelperPath = $settings.navContainerHelperPath.Replace('$HOME',"$HOME")
}
if ($run -eq "Local" -and $navContainerHelperPath -ne "" -and (Test-Path $navContainerHelperPath)) {
    Write-Host "Using NavContainerHelper from $navContainerHelperPath"
    . $navContainerHelperPath
} else {
    $module = Get-InstalledModule -Name navcontainerhelper -ErrorAction Ignore
    if ($module) {
        $versionStr = $module.Version.ToString()
        Write-Host "NavContainerHelper $VersionStr is installed"
        Write-Host "Determine latest NavContainerHelper version"
        $latestVersion = (Find-Module -Name navcontainerhelper).Version
        $latestVersionStr = $latestVersion.ToString()
        Write-Host "NavContainerHelper $latestVersionStr is the latest version"
        if ($latestVersion -gt $module.Version) {
            Write-Host "Updating NavContainerHelper to $latestVersionStr"
            Update-Module -Name navcontainerhelper -Force -RequiredVersion $latestVersionStr
            Write-Host "NavContainerHelper updated"
        }
    } else {
        Write-Host "Installing NavContainerHelper"
        Install-Module -Name navcontainerhelper -Force
        $module = Get-InstalledModule -Name navcontainerhelper -ErrorAction Ignore
        $versionStr = $module.Version.ToString()
        Write-Host "NavContainerHelper $VersionStr installed"
    }
}
