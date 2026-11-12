param(
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\..\A_FUNC_SumUnique_V6.bas')
)

$ErrorActionPreference = 'Stop'
$taskModule = (Resolve-Path -LiteralPath $ModulePath).Path
$taskCountModule = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\A_FUNC_CountUnique_V6.bas')).Path
$taskTests = Join-Path $PSScriptRoot 'Test_SumUnique_V6.bas'
$taskExcel = $null
$taskBook = $null
$taskSheet = $null
$taskExitCode = 1

try {
    $taskExcel = New-Object -ComObject Excel.Application
    $taskExcel.Visible = $false
    $taskExcel.DisplayAlerts = $false
    $taskExcel.EnableEvents = $false
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import($taskModule) | Out-Null
    $taskSheet = $taskBook.Worksheets.Item(1)
    $taskSheet.Range('A1:A2').Value2 = 'R'
    $taskSheet.Range('B1:B2').Value2 = 'A'
    $taskSheet.Range('C1').Value2 = 2.0
    $taskSheet.Range('C2').Value2 = 3.0
    $taskSheet.Range('E1').Formula2 = '=SUMUNIQUE_V6("Standalone",1,C1:C2,A1:A2,0,B1:B2,0)'
    $taskSheet.Calculate()
    $taskStandalonePassed = ($taskSheet.Range('F3').Value2 -eq 5.0)
    if (-not $taskStandalonePassed) { throw 'Standalone SUM module failed its worksheet formula test.' }
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskSheet) | Out-Null
    $taskSheet = $null
    $taskBook.Close($false) | Out-Null
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskBook) | Out-Null
    $taskBook = $null
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import($taskCountModule) | Out-Null
    $taskBook.VBProject.VBComponents.Import($taskModule) | Out-Null
    $taskBook.VBProject.VBComponents.Import($taskTests) | Out-Null
    $taskResult = $taskExcel.Run("'$($taskBook.Name)'!RunSumUniqueV6Tests")
    [PSCustomObject]@{
        ExcelVersion = $taskExcel.Version
        Module = $taskModule
        StandaloneWorksheetFormula = $taskStandalonePassed
        Result = [string]$taskResult
    } | ConvertTo-Json -Depth 3
    if ([string]$taskResult -like 'PASS:*') { $taskExitCode = 0 }
}
catch {
    Write-Error $_
}
finally {
    if ($null -ne $taskSheet) {
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskSheet) | Out-Null
    }
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
