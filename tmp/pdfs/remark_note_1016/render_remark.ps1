Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap 4000,256
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$remarkFont = New-Object System.Drawing.Font('Cordia New',128,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$graphics.DrawString(': ขนาดที่ไม่ได้กำหนดพิกัดความเผื่อไว้ให้ใช้ค่า ± 3.0mm.', $remarkFont, [System.Drawing.Brushes]::Black, 0, 0)
$bitmap.Save((Join-Path $PSScriptRoot 'remark-uncropped.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$remarkFont.Dispose()
$bitmap.Dispose()
