$ErrorActionPreference='Stop'
$dir=Join-Path (Split-Path $PSScriptRoot -Parent) 'outputs\rfq_26106_corrected'
$file=Get-ChildItem -LiteralPath $dir -Filter '*.xlsm' | Where-Object Name -NotLike '*.before_unicode_fix.xlsm' | Select-Object -ExpandProperty FullName
$backup=Join-Path $dir 'history_before_no_wrap'
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item -LiteralPath $file -Destination $backup
$pdf=[IO.Path]::ChangeExtension($file,'.pdf')
Copy-Item -LiteralPath $pdf -Destination $backup
$app=New-Object -ComObject Excel.Application
$app.Visible=$false;$app.DisplayAlerts=$false;$app.AutomationSecurity=3
try {
 $book=$app.Workbooks.Open($file,0,$false)
 $count=0;$sum=0
 foreach($sheet in $book.Worksheets){
  for($r=7;$r -le 26;$r++){
   $sheet.Range("J$r").ClearContents()
   $cell=$sheet.Range("B${r}:D${r}")
   if($sheet.Range("A$r").Value2){
    $count++;$sum+=$sheet.Range("W$r").Value2
    $sheet.Range("B$r").Value2=([string]$sheet.Range("B$r").Value2).Replace("`r",'').Replace("`n",' ')
   }
   $cell.WrapText=$false
   $cell.Font.Size=9
   $cell.ShrinkToFit=$true
  }
  $sheet.Calculate()
 }
 if($count -ne 27 -or $sum -ne 259){throw 'Quantity mismatch'}
 $finalDir=Join-Path (Split-Path $dir -Parent) 'rfq_26106_final'
 New-Item -ItemType Directory -Path $finalDir -Force | Out-Null
 $finalFile=Join-Path $finalDir ([IO.Path]::GetFileName($file))
 if(Test-Path -LiteralPath $finalFile){throw 'Final file already exists'}
 $book.SaveAs($finalFile,52)
 $book.ExportAsFixedFormat(0,[IO.Path]::ChangeExtension($finalFile,'.pdf'))
 $book.Close($false)
 Write-Output 'VERIFIED 27 ITEMS 259 PCS; J BLANK; NO WRAP; SHRINK TO FIT'
}finally{$app.Quit()}
