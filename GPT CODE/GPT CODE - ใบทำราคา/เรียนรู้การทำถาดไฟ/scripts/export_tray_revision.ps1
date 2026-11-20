$ErrorActionPreference='Stop'
$file=Get-ChildItem -LiteralPath '.\outputs\rfq_26106_rev01' -Filter '*.xlsm' | Select-Object -ExpandProperty FullName
$excel=New-Object -ComObject Excel.Application
$excel.Visible=$false
$excel.DisplayAlerts=$false
$excel.AutomationSecurity=3
try {
 $book=$excel.Workbooks.Open($file,0,$false)
 $sum=0;$count=0
 foreach($sheet in $book.Worksheets){
  $sheet.Unprotect()
  $checkIndex=0
  foreach($cb in $sheet.CheckBoxes()){
   $checkIndex++
   if($checkIndex -in @(2,3,7)){$cb.Value=1}else{$cb.Value=0}
   $caption=([string]$cb.Caption).Trim()
   if($caption -match 'ฝ้าเพดาน|ภายในอาคาร|เพื่อผลิต'){$cb.Value=1}
   elseif($caption -match 'แผงบังแดด|ผนังหน้าอาคาร|ภายนอกอาคาร|อื่น|เพื่อเสนอราคา'){$cb.Value=-4146}
  }
  for($r=7;$r -le 26;$r++){
   if($sheet.Range("A$r").Value2){$sum+=$sheet.Range("W$r").Value2;$count++}
   $sheet.Range("B${r}:D${r}").WrapText=$true
   $sheet.Range("B${r}:D${r}").Font.Size=8
   $sheet.Rows.Item($r).RowHeight=32
  }
  $sheet.Calculate()
 }
 if($sum -ne 259 -or $count -ne 27){throw "Mismatch $count $sum"}
 $book.Save()
 $book.ExportAsFixedFormat(0,[IO.Path]::ChangeExtension($file,'.pdf'))
 $book.Close($false)
 Write-Output "CHECKED ITEMS=$count TOTAL=$sum"
} finally {$excel.Quit()}
