$ErrorActionPreference='Stop'
$dir=(Resolve-Path -LiteralPath '.\outputs\rfq_26106_rev01').Path
$old='BU2-DE-26106_REV01_โครงการ MRT PURPLE LINE 4 STATION (PP17 - PP20) (แผ่นไฟ VA ยาว ซ้ายขวาไม่เท่า แบบตรง)'
$new=$old.Replace('26106_REV01','26106')
$src=Join-Path $dir ($old+'.xlsm')
$dest=Join-Path $dir ($new+'.xlsm')
$pdf=Join-Path $dir ($new+'.pdf')
if((Test-Path -LiteralPath $dest) -or (Test-Path -LiteralPath $pdf)){throw 'Destination exists'}
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$false;$excel.DisplayAlerts=$false;$excel.AutomationSecurity=3
try {
 $book=$excel.Workbooks.Open($src,0,$false)
 foreach($sheet in $book.Worksheets){$sheet.Range('Z1').Value2='BU2-DE-26106'}
 $book.SaveAs($dest,52)
 $book.ExportAsFixedFormat(0,$pdf)
 $book.Close($false)
 Write-Output 'SAVED HEADER WITHOUT REV; EXCEL AND PDF'
} finally {$excel.Quit()}
