param([switch]$Apply)

$ErrorActionPreference = 'Stop'
$targetDirectory = 'C:\TA\PPLINE CKST\C1&C2_0121-1 Update (29.01.26) PPedit\IV01\CAD\IV-01_FOR_SEND_20261016\CAD'
$resolvedDirectory = (Resolve-Path -LiteralPath $targetDirectory).Path
if (-not [string]::Equals($resolvedDirectory.TrimEnd('\'), $targetDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'The resolved directory differs from the inspected target.'
}
$expectedHash = '839E02674D9622E409E95EC47554FAA208F26841CC2629B51157EE07FEA53063'
$mappingPath = 'C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE\output\cad_rename_20261016\rename_mapping.csv'
$plan = @(Import-Csv -LiteralPath $mappingPath)
if ($plan.Count -ne 13) { throw 'Expected exactly 13 rename entries.' }
$pdfHashes = @{}

# Complete all checks before renaming the first file.
foreach ($entry in $plan) {
    $oldPath = Join-Path $resolvedDirectory $entry.OldName
    $newPath = Join-Path $resolvedDirectory $entry.NewName
    if ([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($oldPath)) -ne $resolvedDirectory -or
        [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($newPath)) -ne $resolvedDirectory) {
        throw 'A rename target is outside the inspected folder.'
    }
    if (-not (Test-Path -LiteralPath $oldPath -PathType Leaf)) { throw "Source not found: $oldPath" }
    if (Test-Path -LiteralPath $newPath) { throw "Destination already exists: $newPath" }
    if ((Get-FileHash -LiteralPath $oldPath -Algorithm SHA256).Hash -ne $expectedHash) {
        throw "Source contents differ from the inspected file: $oldPath"
    }
    $pdfPath = [System.IO.Path]::ChangeExtension($newPath, '.pdf')
    if (-not (Test-Path -LiteralPath $pdfPath -PathType Leaf)) { throw "Matching PDF not found: $pdfPath" }
    $pdfHashes[$pdfPath] = (Get-FileHash -LiteralPath $pdfPath -Algorithm SHA256).Hash
}
$plan | Format-Table OldName, NewName -AutoSize
if (-not $Apply) {
    Write-Output 'DRY RUN: all 13 rename pairs verified; no files changed.'
    exit 0
}

foreach ($entry in $plan) {
    Rename-Item -LiteralPath (Join-Path $resolvedDirectory $entry.OldName) -NewName $entry.NewName -ErrorAction Stop
}

foreach ($entry in $plan) {
    $newPath = Join-Path $resolvedDirectory $entry.NewName
    if ((Get-FileHash -LiteralPath $newPath -Algorithm SHA256).Hash -ne $expectedHash) {
        throw "File contents changed unexpectedly: $newPath"
    }
    if (Test-Path -LiteralPath (Join-Path $resolvedDirectory $entry.OldName)) {
        throw "Original filename still exists: $($entry.OldName)"
    }
}
foreach ($pdfPath in $pdfHashes.Keys) {
    if ((Get-FileHash -LiteralPath $pdfPath -Algorithm SHA256).Hash -ne $pdfHashes[$pdfPath]) {
        throw "PDF contents changed unexpectedly: $pdfPath"
    }
}
Write-Output 'SUCCESS: 13 DWG files renamed to match their PDF filenames; DWG contents and PDF files unchanged.'
