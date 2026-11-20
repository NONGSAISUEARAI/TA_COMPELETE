$ErrorActionPreference='Stop'
$folder=Join-Path (Split-Path $PSScriptRoot -Parent) 'outputs\rfq_26106_corrected'
$file=Get-ChildItem -LiteralPath $folder -Filter '*.xlsm' | Where-Object Name -NotLike '*.before_unicode_fix.xlsm' | Select-Object -ExpandProperty FullName
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$false;$excel.DisplayAlerts=$false;$excel.AutomationSecurity=3
try {
 $book=$excel.Workbooks.Open($file,0,$false)
 $count=0;$sum=0;$codes=@()
 foreach($sheet in $book.Worksheets){
  if($sheet.Range('Z2').Value2 -ne 'PJ25-031'){throw 'JO mismatch'}
  for($r=7;$r -le 26;$r++){
   if($sheet.Range("A$r").Value2){
    $count++;$sum+=$sheet.Range("W$r").Value2
    if($sheet.Range("K$r").Value2 -ne 249){throw 'Width mismatch'}
    $name=[string]$sheet.Range("B$r").Value2
    if($name -notmatch '249x\((\d+)\+(\d+)\)mm\. L=(\d+)mm\.'){throw 'Part name invalid'}
    if(([int]$Matches[1]+[int]$Matches[2]) -ne [int]$Matches[3]){throw 'Length mismatch'}
    if($sheet.Range("M$r").Value2 -ne [int]$Matches[3]){throw 'Cell length mismatch'}
    if($name -notmatch '\(PJ25-031AL-TRAY-LT-VA-(\d{2})\)'){throw 'Part code invalid'}
    $codes+=$Matches[1]
   }
   $sheet.Range("B${r}:D${r}").WrapText=$true
   $sheet.Range("B${r}:D${r}").Font.Size=9
   $sheet.Rows.Item($r).RowHeight=30
   $sheet.Range("Z$r").WrapText=$true
  }
  $sheet.Calculate()
 }
 if($count -ne 27 -or $sum -ne 259 -or ($codes | Select-Object -Unique).Count -ne 27){throw 'Totals or codes mismatch'}
 $book.Save()
 $book.ExportAsFixedFormat(0,[IO.Path]::ChangeExtension($file,'.pdf'))
 $book.Close($false)
 Write-Output "VERIFIED $count ITEMS $sum PCS; UNIQUE CODES; WIDTH=249; LENGTH=W1+W2"
} finally {$excel.Quit()}
