param(
    [string]$targetFile = 'C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE\outputs\01a0c35e-5086-7442-abfc-18d7347eb1aa\TOTAL_TRAY_REV03_rebuilt.xlsm',
    [switch]$newBlank
)
$ErrorActionPreference = 'Stop'
$excel = $null
$workbook = $null
$stage = 'create Excel instance'

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.EnableEvents = $false
    $excel.AutomationSecurity = 3
    $excel.AskToUpdateLinks = $false
    $stage = 'open workbook'
    if ($newBlank) {
        $workbook = $excel.Workbooks.Add()
    } else {
        $workbook = $excel.Workbooks.Open($targetFile, 0, $true)
    }
    $stage = 'inspect workbook'
    Write-Output ('Opened in Excel: ' + $workbook.FullName)
    Write-Output ('Worksheet count: ' + $workbook.Worksheets.Count)
    Write-Output ('First worksheet: ' + $workbook.Worksheets.Item(1).Name)
    Write-Output ('Last worksheet: ' + $workbook.Worksheets.Item($workbook.Worksheets.Count).Name)
    Write-Output ('Read-only: ' + $workbook.ReadOnly)
}
catch {
    Write-Output ('Failed at ' + $stage + ': ' + $_.Exception.Message)
    throw
}
finally {
    if ($null -ne $workbook) {
        try { $workbook.Close($false) } catch { Write-Output ('Close: ' + $_.Exception.Message) }
        try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($workbook) } catch {}
    }
    if ($null -ne $excel) {
        try { $excel.Quit() } catch { Write-Output ('Quit: ' + $_.Exception.Message) }
        try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel) } catch {}
    }
}
