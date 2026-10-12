Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap 1700,420
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$headingFont = New-Object System.Drawing.Font('Tahoma',108,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$bodyFont = New-Object System.Drawing.Font('Tahoma',128,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
$graphics.DrawString('หมายเหตุ:', $headingFont, [System.Drawing.Brushes]::Black, 0, 0)
$graphics.DrawString('ติดฟิล์ม ด้านทำสี 1 ด้าน', $bodyFont, [System.Drawing.Brushes]::Black, 0, 170)
$bitmap.Save((Join-Path $PSScriptRoot 'note.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$headingFont.Dispose()
$bodyFont.Dispose()
$bitmap.Dispose()
