$ErrorActionPreference = 'Stop'

$workbookPath = 'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx'
$backupPath = 'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy_before_split_0042_2026-08-20.xlsx'
$plans = @(
    @{ Number = '0071'; Rows = @(@{ Source = 9 }, @{ Source = 12 }, @{ Source = 13 }, @{ Source = 14 }, @{ Source = 15 }, @{ Source = 16 }, @{ Source = 17 }); Total = 4910 },
    @{ Number = '0072'; Rows = @(@{ Source = 11 }, @{ Source = 18 }, @{ Source = 19 }); Total = 3451.5 },
    @{ Number = '0073'; Rows = @(@{ Source = 10; Quantity = 7 }); Total = 4830 },
    @{ Number = '0074'; Rows = @(@{ Source = 10; Quantity = 7 }); Total = 4830 }
)

$excel = $null
$workbook = $null
$completed = $false
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $workbook = $excel.Workbooks.Open($workbookPath, 0, $false)

    foreach ($plan in $plans) {
        $exists = $true
        try { $null = $workbook.Worksheets.Item($plan.Number) } catch { $exists = $false }
        if ($exists) { $workbook.Worksheets.Item($plan.Number).Delete() }
    }
    if (-not (Test-Path -LiteralPath $backupPath)) { $workbook.SaveCopyAs($backupPath) }

    $source = $workbook.Worksheets.Item('0042')
    foreach ($plan in $plans) {
        $source.Copy([Type]::Missing, $workbook.Worksheets.Item($workbook.Worksheets.Count))
        $target = $workbook.ActiveSheet
        $target.Name = $plan.Number
        $target.Range('A9:AW22').ClearContents()

        $destinationRow = 9
        foreach ($item in $plan.Rows) {
            $source.Range("A$($item.Source):AW$($item.Source)").Copy($target.Range("A$destinationRow"))
            if ($item.ContainsKey('Quantity')) { $target.Range("R$destinationRow").Value2 = $item.Quantity }
            $destinationRow++
        }
        $target.Range('T1').Value2 = "IT3-M3-2026-$($plan.Number)"
        $target.Range('V28').Formula = "=$($plan.Total.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
        $target.Range('V28').NumberFormat = '#,### "B"'
    }

    $excel.CalculateFull()
    foreach ($plan in $plans) {
        $sheet = $workbook.Worksheets.Item($plan.Number)
        if ($sheet.Range('T1').Text -ne "IT3-M3-2026-$($plan.Number)") { throw "T1 verification failed for $($plan.Number)" }
        if ([math]::Abs([double]$sheet.Range('V28').Value2 - [double]$plan.Total) -gt 0.001) { throw "V28 verification failed for $($plan.Number)" }
        if ([double]$sheet.Range('V28').Value2 -ge 5000) { throw "Total is not below 5000 for $($plan.Number)" }
    }
    $workbook.Save()
    $completed = $true
    $plans | ForEach-Object { [pscustomobject]@{ Sheet = $_.Number; T1 = $workbook.Worksheets.Item($_.Number).Range('T1').Text; V28 = $workbook.Worksheets.Item($_.Number).Range('V28').Text } } | Format-Table -AutoSize
}
finally {
    if ($workbook) { $workbook.Close($completed) }
    if ($excel) { $excel.Quit() }
    if ($workbook) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) }
    if ($excel) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($excel) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
