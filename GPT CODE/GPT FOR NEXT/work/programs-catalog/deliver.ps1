$ErrorActionPreference = 'Stop'
$portfolioRoot = 'C:\TA\TA-PORTFOLIO'
$stageRoot = 'C:\TA\TA_COMPELETE\GPT CODE\GPT FOR NEXT\work\programs-catalog'
$backupRoot = 'C:\TA\TA-PORTFOLIO\backups\Before_Programs_20261011'
$expected = @{
  'source\index.html'='B163234F879E6E8403C01F2091D23D2A723B0EBF412FEDB398EC33DB1A980A04'
  'source\css\home.css'='04A20D0772084AF134DF496D2314DD3F0F9728A7ED78154DD059BDCB5248C2CB'
  'source\js\home.js'='D468DDB59064F9D1E349C24A5EA346966143DA2DE3D225523B7D8BB067C6A8CE'
  'publish\index.html'='B699D7B28EFCE2A5714817EDA0744B7E29064EC5D5AD4168E0E1236FE0E6FF4A'
  'publish\js\encrypted-portfolio.js'='A667A111CD3EC97A054013A7C14A18AD1F498DE3A9B4C08E92E21E282F2F1B66'
  'publish\css\login.css'='D05CBB6968D7BF6D5DE2331333A3510D0BB2E5CAA669947B86CBFD3B458FD816'
  'tools\build-encrypted-portfolio.mjs'='587D58A5D4C4E82418D17143464BB6174271D59039F49B9241E33EB0CCA72F97'
  '.gitignore'='298C88345D360DA9FABAE1D949B4079AC4040A89363AADB99270AE8F04683500'
}
foreach ($relative in $expected.Keys) {
  if ((Get-FileHash -LiteralPath (Join-Path $portfolioRoot $relative)).Hash -ne $expected[$relative]) { throw "File changed since inspection: $relative" }
}
if (Test-Path -LiteralPath $backupRoot) { throw 'Backup already exists; do not overwrite.' }
$keyPath = Join-Path $portfolioRoot 'private\access-key.json'
if (-not (Test-Path -LiteralPath $keyPath)) { throw 'Existing private key is missing. Do not create a new password.' }
$keyHash = (Get-FileHash -LiteralPath $keyPath).Hash
foreach ($folder in @('source\css','source\js','publish\css','publish\js','private')) { New-Item -ItemType Directory -Path (Join-Path $backupRoot $folder) -Force | Out-Null }
foreach ($relative in @('source\index.html','source\css\home.css','source\js\home.js','publish\index.html','publish\js\encrypted-portfolio.js','publish\css\login.css','.gitignore','private\build-checks.json')) {
  $oldPath = Join-Path $portfolioRoot $relative
  if (Test-Path -LiteralPath $oldPath) { Copy-Item -LiteralPath $oldPath -Destination (Join-Path $backupRoot $relative) }
}
# Ignore plaintext backups before saving them into the repository.
Copy-Item -LiteralPath (Join-Path $stageRoot '.gitignore') -Destination (Join-Path $portfolioRoot '.gitignore')
Copy-Item -LiteralPath (Join-Path $stageRoot 'publish\css\login.css') -Destination (Join-Path $portfolioRoot 'publish\css\login.css')
& 'C:\Users\popul\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' (Join-Path $portfolioRoot 'tools\build-encrypted-portfolio.mjs') (Join-Path $stageRoot 'source')
if ($LASTEXITCODE -ne 0) { throw 'Encryption build failed. Previous files are recoverable in the backup.' }
if ((Get-FileHash -LiteralPath $keyPath).Hash -ne $keyHash) { throw 'Existing credential unexpectedly changed.' }
foreach ($relative in @('source\index.html','source\css\home.css','source\js\home.js')) {
  if ((Get-FileHash -LiteralPath (Join-Path $stageRoot $relative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $portfolioRoot $relative)).Hash) { throw "Source copy mismatch: $relative" }
}
Copy-Item -LiteralPath (Join-Path $stageRoot 'README.md') -Destination (Join-Path $portfolioRoot 'source\PROGRAMS-README.md')
Write-Output 'Programs source and encrypted after-login payload saved. Existing credential unchanged.'
Write-Output "Previous homepage backed up: $backupRoot"
