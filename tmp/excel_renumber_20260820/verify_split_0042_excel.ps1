$ErrorActionPreference = 'Stop'
$workbookPath = 'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx'
$expected = @{
    '0071' = 4910
    '0072' = 3451.5
    '0073' = 4830
    '0074' = 4830
}
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $null
try {
    $workbook = $excel.Workbooks.Open($workbookPath, 0, $true)
    $source = $workbook.Worksheets.Item('0042')
    $results = foreach ($number in $expected.Keys | Sort-Object) {
        $sheet = $workbook.Worksheets.Item($number)
        if ($sheet.Range('T1').Text -ne "IT3-M3-2026-$number") { throw "T1 mismatch: $number" }
        if ([math]::Abs([double]$sheet.Range('V28').Value2 - [double]$expected[$number]) -gt 0.001) { throw "V28 mismatch: $number" }
        if ([double]$sheet.Range('V28').Value2 -ge 5000) { throw "V28 is not below 5000: $number" }
        if ($sheet.PageSetup.Orientation -ne $source.PageSetup.Orientation -or $sheet.PageSetup.Zoom -ne $source.PageSetup.Zoom -or $sheet.PageSetup.FitToPagesWide -ne $source.PageSetup.FitToPagesWide -or $sheet.PageSetup.FitToPagesTall -ne $source.PageSetup.FitToPagesTall) { throw "Page setup mismatch: $number" }
        [pscustomobject]@{ Sheet = $number; T1 = $sheet.Range('T1').Text; V28 = $sheet.Range('V28').Text; PageSetup = 'matched 0042' }
    }
    $results | Format-Table -AutoSize
}
finally {
    if ($workbook) { $workbook.Close($false) }
    $excel.Quit()
    if ($workbook) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) }
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($excel)
}
