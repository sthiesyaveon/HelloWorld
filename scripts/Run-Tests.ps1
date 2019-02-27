Param(
    [ValidateSet('AzureDevOps','Local')]
    [string] $run = "AzureDevOps",
    [ValidateSet('current','nextminor','nextmajor')]
    [string] $version = "current",
    [ValidateSet('bld','dev')]
    [string] $type = "bld",
    [Parameter(Mandatory=$true)]
    [string] $testSuite,
    [Parameter(Mandatory=$true)]
    [pscredential] $credential,
    [Parameter(Mandatory=$true)]
    [string] $testResultsFile
)

# Run Test is a temporary hack
# We are working on a better solution
$settings = (Get-Content (Join-Path $PSScriptRoot "..\settings.json") | ConvertFrom-Json)
$containerName = "$($settings.name)-$type"
$TempTestResultFile = "C:\ProgramData\NavContainerHelper\Extensions\$containerName\Test Results.xml"
Run-TestsInNavContainer -containerName $containerName -XUnitResultFileName $TempTestResultFile -testSuite $testSuite -credential $credential -AzureDevOps warning
Copy-Item -Path $TempTestResultFile -Destination $testResultsFile -Force
