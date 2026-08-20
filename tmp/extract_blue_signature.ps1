Add-Type -AssemblyName System.Drawing

$source = 'C:\Users\popul\AppData\Local\Temp\codex-clipboard-5820e485-8152-4fb1-ab60-ed2d9f2fe294.png'
$destination = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\signature_vudhichai_blue.png'

$input = [System.Drawing.Bitmap]::new($source)
$output = [System.Drawing.Bitmap]::new($input.Width, $input.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

for ($y = 0; $y -lt $input.Height; $y++) {
    for ($x = 0; $x -lt $input.Width; $x++) {
        $pixel = $input.GetPixel($x, $y)
        $hue = $pixel.GetHue()
        $saturation = $pixel.GetSaturation()
        $brightness = $pixel.GetBrightness()

        # Retain saturated blue ink; remove white, black text, and table rules.
        if ($pixel.A -gt 0 -and $hue -ge 190 -and $hue -le 260 -and $saturation -ge 0.45 -and $brightness -ge 0.2) {
            $output.SetPixel($x, $y, $pixel)
        } else {
            $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 255, 255, 255))
        }
    }
}

$crop = [System.Drawing.Rectangle]::new(0, 280, 610, 155)
$trimmed = $output.Clone($crop, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$trimmed.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
$trimmed.Dispose()
$output.Dispose()
$input.Dispose()
