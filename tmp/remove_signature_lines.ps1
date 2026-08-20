Add-Type -AssemblyName System.Drawing

$source = 'C:\Users\popul\AppData\Local\Temp\codex-clipboard-4053a87b-8030-488b-a0fb-a189ae89e67b.png'
$destination = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\digital_signature_vudhichai_no_lines.png'

$input = [System.Drawing.Bitmap]::new($source)
$output = [System.Drawing.Bitmap]::new($input.Width, $input.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

for ($y = 0; $y -lt $input.Height; $y++) {
    for ($x = 0; $x -lt $input.Width; $x++) {
        $output.SetPixel($x, $y, $input.GetPixel($x, $y))
    }
}

# Full-length border rules detected in this source image.
for ($x = 331; $x -le 335; $x++) {
    for ($y = 0; $y -lt $input.Height; $y++) { $output.SetPixel($x, $y, [System.Drawing.Color]::White) }
}
for ($y = 151; $y -le 156; $y++) {
    for ($x = 0; $x -lt $input.Width; $x++) { $output.SetPixel($x, $y, [System.Drawing.Color]::White) }
}

$output.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()
$input.Dispose()
