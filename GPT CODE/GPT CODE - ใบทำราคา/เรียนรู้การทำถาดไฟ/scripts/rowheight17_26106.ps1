$ErrorActionPreference='Stop'
$base=Join-Path (Split-Path $PSScriptRoot -Parent) 'outputs'
$src=Get-ChildItem -LiteralPath (Join-Path $base 'rfq_26106_final') -Filter '*.xlsm' | Select-Object -ExpandProperty FullName
$dir=Join-Path $base 'rfq_26106_height17_ready'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$dest=Join-Path $dir ([IO.Path]::GetFileName($src))
if(Test-Path -LiteralPath $dest){throw 'Destination exists'}
$app=New-Object -ComObject Excel.Application
$app.Visible=$false;$app.DisplayAlerts=$false;$app.AutomationSecurity=3
try {
 $book=$app.Workbooks.Open($src,0,$true)
 foreach($sheet in $book.Worksheets){
  $sheet.Rows.Item('7:26').RowHeight=17
  for($r=7;$r -le 26;$r++){
   $z=$sheet.Range("Z$r")
   if($z.Value2){$z.Value2=([string]$z.Value2).Replace("`r",'').Replace("`n",' ')}
   $z.WrapText=$false;$z.ShrinkToFit=$true
  }
 }
 $book.SaveAs($dest,52)
 $book.ExportAsFixedFormat(0,[IO.Path]::ChangeExtension($dest,'.pdf'))
 $book.Close($false)
 Write-Output 'SAVED ALL 20 ITEM ROWS PER PAGE AT 17 PT'
}finally{$app.Quit()}
