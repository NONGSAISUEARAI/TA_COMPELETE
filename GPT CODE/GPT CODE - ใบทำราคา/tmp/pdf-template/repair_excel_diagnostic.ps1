$ErrorActionPreference='Stop'
$rfqExcel=$null
$rfqBook=$null
$rfqOwned=$false
try {
  $rfqExcel=New-Object -ComObject Excel.Application
  if ($rfqExcel.Workbooks.Count -ne 0) { throw 'Existing Excel instance detected' }
  $rfqOwned=$true
  $rfqExcel.DisplayAlerts=$false
  $rfqExcel.Visible=$false
  $rfqExcel.EnableEvents=$false
  $rfqExcel.AutomationSecurity=3
  $rfqBook=$rfqExcel.Workbooks.Open((Join-Path $PSScriptRoot 'native-qa.xlsx'),0,$true,5,'','',$true,2,'',$false,$false,0,$false,$true,1)
  Write-Output ('Repair opened sheets='+$rfqBook.Worksheets.Count)
  $rfqBook.SaveAs((Join-Path $PSScriptRoot 'native-qa-repaired.xlsx'),51)
}
finally {
  if ($rfqBook) { $rfqBook.Close($false);[void][Runtime.InteropServices.Marshal]::ReleaseComObject($rfqBook) }
  if ($rfqExcel -and $rfqOwned) { $rfqExcel.Quit() }
  if ($rfqExcel) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($rfqExcel) }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
