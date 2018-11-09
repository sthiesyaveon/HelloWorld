Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    [Parameter(Mandatory=$true)]
    [string] $testResultsFile
)

# Run Test is a temp solution

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
$containerName = "$($settings.name)-$type"
$TempTestResultFile = "C:\ProgramData\NavContainerHelper\Extensions\$containerName\Test Results.xml"
Invoke-NavContainerCodeunit -containerName $containerName -Codeunitid $settings.TestCodeunitId -CompanyName $settings.TestCompanyName -Argument $TempTestResultFile -MethodName $settings.TestMethodName -TimeZone UTC
if ($run -eq "AzureDevOps") {
    (Get-Content -Path $TempTestResultFile -Raw | Convert-CALTestOutputToAzureDevOps).Save($testResultsFile)
} else {
    Copy-Item -Path $TempTestResultFile -Destination $testResultsFile -Force
}
