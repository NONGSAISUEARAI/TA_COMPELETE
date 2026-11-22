$ErrorActionPreference='Stop'
$rfqRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$rfqReport=Get-Content -LiteralPath (Join-Path $rfqRoot 'outputs\rfq_26106_from_template\excel-export-verification.json') -Raw | ConvertFrom-Json
$rfqExcel=$null
$rfqBook=$null
$rfqOwnInstance=$false
try {
  $rfqExcel=New-Object -ComObject Excel.Application
  if ($rfqExcel.Workbooks.Count -ne 0) { throw 'Expected a separate empty Excel instance; left the existing application untouched.' }
  $rfqOwnInstance=$true
  $rfqExcel.Visible=$false
  $rfqExcel.DisplayAlerts=$false
  $rfqExcel.EnableEvents=$false
  $rfqExcel.AskToUpdateLinks=$false
  $rfqExcel.AutomationSecurity=3
  $rfqBook=$rfqExcel.Workbooks.Open((Join-Path $PSScriptRoot 'native-qa.xlsx'),0,$true)
  if ($rfqBook.Worksheets.Count -ne 2) { throw 'Unexpected worksheet count' }
  $rfqExcel.CalculateFullRebuild()
  $rfqChecks=@()
  $rfqTotal=0
  $rfqExpected=@(-4146,1,1,-4146,1,-4146,-4146,-4146)
  for ($rfqPage=1; $rfqPage -le 2; $rfqPage++) {
    $rfqSheet=$rfqBook.Worksheets.Item($rfqPage)
    $rfqBoxes=$rfqSheet.CheckBoxes()
    if ($rfqBoxes.Count -ne 8) { throw "Native checkboxes missing on page $rfqPage" }
    $rfqValues=@()
    for ($rfqIndex=1; $rfqIndex -le 8; $rfqIndex++) { $rfqValues += [int]$rfqBoxes.Item($rfqIndex).Value }
    if (($rfqValues -join ',') -ne ($rfqExpected -join ',')) { throw "Checkbox states differ on page $rfqPage" }
    $rfqTotal += [double]$rfqExcel.WorksheetFunction.Sum($rfqSheet.Range('W7:W26'))
    if ($rfqSheet.Range('G7').Value2 -ne 'Alu.sheet, MF') { throw 'Material formula did not calculate' }
    $rfqChecks += [ordered]@{sheet=$rfqSheet.Name;checkboxes=$rfqBoxes.Count;states=$rfqValues;pageNumber=$rfqSheet.Range('Z45').Text;printArea=$rfqSheet.PageSetup.PrintArea}
  }
  if ($rfqTotal -ne 462) { throw 'Native quantity total differs' }
  $rfqFirst=$rfqBook.Worksheets.Item(1)
  $rfqFirst.Range('E7').Value2=[double]2
  $rfqExcel.CalculateFullRebuild()
  if ($rfqFirst.Range('G7').Value2 -ne 'Alu.coil, MF') { throw 'Material lookup is a stale cache' }
  $rfqFirst.Range('E7').Value2=[double]1
  $rfqExcel.CalculateFullRebuild()
  $rfqBook.ExportAsFixedFormat(0,(Join-Path $PSScriptRoot 'excel-native-preview.pdf'))
  [ordered]@{openedInExcel=$true;readOnly=$rfqBook.ReadOnly;worksheets=2;quantity=$rfqTotal;liveMaterialLookup=$true;nativeControls=$rfqChecks;pdfPreview='excel-native-preview.pdf'} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'excel-native-verification.json') -Encoding utf8
  Write-Output 'PASS: Excel opened the export, calculated 462 pieces, retained 8 checkboxes per sheet, and updated the material name after changing its code.'
}
finally {
  if ($null -ne $rfqBook) { $rfqBook.Close($false); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($rfqBook) }
  if ($null -ne $rfqExcel) {
    if ($rfqOwnInstance) { $rfqExcel.Quit() }
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($rfqExcel)
  }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
