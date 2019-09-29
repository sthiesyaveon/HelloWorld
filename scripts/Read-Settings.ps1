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

$property = $settings.PSObject.Properties.Match('containerName')
if ($property.Value) {
    $containerName = $property.Value
}
else {
    $containerName = "$($settings.Name)-ci"
}

$property = $settings.PSObject.Properties.Match('navContainerHelperVersion')
if ($property.Value) {
    $navContainerHelperVersion = $property.Value
}
else {
    $navContainerHelperVersion = "latest"
}
Write-Host "Set navContainerHelperVersion = $navContainerHelperVersion"
Write-Host "##vso[task.setvariable variable=navContainerHelperVersion]$navContainerHelperVersion"

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
    "alwaysPull","reuseContainer" | ForEach-Object {
        $property = $imageVersion.PSObject.Properties.Match($_)
        if ($property.Value) {
            $propertyValue = $property.Value
        }
        else {
            $propertyValue = $false
        }
        Write-Host "Set $_ = $propertyValue"
        Write-Host "##vso[task.setvariable variable=$_]$propertyValue"
    }
    if ($imageVersion.PSObject.Properties.Match("containerName")) {
        $containerName = $imageversion.containerName
    }
}
else {
    throw "Unknown version: $version"
}

Write-Host "Set containerName = $containerName"
Write-Host "##vso[task.setvariable variable=containerName]$containerName"
