Param(
    [switch] $local,

    [Parameter(Mandatory=$true)]
    [string] $version
)

$agentName = ""
if (!$local) {
    $agentName = $ENV:AGENT_NAME
}

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
if ("$version" -eq "")  {
    $version = $settings.versions[0].version
    Write-Host "Version not defined, using $version"
}

$buildversion = $settings.versions | Where-Object { $_.version -eq $version }
if ($buildversion) {
    Write-Host "Set artifact = $($buildVersion.artifact)"
    Set-Variable -Name "artifact" -Value $buildVersion.artifact

    if ($buildversion.PSObject.Properties.Name -eq "signapp") {
        $signapp = $buildversion.signapp
    }
    else {
        $signapp = $true
    }
    Write-Host "Set signapp = $signapp"
    Set-Variable -Name "signapp" -Value $signapp
}
else {
    throw "Unknown version: $version"
}

$pipelineName = "$($settings.Name)-$version"
Write-Host "Set pipelineName = $pipelineName"

if ($local -or ("$AgentName" -ne "Hosted Agent" -and "$AgentName" -notlike "Azure Pipelines*")) {
    $imageName = "bcimage"
}
else {
    $imageName = ""
}
Write-Host "Set imageName = $imageName"

if ($agentName) {
    $containerName = "$($agentName -replace '[^a-zA-Z0-9---]', '')-$($pipelineName -replace '[^a-zA-Z0-9---]', '')"
}
else {
    $containerName = $pipelineName.Replace('.','-') -replace '[^a-zA-Z0-9---]', ''
}
Write-Host "Set containerName = $containerName"

"installApps", "appFolders", "testFolders", "memoryLimit" | ForEach-Object {
    $str = ""
    if ($settings.PSObject.Properties.Name -eq $_) {
        $str = $settings."$_"
    }
    Write-Host "Set $_ = $str"
    Set-Variable -Name $_ -Value $str
}

"installTestFramework", "installTestLibraries", "installPerformanceToolkit", "enableCodeCop", "enableAppSourceCop", "enablePerTenantExtensionCop", "enableUICop" | ForEach-Object {
    $str = "False"
    if ($settings.PSObject.Properties.Name -eq $_) {
        $str = $settings."$_"
    }
    Write-Host "Set $_ = $str"
    Set-Variable -Name $_ -Value ($str -eq "True")
}
