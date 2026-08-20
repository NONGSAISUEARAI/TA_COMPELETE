Add-Type -AssemblyName System.Drawing

$source = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\digital_signature_ekal_id.png'
$destination = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\digital_signature_ekal_id_no_green_blue.png'

$input = [System.Drawing.Bitmap]::new($source)
$output = [System.Drawing.Bitmap]::new($input.Width, $input.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

for ($y = 0; $y -lt $input.Height; $y++) {
    for ($x = 0; $x -lt $input.Width; $x++) {
        $pixel = $input.GetPixel($x, $y)
        $hue = $pixel.GetHue()
        $saturation = $pixel.GetSaturation()
        $brightness = $pixel.GetBrightness()

        # Remove all light green, blue, and blue-violet background tones; preserve dark text.
        if ($pixel.A -gt 0 -and $saturation -gt 0.08 -and $brightness -gt 0.45 -and $hue -ge 75 -and $hue -le 330) {
            $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 255, 255, 255))
        } else {
            $output.SetPixel($x, $y, $pixel)
        }
    }
}

$output.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()
$input.Dispose()
