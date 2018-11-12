Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [string] $test,
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    [Parameter(Mandatory=$true)]
    [string] $testResultsFile
)

# Run Test is a temporary hack
# We are working on a better solution
$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$runtest = $settings.tests | Where-Object { $_.test -eq $test }
if ($runtest) {
    $containerName = "$($settings.name)-$type"
    $TempTestResultFile = "C:\ProgramData\NavContainerHelper\Extensions\$containerName\Test Results.xml"
    if ($runtest.type -eq "Codeunit") {
        Invoke-NavContainerCodeunit -containerName $containerName -Codeunitid $runtest.codeunitId -CompanyName $runtest.companyName -Argument $TempTestResultFile -MethodName $runtest.methodName -TimeZone UTC
    } else {
        throw "Unknown test type"
    }
    if ($run -eq "AzureDevOps") {
        (Get-Content -Path $TempTestResultFile -Raw | Convert-CALTestOutputToAzureDevOps).Save($testResultsFile)
    } else {
        Copy-Item -Path $TempTestResultFile -Destination $testResultsFile -Force
    }
}
