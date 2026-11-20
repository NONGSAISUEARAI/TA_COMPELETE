$ErrorActionPreference='Stop'
$file=Get-ChildItem -LiteralPath '.\outputs\rfq_26106' -Filter 'BU2-DE-26106*.xlsx' | Select-Object -ExpandProperty FullName
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$false
$excel.DisplayAlerts=$false
$excel.AutomationSecurity=3
try {
 $book=$excel.Workbooks.Open($file,0,$false)
 $sheet=$book.Worksheets.Item('1')
 if($sheet.Range('W7:W22').Value2.Count -ne 16){throw 'Unexpected count'}
 $sum=0; for($r=7;$r -le 22;$r++){$sum+=$sheet.Range("W$r").Value2}
 if($sum -ne 3278){throw 'Quantity mismatch'}
 $sheet.Calculate()
 $book.Save()
 $sheet.ExportAsFixedFormat(0,[IO.Path]::ChangeExtension($file,'.pdf'))
 Write-Output "ITEMS=16 TOTAL=$sum PDF_EXPORTED"
 $book.Close($false)
} finally {$excel.Quit()}
