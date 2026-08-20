Add-Type -AssemblyName System.Drawing

$source = 'C:\Users\popul\AppData\Local\Temp\codex-clipboard-5820e485-8152-4fb1-ab60-ed2d9f2fe294.png'
$destination = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\signature_vudhichai_with_text.png'

$input = [System.Drawing.Bitmap]::new($source)
$output = [System.Drawing.Bitmap]::new($input.Width, $input.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

for ($y = 0; $y -lt $input.Height; $y++) {
    for ($x = 0; $x -lt $input.Width; $x++) {
        $pixel = $input.GetPixel($x, $y)
        $isWhiteBackground = $pixel.R -ge 248 -and $pixel.G -ge 248 -and $pixel.B -ge 248
        $isTableLine = ($x -ge 1308 -and $x -le 1324) -or ($x -ge 1376 -and $x -le 1384) -or ($y -ge 524 -and $y -le 533)

        if ($isWhiteBackground -or $isTableLine) {
            $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 255, 255, 255))
        } else {
            $output.SetPixel($x, $y, $pixel)
        }
    }
}

$output.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()
$input.Dispose()
