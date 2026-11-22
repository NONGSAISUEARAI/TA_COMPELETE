$ErrorActionPreference='Stop'
$rfqRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$rfqExcel=$null
$rfqOwned=$false
try {
  $rfqExcel=New-Object -ComObject Excel.Application
  if ($rfqExcel.Workbooks.Count -ne 0) { throw 'Existing Excel instance detected' }
  $rfqOwned=$true
  $rfqExcel.DisplayAlerts=$false
  $rfqExcel.Visible=$false
  $rfqExcel.EnableEvents=$false
  $rfqExcel.AutomationSecurity=3
  foreach ($rfqPath in @((Join-Path $PSScriptRoot 'native-no-unchecked.xlsx'))) {
    try {
      $rfqBook=$rfqExcel.Workbooks.Open($rfqPath,0,$true)
      Write-Output ('OPENED: '+(Split-Path $rfqPath -Leaf)+' sheets='+$rfqBook.Worksheets.Count)
      $rfqBook.Close($false)
      [void][Runtime.InteropServices.Marshal]::ReleaseComObject($rfqBook)
    } catch { Write-Output ('FAILED: '+(Split-Path $rfqPath -Leaf)+' '+$_.Exception.Message) }
  }
}
finally {
  if ($rfqExcel -and $rfqOwned) { $rfqExcel.Quit() }
  if ($rfqExcel) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($rfqExcel) }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
