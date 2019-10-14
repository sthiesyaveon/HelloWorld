Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory=$false)]
    [string] $containerName = $ENV:CONTAINERNAME,

    [Parameter(Mandatory=$false)]
    [string] $testSuite = "DEFAULT",

    [Parameter(Mandatory=$false)]
    [pscredential] $credential = $null,

    [Parameter(Mandatory=$false)]
    [string] $testResultsFile = (Join-Path $ENV:BUILD_REPOSITORY_LOCALPATH "TestResults.xml"),

    [switch] $reRunFailedTests
)

if (-not ($credential)) {
    $securePassword = try { $ENV:PASSWORD | ConvertTo-SecureString } catch { ConvertTo-SecureString -String $ENV:PASSWORD -AsPlainText -Force }
    $credential = New-Object PSCredential -ArgumentList $ENV:USERNAME, $SecurePassword
}

$TempTestResultFile = "C:\ProgramData\NavContainerHelper\Extensions\$containerName\Test Results.xml"

$tests = Get-TestsFromBCContainer `
    -containerName $containerName `
    -credential $credential `
    -ignoreGroups `
    -testSuite $testSuite

$azureDevOpsParam = @{}
if ($buildEnv -eq "AzureDevOps") {
    $azureDevOpsParam = @{ "AzureDevOps" = "Warning" }
}

$rerunTests = @()
$failedTests = @()
$first = $true
$tests | ForEach-Object {
    if (-not (Run-TestsInBcContainer @AzureDevOpsParam `
        -containerName $containerName `
        -credential $credential `
        -XUnitResultFileName $TempTestResultFile `
        -AppendToXUnitResultFile:(!$first) `
        -testSuite $testSuite `
        -testCodeunit $_.Id `
        -returnTrueIfAllPassed `
        -restartContainerAndRetry)) { $rerunTests += $_ }
    $first = $false
}
if ($rerunTests.Count -gt 0 -and $reRunFailedTests) {
    Restart-BCContainer -containerName $containername
    $rerunTests | % {
        if (-not (Run-TestsInBcContainer @AzureDevOpsParam `
            -containerName $containerName `
            -credential $credential `
            -XUnitResultFileName $TempTestResultFile `
            -AppendToXUnitResultFile:(!$first) `
            -testSuite $testSuite `
            -testCodeunit $_.Id `
            -returnTrueIfAllPassed `
            -restartContainerAndRetry)) { $failedTests += $_ }
        $first = $false
    }
}

Copy-Item -Path $TempTestResultFile -Destination $testResultsFile -Force
