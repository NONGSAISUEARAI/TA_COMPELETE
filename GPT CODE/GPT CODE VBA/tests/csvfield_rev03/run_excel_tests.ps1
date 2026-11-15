$ErrorActionPreference = 'Stop'
$taskExcel = $null
$taskBook = $null
$taskExitCode = 1
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
try {
    $taskExcel = New-Object -ComObject Excel.Application
    $taskExcel.Visible = $false
    $taskExcel.DisplayAlerts = $false
    $taskExcel.EnableEvents = $false
    $taskBook = $taskExcel.Workbooks.Add()
    $taskBook.VBProject.VBComponents.Import((Join-Path $taskRoot 'A_FUNC_CSVFIELD_REV03.bas')) | Out-Null
    $taskBaseline = [System.IO.File]::ReadAllText((Join-Path $taskRoot 'A_FUNC_CSVFIELD_REV02.bas'))
    $taskBaseline = [regex]::Replace($taskBaseline, '(?m)^Attribute VB_Name.*\r?\n', '')
    $taskBaseline = [regex]::Replace($taskBaseline, '\bCSVFIELD\b', 'CSVFIELD_BASELINE')
    $taskComponent = $taskBook.VBProject.VBComponents.Add(1)
    $taskComponent.Name = 'CSVFIELD_REV02_BASELINE'
    $taskComponent.CodeModule.AddFromString($taskBaseline)
    $taskBook.VBProject.VBComponents.Import((Join-Path $PSScriptRoot 'Test_CSVFIELD_REV03.bas')) | Out-Null
    $taskResult = [string]$taskExcel.Run("'$($taskBook.Name)'!RunCsvFieldRev03Tests")
    [PSCustomObject]@{ ExcelVersion=$taskExcel.Version; Result=$taskResult } | ConvertTo-Json
    if ($taskResult.StartsWith('PASS:')) { $taskExitCode = 0 }
}
finally {
    if ($null -ne $taskBook) { $taskBook.Close($false) | Out-Null }
    if ($null -ne $taskExcel) { $taskExcel.Quit() }
    foreach ($taskObject in @($taskComponent, $taskBook, $taskExcel)) {
        if ($null -ne $taskObject) { [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskObject) | Out-Null }
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
exit $taskExitCode
