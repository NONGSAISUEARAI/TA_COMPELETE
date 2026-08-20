Add-Type -AssemblyName System.Drawing

$source = 'C:\Users\popul\AppData\Local\Temp\codex-clipboard-da9cf6fd-ff75-4c0e-931a-7d73b2ded4ff.png'
$destination = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\signature_ekal_id_no_green_blue.png'

$input = [System.Drawing.Bitmap]::new($source)
$output = [System.Drawing.Bitmap]::new($input.Width, $input.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

for ($y = 0; $y -lt $input.Height; $y++) {
    for ($x = 0; $x -lt $input.Width; $x++) {
        $pixel = $input.GetPixel($x, $y)
        $hue = $pixel.GetHue()
        $saturation = $pixel.GetSaturation()
        $brightness = $pixel.GetBrightness()

        # Light green, cyan, blue, and blue-violet background colors only.
        if ($pixel.A -gt 0 -and $saturation -gt 0.06 -and $brightness -gt 0.55 -and $hue -ge 70 -and $hue -le 330) {
            $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 255, 255, 255))
        } else {
            $output.SetPixel($x, $y, $pixel)
        }
    }
}

$output.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()
$input.Dispose()
