param(
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\..\A_FUNC_CUTTING_LIST.bas')
)

$ErrorActionPreference = 'Stop'
$taskExcel = $null
$taskBook = $null
$taskModule = (Resolve-Path -LiteralPath $ModulePath).Path
$taskTests = Join-Path $PSScriptRoot 'Test_CUTTING_LIST.bas'
$taskExitCode = 1
try {
    # An isolated, hidden Excel instance. No existing workbook is attached.
    $taskExcel = New-Object -ComObject Excel.Application
    $taskExcel.Visible = $false
    $taskExcel.DisplayAlerts = $false
    $taskExcel.EnableEvents = $false
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import($taskModule) | Out-Null
    $taskBook.VBProject.VBComponents.Import($taskTests) | Out-Null
    $taskResult = [string]$taskExcel.Run("'$($taskBook.Name)'!RunCuttingListTests")
    [PSCustomObject]@{
        ExcelVersion = $taskExcel.Version
        Module = $taskModule
        Result = $taskResult
    } | ConvertTo-Json
    if ($taskResult.StartsWith('PASS:')) { $taskExitCode = 0 }
}
catch {
    Write-Output ([PSCustomObject]@{ Result='ERROR'; Message=$_.Exception.Message } | ConvertTo-Json)
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
