Add-Type -AssemblyName System.Drawing

function Remove-BorderLines {
    param(
        [string]$Path,
        [int]$RightLineStart = -1,
        [int]$BottomLineStart = -1
    )

    $source = [System.Drawing.Bitmap]::new($Path)
    $result = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($result)
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.DrawImageUnscaled($source, 0, 0)
    if ($RightLineStart -ge 0) {
        $graphics.FillRectangle([System.Drawing.Brushes]::White, $RightLineStart, 0, $result.Width - $RightLineStart, $result.Height)
    }
    if ($BottomLineStart -ge 0) {
        $graphics.FillRectangle([System.Drawing.Brushes]::White, 0, $BottomLineStart, $result.Width, $result.Height - $BottomLineStart)
    }
    $graphics.Dispose()
    $source.Dispose()
    $result.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $result.Dispose()
}

$folder = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE'
Remove-BorderLines -Path (Join-Path $folder 'signature_ekal_id_from_pdf.png') -BottomLineStart 105
Remove-BorderLines -Path (Join-Path $folder 'signature_vudhichai_from_pdf.png') -RightLineStart 85
