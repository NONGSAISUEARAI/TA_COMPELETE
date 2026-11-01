$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$base='C:\TA\PPLINE CKST\C1&C2_0121-1 Update (29.01.26) PPedit\PPLINE CKST - APPROVE + COMMENT'
$allowed=@('[IV01]','[PP17]','[PP18]','[PP19]','[VS01]')
$manifest=@(Get-Content -LiteralPath (Join-Path $root 'manifest.json') -Raw | ConvertFrom-Json)
$results=@(Get-Content -LiteralPath (Join-Path $root 'final_verified.jsonl') | ForEach-Object {$_ | ConvertFrom-Json})
if($manifest.Count -ne 11 -or $results.Count -ne 11) {throw 'Expected exactly 11 verified files'}
$changes=@()
foreach($entry in $manifest) {
    $resolved=(Resolve-Path -LiteralPath $entry.Source).Path
    $relative=[IO.Path]::GetRelativePath($base,$resolved)
    if(-not $resolved.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase) -or ($relative.Split('\')[0] -notin $allowed) -or [IO.Path]::GetExtension($resolved) -ne '.dwg') {throw 'Unexpected destination'}
    if((Get-FileHash -LiteralPath $resolved).Hash -ne $entry.OriginalSHA256) {throw "Source changed since backup: $resolved"}
    if((Get-FileHash -LiteralPath $entry.Backup).Hash -ne $entry.OriginalSHA256) {throw 'Backup verification failed'}
    $verified=@($results | Where-Object {$_.Source -ceq $entry.Source -and $_.Output -ceq $entry.Output -and $_.status -eq 'PASS' -and $_.after.NonWhite -eq 0 -and $_.after.Explodable -eq 0 -and $_.after.InlineColors -eq 0})
    if($verified.Count -ne 1) {throw "Missing PASS result: $resolved"}
    $changes+=[pscustomobject]@{Source=$resolved;Output=$entry.Output;Backup=$entry.Backup;OriginalSHA256=$entry.OriginalSHA256;NewSHA256=(Get-FileHash -LiteralPath $entry.Output).Hash}
}
foreach($change in $changes) {
    Copy-Item -LiteralPath $change.Output -Destination $change.Source -Force
    if((Get-FileHash -LiteralPath $change.Source).Hash -ne $change.NewSHA256) {throw "Installed hash mismatch: $($change.Source)"}
    $change | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $root 'installed.jsonl') -Encoding utf8
    Write-Output ('INSTALLED '+[IO.Path]::GetFileName($change.Source))
}
Write-Output 'SUCCESS: all 11 originals updated and verified; original backups retained.'
