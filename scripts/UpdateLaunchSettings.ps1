Param(
    [string] $Name,
    [string] $Server
)

$launchSettings = [ordered]@{ "type" = "al";
                              "request" = "launch";
                              "name" = "$Name"; 
                              "server" = "$Server";
                              "serverInstance" = "NAV"; 
                              "tenant" = ""; 
                              "authentication" =  "UserPassword" }

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)

if ($settings.PSObject.Properties.name -match "startupObjectId") {
    $launchSettings += @{ "startupObjectId" = $settings.startupObjectId }
}
if ($settings.PSObject.Properties.name -match "startupObjectType") {
    $launchSettings += @{ "startupObjectType" = $settings.startupObjectType }
}
if ($settings.PSObject.Properties.name -match "breakOnError") {
    $launchSettings += @{ "breakOnError" = $settings.breakOnError }
}

Get-ChildItem (Join-Path $PSScriptRoot "..") | ForEach-Object {
    $folder = $_.FullName
    $launchJsonFile = Join-Path $folder ".vscode\launch.json"
    if (Test-Path $launchJsonFile) {
        Write-Host "Modifying $launchJsonFile"
        $launchJson = Get-Content $LaunchJsonFile | ConvertFrom-Json
        $launchJson.configurations = @($launchJson.configurations | Where-Object { $_.name -ne $launchsettings.name })
        $launchJson.configurations += $launchSettings
        $launchJson | ConvertTo-Json -Depth 10 | Set-Content $launchJsonFile
    }
}
