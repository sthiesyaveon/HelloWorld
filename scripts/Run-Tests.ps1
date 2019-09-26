Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $run = "AzureDevOps",

    [Parameter(Mandatory=$true)]
    [string] $containerName,

    [Parameter(Mandatory=$false)]
    [string] $testSuite = "Default",

    [Parameter(Mandatory=$true)]
    [pscredential] $credential,

    [Parameter(Mandatory=$true)]
    [string] $testResultsFile,

    [switch] $reRunFailedTests
)

$TempTestResultFile = "C:\ProgramData\NavContainerHelper\Extensions\$containerName\Test Results.xml"

$tests = Get-TestsFromBCContainer -containerName $containerName `
                                  -credential $credential `
                                  -ignoreGroups `
                                  -testSuite $testSuite `
                                  -usePublicWebBaseUrl:($run -eq "AzureVM")

$azureDevOpsParam = @{}
if ($run -eq "AzureDevOps") {
    $azureDevOpsParam = @{ "AzureDevOps" = "Warning" }
}

$rerunTests = @()
$failedTests = @()
$first = $true
$tests | % {
    if (-not (Run-TestsInBcContainer @AzureDevOpsParam -containerName $containerName `
                                     -credential $credential `
                                     -XUnitResultFileName $TempTestResultFile `
                                     -AppendToXUnitResultFile:(!$first) `
                                     -testCodeunit $_.Id `
                                     -returnTrueIfAllPassed `
                                     -usePublicWebBaseUrl:($run -eq "AzureVM") `
                                     -restartContainerAndRetry)) { $rerunTests += $_ }
    $first = $false
}
if ($rerunTests.Count -gt 0 -and $reRunFailedTests) {
    Restart-BCContainer -containerName $containername
    $rerunTests | % {
        if (-not (Run-TestsInBcContainer @AzureDevOpsParam -containerName $containerName `
                                         -credential $credential `
                                         -XUnitResultFileName $TempTestResultFile `
                                         -AppendToXUnitResultFile:(!$first) `
                                         -testCodeunit $_.Id `
                                         -returnTrueIfAllPassed `
                                         -usePublicWebBaseUrl:($run -eq "AzureVM") `
                                         -restartContainerAndRetry)) { $failedTests += $_ }
        $first = $false
    }
}

Copy-Item -Path $TempTestResultFile -Destination $testResultsFile -Force
