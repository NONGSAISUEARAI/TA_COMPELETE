$ErrorActionPreference = 'Stop'
$xlsxPath = 'C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา\outputs\rfq_preview_2pages_20261006\RFQ_HK_MEP_ตัวอย่าง_2หน้า_40รายการ.xlsx'
$pdfPath = 'C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา\outputs\rfq_preview_2pages_20261006\print_check.pdf'
$excelApp = $null
$book = $null
try {
    $excelApp = New-Object -ComObject Excel.Application
    $excelApp.Visible = $false
    $excelApp.DisplayAlerts = $false
    $excelApp.AutomationSecurity = 3
    $book = $excelApp.Workbooks.Open($xlsxPath, 0, $true)
    $book.ExportAsFixedFormat(0, $pdfPath)
    Write-Output $pdfPath
}
finally {
    if ($book -ne $null) {
        $book.Close($false)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($book)
    }
    if ($excelApp -ne $null) {
        $excelApp.Quit()
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excelApp)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
