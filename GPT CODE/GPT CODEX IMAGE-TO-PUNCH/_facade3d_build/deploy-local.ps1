$ErrorActionPreference = 'Stop'
$stageDir = $PSScriptRoot
$targetDir = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX IMAGE-TO-PUNCH 3D'
$originalDir = 'C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX IMAGE-TO-PUNCH'
$resolvedTarget = (Resolve-Path -LiteralPath $targetDir).Path
if ($resolvedTarget -ne $targetDir) { throw 'Unexpected destination path' }
if ((Get-Item -LiteralPath $targetDir).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Destination must not be a linked directory' }
$backupDir = Join-Path $targetDir '_legacy-reference'
if (Test-Path -LiteralPath $backupDir) { throw 'Backup exists; inspect before deploying again' }
$legacyFiles = @('index.html','app.js','style.css','tests\punch-shapes.cjs')
foreach ($relative in $legacyFiles) {
  $oldFile = Join-Path $targetDir $relative
  $original = Join-Path $originalDir $relative
  if ((Get-FileHash -LiteralPath $oldFile).Hash -ne (Get-FileHash -LiteralPath $original).Hash) { throw "Original copy has changed: $relative" }
}
New-Item -ItemType Directory -Path (Join-Path $backupDir 'tests') -Force | Out-Null
foreach ($relative in $legacyFiles) {
  $oldFile = Join-Path $targetDir $relative
  $backupFile = Join-Path $backupDir $relative
  if (-not ([IO.Path]::GetFullPath($oldFile).StartsWith($targetDir + '\')) -or -not ([IO.Path]::GetFullPath($backupFile).StartsWith($targetDir + '\'))) { throw 'Path outside target workspace' }
  Move-Item -LiteralPath $oldFile -Destination $backupFile
}
$files = @('index.html','app.js','style.css','geometry.js','dxf.js','server.mjs','package.json','README.md','preview-3d.png','preview-area.png','tests\geometry.test.mjs','tests\browser-smoke.cjs','tests\make-sample.mjs','samples\facade-boundaries.dxf','vendor\three.module.js','vendor\three.core.js','vendor\OrbitControls.js','vendor\THREE-LICENSE.txt')
foreach ($relative in $files) {
  $sourceFile = Join-Path $stageDir $relative
  $targetFile = Join-Path $targetDir $relative
  New-Item -ItemType Directory -Path (Split-Path -Parent $targetFile) -Force | Out-Null
  Copy-Item -LiteralPath $sourceFile -Destination $targetFile
  if ((Get-FileHash -LiteralPath $sourceFile).Hash -ne (Get-FileHash -LiteralPath $targetFile).Hash) { throw "Verification failed: $relative" }
}
Write-Output "Installed and verified $($files.Count) files in $targetDir"
Write-Output "Legacy reference preserved at $backupDir"
