$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$ScriptRoot = $PSScriptRoot

$settings = (Get-Content (Join-Path $ScriptRoot "settings.json") | ConvertFrom-Json)

$defaultVersion = $settings.versions[0].version
$version = Read-Host ("Select Version (" +(($settings.versions | ForEach-Object { $_.version }) -join ", ") + ") (default $defaultVersion)")
if (!($version)) {
    $version = $defaultVersion
}

$defaultUserProfile = $settings.userProfiles | Where-Object { $_.profile -eq "$($env:COMPUTERNAME)\$($env:USERNAME)" }
if (!($defaultUserProfile)) {
    $defaultUserProfile = $settings.userProfiles | Where-Object { $_.profile -eq $env:USERNAME }
    if (!($defaultUserProfile)) {
        $defaultUserProfile = $settings.userProfiles | Where-Object { $_.profile -eq "default" }
    }
}

if ($defaultUserProfile) {
    $profile = $defaultUserProfile.profile
}
else {
    $defaultUserProfile = $settings.userProfiles[0]
    $profile = Read-Host ("Select User Profile (" +(($settings.userProfiles | ForEach-Object { $_.profile }) -join ", ") + ") (default $($defaultUserProfile.profile))")
}

$userProfile = $settings.userProfiles | Where-Object { $_.profile -eq $profile }
$imageversion = $settings.versions | Where-Object { $_.version -eq $version }
if (!($imageversion)) {
    throw "No version for $version in settings.json"
}

if ($userProfile.licenseFilePath) {
    $licenseFile = $userProfile.licenseFilePath | ConvertTo-SecureString
}
else {
    $licenseFile = $null
}
$credential = New-Object PSCredential($userProfile.Username, ($userProfile.Password | ConvertTo-SecureString))
$CodeSignPfxFile = $null
if (($userProfile.PSObject.Properties.name -eq "CodeSignPfxFilePath") -and ($userProfile.PSObject.Properties.name -eq "CodeSignPfxPassword")) {
    $CodeSignPfxFile = ConvertTo-SecureString -string $userProfile.CodeSignPfxFilePath -AsPlainText -Force
    $CodeSignPfxPassword = $userProfile.CodeSignPfxPassword | ConvertTo-SecureString
}

Function UpdateLaunchJson {
    Param(
        [string] $Name,
        [string] $Server,
        [int] $Port = 7049,
        [string] $ServerInstance = "NAV"
    )
    
    $launchSettings = [ordered]@{ "type" = "al";
                                  "request" = "launch";
                                  "name" = "$Name"; 
                                  "server" = "$Server"
                                  "serverInstance" = $serverInstance
                                  "port" = $Port
                                  "tenant" = ""
                                  "authentication" =  "UserPassword"
    }
    
    $settings = (Get-Content (Join-Path $ScriptRoot "settings.json") | ConvertFrom-Json)
    
    $settings.launch.PSObject.Properties | % {
        $setting = $_
        $launchSetting = $launchSettings.GetEnumerator() | Where-Object { $_.Name -eq $setting.Name }
        if ($launchSetting) {
            $launchSettings[$_.Name] = $_.Value
        }
        else {
            $launchSettings += @{ $_.Name = $_.Value }
        }
    }
    
    Get-ChildItem $ScriptRoot -Directory | ForEach-Object {
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
}

function InvokeScriptInSession {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.PSSession] $session,
        [Parameter(Mandatory=$true)]
        [string] $filename,
        [Parameter(Mandatory=$false)]
        [object[]] $argumentList
    )

    Invoke-Command -Session $vmSession -ScriptBlock ([ScriptBlock]::Create([System.IO.File]::ReadAllText($filename))) -ArgumentList $argumentList
}

function CopyFileToSession {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.PSSession] $session,
        $localfile,
        [switch] $returnSecureString
    )

    if ($localfile) {
        if ($localFile -is [securestring]) {
            $localFile = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($localFile)))
        }
        if ($localfile -notlike "https://*" -and $localfile -notlike "http://*") {
            $tempFilename = "c:\demo\$([Guid]::NewGuid().ToString())"
            Copy-Item -ToSession $vmSession -Path $localFile -Destination $tempFilename
            $localfile = $tempFilename
        }
        if ($returnSecureString) {
            ConvertTo-SecureString -String $localfile -AsPlainText -Force
        }
        else {
            $localfile
        }
    }
    else {
        if ($returnSecureString) {
            $null
        }
        else {
            ""
        }
    }
}

function RemoveFileFromSession {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.PSSession] $session,
        $filename
    )
    
    if ($filename) {
        if ($filename -is [securestring]) {
            $filename = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($filename)))
        }
        if ($filename -notlike "https://*" -and $filename -notlike "http://*") {
            Invoke-Command -Session $session -ScriptBlock { Param($filename)
                Remove-Item $filename -Force
            } -ArgumentList $filename
        }
    }
}

function CopyFoldersToSession {
    Param(
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.Runspaces.PSSession] $session,
        [Parameter(Mandatory=$true)]
        [string] $baseFolder,
        [Parameter(Mandatory=$true)]
        [string[]] $subFolders,
        [Parameter(Mandatory=$false)]
        [string[]] $exclude = @("*.app")
    )

    $tempFolder = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
    $subFolders | % {
        Copy-Item -Path (Join-Path $baseFolder $_) -Destination (Join-Path $tempFolder "$_\") -Recurse -Exclude $exclude
    }

    $file = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
    Add-Type -Assembly System.IO.Compression
    Add-Type -Assembly System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempfolder, $file)
    $sessionFile = CopyFileToSession -session $session -localfile $file
    Remove-Item $file -Force

    Invoke-Command -Session $session -ScriptBlock { Param($filename)
        Add-Type -Assembly System.IO.Compression
        Add-Type -Assembly System.IO.Compression.FileSystem
        $tempFoldername = "c:\demo\$([Guid]::NewGuid().ToString())"
        [System.IO.Compression.ZipFile]::ExtractToDirectory($filename, $tempfoldername)
        Remove-Item $filename -Force
        $tempfoldername
    } -ArgumentList $sessionFile
}

function RemoveFolderFromSession {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.PSSession] $session,
        [Parameter(Mandatory=$true)]
        [string] $foldername
    )
    
    Invoke-Command -Session $session -ScriptBlock { Param($foldername)
        Remove-Item $foldername -Force -Recurse
    } -ArgumentList $foldername
}
