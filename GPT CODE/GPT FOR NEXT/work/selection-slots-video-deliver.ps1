$ErrorActionPreference = 'Stop'
$stagePath = 'C:\TA\TA_COMPELETE\GPT CODE\GPT FOR NEXT\work\selection-slots-video'
$targetPath = 'C:\TA\TA-PORTFOLIO\Autolisp Collection\03_Selection_and_Inspection\Selection_Slots'
$backupPath = 'C:\TA\TA-PORTFOLIO\backups\Selection_Slots_before_video_20261011'
$expected = @{
  'index.html' = '5A57A13FB0CE9DE8C390AE7514633A3CEA6D934CE837662092073223B43F7D12'
  'assets\template.css' = '646F06DC7E46E58A2CFB6476ED3B004325840DE48B0BE7F22001AE7ACB5221A2'
  'assets\template.js' = '9E65768BBA50F138BD2CFD9A4F3A824161E598A90BCFE64F7883C98AE39F454B'
}
foreach ($relative in $expected.Keys) {
  if ((Get-FileHash -LiteralPath (Join-Path $targetPath $relative)).Hash -ne $expected[$relative]) {
    throw "Target changed since inspection: $relative. Preserve and inspect before saving."
  }
}
if (Test-Path -LiteralPath $backupPath) { throw 'Backup already exists; do not overwrite.' }
$videoPath = Join-Path $targetPath 'assets\videos\selection-saveloadadddelete.mp4'
if (Test-Path -LiteralPath $videoPath) { throw 'Target video already exists; inspect before overwrite.' }
New-Item -ItemType Directory -Path (Join-Path $backupPath 'assets') | Out-Null
foreach ($relative in @('index.html','README.md','QA.md','assets\template.css','assets\template.js')) {
  Copy-Item -LiteralPath (Join-Path $targetPath $relative) -Destination (Join-Path $backupPath $relative)
}
New-Item -ItemType Directory -Path (Join-Path $targetPath 'assets\videos') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath 'previews') -Force | Out-Null
foreach ($relative in @('index.html','README.md','QA.md','assets\template.css','assets\template.js','assets\videos\selection-saveloadadddelete.mp4','previews\video-desktop.png','previews\video-mobile.png')) {
  Copy-Item -LiteralPath (Join-Path $stagePath $relative) -Destination (Join-Path $targetPath $relative)
  if ((Get-FileHash -LiteralPath (Join-Path $stagePath $relative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $targetPath $relative)).Hash) {
    throw "Copy verification failed: $relative"
  }
}
if ((Get-FileHash -LiteralPath 'C:\TA\TA_COMPELETE\GPT CODE\GPT FOR NEXT\selection_saveloadadddelete_func.mp4').Hash -ne (Get-FileHash -LiteralPath $videoPath).Hash) {
  throw 'Original video differs from project copy.'
}
Write-Output "Saved and verified: $targetPath"
Write-Output "Previous files backed up: $backupPath"
