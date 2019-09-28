Param(
    [Parameter(Mandatory=$false)]
    [string] $version = "",

    [Parameter(Mandatory=$true)]
    [string] $buildProjectFolder
)

$settings = (Get-Content (Join-Path $buildProjectFolder "scripts\settings.json") | ConvertFrom-Json)
if ("$version" -eq "")  {
    $version = $settings.versions[0].version
    Write-Host "Version not defined, using $version"
}
$appFolders = $settings.appFolders
Write-Host "Set appFolders = $appFolders"
Write-Host "##vso[task.setvariable variable=appFolders]$appFolders"

$testFolders = $settings.testFolders
Write-Host "Set testFolders = $testFolders"
Write-Host "##vso[task.setvariable variable=testFolders]$testFolders"

$imageversion = $settings.versions | Where-Object { $_.version -eq $version }
if ($imageversion) {
    Write-Host "Set imageName = $($imageVersion.containerImage)"
    Write-Host "##vso[task.setvariable variable=imageName]$($imageVersion.containerImage)"
    Write-Host "Set alwaysPull = $($imageVersion.alwaysPull)"
    Write-Host "##vso[task.setvariable variable=alwaysPull]$($imageVersion.alwaysPull)"
}
else {
    throw "Unknown version: $version"
}