$ErrorActionPreference = 'Stop'
$taskExcel = $null
$taskBook = $null
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$taskExitCode = 1
try {
    $taskExcel = New-Object -ComObject Excel.Application
    $taskExcel.Visible = $false
    $taskExcel.DisplayAlerts = $false
    $taskExcel.EnableEvents = $false

    # V0 must run standalone and retain the entire original test suite.
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import((Join-Path $taskRoot 'A_FUNC_CUTTING_LIST_V0.bas')) | Out-Null
    $taskTestSource = [System.IO.File]::ReadAllText((Join-Path $taskRoot 'tests\cutting_list\Test_CUTTING_LIST.bas'))
    $taskTestSource = [regex]::Replace($taskTestSource, '(?m)^Attribute VB_Name.*\r?\n', '')
    $taskTestSource = [regex]::Replace($taskTestSource, '\bCUTTING_LIST\b', 'CUTTING_LIST_V0')
    $taskComponent = $taskBook.VBProject.VBComponents.Add(1)
    $taskComponent.Name = 'Test_V0_Regression'
    $taskComponent.CodeModule.AddFromString($taskTestSource)
    $taskV0Result = [string]$taskExcel.Run("'$($taskBook.Name)'!RunCuttingListTests")
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskComponent) | Out-Null
    $taskComponent = $null
    $taskBook.Close($false) | Out-Null
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskBook) | Out-Null
    $taskBook = $null

    # V1 must also work without importing the original or V0 module.
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import((Join-Path $taskRoot 'A_FUNC_CUTTING_LIST_V1.bas')) | Out-Null
    $taskComponent = $taskBook.VBProject.VBComponents.Add(1)
    $taskComponent.Name = 'Test_V1_Standalone'
    $taskComponent.CodeModule.AddFromString(@'
Public Function TestV1Standalone() As Boolean
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets(1)
    ws.Range("B1").Value2 = "PP17"
    ws.Range("C1").Value2 = "PP18"
    ws.Range("B2:C2").Value2 = "M1"
    ws.Range("A3").Value2 = 2200
    ws.Range("B3:C3").Value2 = 1
    ws.Range("G1").Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3)"
    ws.Calculate
    TestV1Standalone = (ws.Range("G1").Value2 = "SUMMARY REPORT" And ws.Range("H5").Value2 = 2)
End Function
'@)
    $taskStandalone = [bool]$taskExcel.Run("'$($taskBook.Name)'!TestV1Standalone")
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskComponent) | Out-Null
    $taskComponent = $null
    $taskBook.Close($false) | Out-Null
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskBook) | Out-Null
    $taskBook = $null

    # All three function names must coexist in one workbook.
    $taskBook = $taskExcel.Workbooks.Add()
    foreach ($taskName in @('A_FUNC_CUTTING_LIST.bas', 'A_FUNC_CUTTING_LIST_V0.bas', 'A_FUNC_CUTTING_LIST_V1.bas')) {
        $taskBook.VBProject.VBComponents.Import((Join-Path $taskRoot $taskName)) | Out-Null
    }
    $taskBook.VBProject.VBComponents.Import((Join-Path $PSScriptRoot 'Test_CuttingVersions.bas')) | Out-Null
    $taskVersionResult = [string]$taskExcel.Run("'$($taskBook.Name)'!RunCuttingVersionTests")
    [PSCustomObject]@{
        ExcelVersion = $taskExcel.Version
        V0Regression = $taskV0Result
        V1StandaloneWorksheetFormula = $taskStandalone
        Versions = $taskVersionResult
    } | ConvertTo-Json
    if ($taskV0Result.StartsWith('PASS:') -and $taskStandalone -and $taskVersionResult.StartsWith('PASS:')) {
        $taskExitCode = 0
    }
}
catch {
    Write-Output ([PSCustomObject]@{ Result='ERROR'; Message=$_.Exception.Message } | ConvertTo-Json)
}
finally {
    if ($null -ne $taskBook) { $taskBook.Close($false) | Out-Null }
    if ($null -ne $taskExcel) { $taskExcel.Quit() }
    foreach ($taskObject in @($taskComponent, $taskBook, $taskExcel)) {
        if ($null -ne $taskObject) {
            [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskObject) | Out-Null
        }
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
exit $taskExitCode
