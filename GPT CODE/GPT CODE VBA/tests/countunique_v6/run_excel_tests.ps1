param(
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\..\A_FUNC_CountUnique_V6.bas')
)

$ErrorActionPreference = 'Stop'
$taskModule = (Resolve-Path -LiteralPath $ModulePath).Path
$taskTests = Join-Path $PSScriptRoot 'Test_CountUnique_V6.bas'
$taskExcel = $null
$taskBook = $null
$taskExitCode = 1

try {
    $taskExcel = New-Object -ComObject Excel.Application
    $taskExcel.Visible = $false
    $taskExcel.DisplayAlerts = $false
    $taskExcel.EnableEvents = $false
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import($taskModule) | Out-Null
    $taskBook.VBProject.VBComponents.Import($taskTests) | Out-Null
    $taskResult = $taskExcel.Run("'$($taskBook.Name)'!RunCountUniqueV6Tests")
    [PSCustomObject]@{
        ExcelVersion = $taskExcel.Version
        Module = $taskModule
        Result = [string]$taskResult
    } | ConvertTo-Json -Depth 3
    if ([string]$taskResult -like 'PASS:*') { $taskExitCode = 0 }
}
catch {
    Write-Error $_
}
finally {
    if ($null -ne $taskBook) {
        $taskBook.Close($false) | Out-Null
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskBook) | Out-Null
    }
    if ($null -ne $taskExcel) {
        $taskExcel.Quit()
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskExcel) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

exit $taskExitCode
