$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$taskSourceFolder = Join-Path $taskRoot 'เรียนรู้การทำถาดไฟ\outputs\rfq_26106_height17_ready'
$taskSourceFile = Get-ChildItem -LiteralPath $taskSourceFolder -Filter '*.xlsm' | Select-Object -First 1 -ExpandProperty FullName
$taskOutputFolder = Join-Path $taskRoot 'outputs\excel26106-html'
New-Item -ItemType Directory -Path $taskOutputFolder -Force | Out-Null
$taskOutputFile = Join-Path $taskOutputFolder 'BU2-DE-26106.html'
$taskSourceHash = (Get-FileHash -LiteralPath $taskSourceFile -Algorithm SHA256).Hash
$taskExcelApp = $null
$taskWorkbook = $null
try {
    $taskExcelApp = New-Object -ComObject Excel.Application
    $taskExcelApp.Visible = $false
    $taskExcelApp.DisplayAlerts = $false
    $taskExcelApp.AutomationSecurity = 3
    $taskExcelApp.AskToUpdateLinks = $false
    $taskExportCopy = Join-Path $PSScriptRoot 'html-export-copy.xlsm'
    $taskWorkbook = $taskExcelApp.Workbooks.Open($taskExportCopy, 0, $true)
    $taskSheets = @()
    foreach ($taskSheet in $taskWorkbook.Worksheets) {
        $taskSheets += [pscustomobject]@{Name=$taskSheet.Name; PrintArea=$taskSheet.PageSetup.PrintArea}
        $taskPageFile = Join-Path $taskOutputFolder ('page' + $taskSheet.Name + '.html')
        $taskPublication = $taskWorkbook.PublishObjects.Add(1, $taskPageFile, $taskSheet.Name, $taskSheet.PageSetup.PrintArea, 0)
        $taskPublication.Publish($true)
    }
    $taskWorkbook.WebOptions.Encoding = 65001
    $taskWorkbook.WebOptions.OrganizeInFolder = $true
    $taskWorkbook.WebOptions.UseLongFileNames = $true
    $taskWorkbook.WebOptions.AllowPNG = $true
    if (-not (Test-Path -LiteralPath $taskOutputFile)) { $taskWorkbook.SaveAs($taskOutputFile, 44) }
    $taskWorkbook.Close($false)
    $taskWorkbook = $null
    if ((Get-FileHash -LiteralPath $taskSourceFile -Algorithm SHA256).Hash -ne $taskSourceHash) { throw 'Source changed unexpectedly' }
    [pscustomobject]@{Output=$taskOutputFile; SourceUnchanged=$true; Sheets=$taskSheets} | ConvertTo-Json -Depth 4
} finally {
    if ($null -ne $taskWorkbook) { $taskWorkbook.Close($false) }
    if ($null -ne $taskExcelApp) { $taskExcelApp.Quit(); [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskExcelApp) }
}
