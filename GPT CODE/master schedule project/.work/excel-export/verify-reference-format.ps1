$ErrorActionPreference = 'Stop'
$formatExcel = $null
$formatSource = $null
$formatOutput = $null
try {
    $formatExcel = New-Object -ComObject Excel.Application
    $formatExcel.Visible = $false
    $formatExcel.DisplayAlerts = $false
    $formatExcel.EnableEvents = $false
    $formatExcel.AutomationSecurity = 3
    $formatSource = $formatExcel.Workbooks.Open([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Program & Actual Drawing Schedul By Tawan 09-11-26.xlsx')),0,$true)
    $formatOutput = $formatExcel.Workbooks.Open([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../outputs/master-schedule-export/Master_Schedule_Rev02_2026-10-30.xlsx')),0,$true)
    $sourceSheet = $formatSource.Worksheets.Item('Programm Database')
    $outputSheet = $formatOutput.Worksheets.Item('Programm Database')
    $checks = 0
    foreach ($pair in @(@('A4','A4'),@('E4','E4'),@('L4','L4'),@('B3','A3'),@('E5','E5'),@('E6','E6'),@('E7','E11'),@('Q3','S3'),@('Q4','S4'))) {
        $beforeCell = $sourceSheet.Range($pair[0]).DisplayFormat
        $afterCell = $outputSheet.Range($pair[1]).DisplayFormat
        foreach ($property in @('Name','Size','Bold','Color')) {
            if ($beforeCell.Font.$property -ne $afterCell.Font.$property) { throw "Font $property differs at $($pair[1])." }
            $checks++
        }
        if ($beforeCell.Interior.Color -ne $afterCell.Interior.Color) { throw "Fill differs at $($pair[1])." }
        $checks++
        foreach ($edge in @(7,8,9,10)) {
            $beforeBorder = $beforeCell.Borders.Item($edge)
            $afterBorder = $afterCell.Borders.Item($edge)
            if ($beforeBorder.LineStyle -ne $afterBorder.LineStyle -or $beforeBorder.Weight -ne $afterBorder.Weight -or $beforeBorder.Color -ne $afterBorder.Color) { throw "Border $edge differs at $($pair[1])." }
            $checks++
        }
    }
    foreach ($column in 1..16) {
        $beforeWidth = $sourceSheet.Cells.Item(4,$column).ColumnWidth
        $afterWidth = $outputSheet.Cells.Item(4,$column).ColumnWidth
        if ([Math]::Abs($beforeWidth-$afterWidth) -gt 0.02) { throw "Column width differs at $column ($beforeWidth / $afterWidth)." }
        $checks++
    }
    if (-not $outputSheet.Rows.Item(1).Hidden -or -not $outputSheet.Rows.Item(2).Hidden) { throw 'Reference hidden title rows differ.' }
    if (-not $outputSheet.Columns.Item(3).Hidden -or -not $outputSheet.Columns.Item(4).Hidden) { throw 'Reference hidden columns differ.' }
    if ($outputSheet.Range('S3').Orientation -ne $sourceSheet.Range('Q3').Orientation) { throw 'Calendar header rotation differs.' }
    Write-Output "PASS: $checks native Excel checks match reference fonts, fills, borders and column widths; hidden rows/columns and rotated calendar dates also match."
} finally {
    if ($formatOutput) { $formatOutput.Close($false) }
    if ($formatSource) { $formatSource.Close($false) }
    if ($formatExcel) { $formatExcel.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($formatExcel) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
