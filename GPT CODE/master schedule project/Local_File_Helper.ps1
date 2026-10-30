param([int]$Port = 48731, [switch]$NoBrowser, [switch]$LibraryOnly)
$ErrorActionPreference = 'Stop'
$script:AppDirectory = $PSScriptRoot
$script:AccessToken = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')
$script:BaseUrl = 'http://127.0.0.1:' + $Port
$script:StopServer = $false

function Get-FolderPath([string]$Value) {
    $valuePath = $Value.Trim().Trim('"')
    if ($valuePath -match '^file:') {
        $uri = [Uri]$valuePath
        if (-not $uri.IsFile) { throw 'INVALID_PATH' }
        $valuePath = $uri.LocalPath
    }
    if ($valuePath -notmatch '^(?:[a-zA-Z]:[\\/]|\\\\[^\\]+\\[^\\]+)') { throw 'INVALID_PATH' }
    $full = [IO.Path]::GetFullPath($valuePath)
    if (-not [IO.Directory]::Exists($full)) { throw 'FOLDER_NOT_FOUND' }
    if ($full.Length -gt 3) { $full = $full.TrimEnd('\', '/') }
    return $full
}

function Get-FolderCatalog([string]$Value) {
    $root = Get-FolderPath $Value
    $files = New-Object 'System.Collections.Generic.List[object]'
    $queue = New-Object 'System.Collections.Generic.Queue[string]'
    $queue.Enqueue($root)
    $skipped = 0; $visited = 0; $truncated = $false
    $epoch = [DateTime]::SpecifyKind([DateTime]'1970-01-01', [DateTimeKind]::Utc)
    while ($queue.Count -gt 0 -and -not $truncated) {
        $directory = $queue.Dequeue(); $visited++
        if ($visited -gt 20000) { $truncated = $true; break }
        try {
            foreach ($entry in ([IO.DirectoryInfo]$directory).EnumerateFileSystemInfos()) {
                if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { $skipped++; continue }
                if (($entry.Attributes -band [IO.FileAttributes]::Directory) -ne 0) { $queue.Enqueue($entry.FullName); continue }
                if ($files.Count -ge 20000) { $truncated = $true; break }
                $relative = $entry.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
                $files.Add([ordered]@{name=$entry.Name; path=$relative; size=$entry.Length; modified=[Math]::Floor(($entry.LastWriteTimeUtc - $epoch).TotalMilliseconds); selected=$false})
            }
        } catch { $skipped++ }
    }
    return [ordered]@{rootName=([IO.DirectoryInfo]$root).Name; address=$root; source='local'; scannedAt=[DateTime]::UtcNow.ToString('o'); files=@($files.ToArray()); skipped=$skipped; truncated=$truncated; warning=''}
}

function Get-DocumentPath([string]$Root, [string]$Relative) {
    $base = Get-FolderPath $Root
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':')) { throw 'INVALID_PATH' }
    $parts = $Relative -split '[\\/]'
    if (@($parts | Where-Object { $_ -eq '..' -or $_ -eq '.' -or $_ -eq '' }).Count -gt 0) { throw 'INVALID_PATH' }
    $candidate = [IO.Path]::GetFullPath([IO.Path]::Combine($base, $Relative.Replace('/', '\')))
    $prefix = $base.TrimEnd('\') + '\'
    if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'INVALID_PATH' }
    $current = $base
    foreach ($part in $parts) {
        $current = [IO.Path]::Combine($current, $part)
        if (([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'LINK_NOT_ALLOWED' }
    }
    if (-not [IO.File]::Exists($candidate)) { throw 'FILE_NOT_FOUND' }
    $extension = [IO.Path]::GetExtension($candidate).ToLowerInvariant()
    $blocked = @('.exe','.com','.bat','.cmd','.ps1','.psm1','.psd1','.vbs','.vbe','.js','.jse','.wsf','.wsh','.scr','.msi','.msp','.hta','.lnk','.url','.reg','.cpl','.pif','.application','.sct','.inf','.dll')
    if ($blocked -contains $extension) { throw 'EXECUTABLE_NOT_ALLOWED' }
    return $candidate
}

function Invoke-LocalRequest([string]$Method, [string]$Route, [hashtable]$Headers, [string]$Body) {
    if ($Headers['host'] -ne ('127.0.0.1:' + $Port)) { return @{status=403; json=@{error='HOST_NOT_ALLOWED'}} }
    # The page can be opened from a normal link; API calls still require the origin and session checks below.
    if ($Method -eq 'GET' -and $Route -eq '/') { return @{status=200; bytes=[IO.File]::ReadAllBytes((Join-Path $script:AppDirectory 'Master_Schedule.html')); type='text/html; charset=utf-8'} }
    $origin = $Headers['origin']
    if ($origin -and $origin -ne $script:BaseUrl) { return @{status=403; json=@{error='ORIGIN_NOT_ALLOWED'}} }
    if ($Headers['sec-fetch-site'] -and $Headers['sec-fetch-site'] -notin @('same-origin','none')) { return @{status=403; json=@{error='ORIGIN_NOT_ALLOWED'}} }
    if ($Method -eq 'GET' -and $Route -eq '/api/health') { return @{status=200; json=@{app='master-schedule-local-files'}} }
    if ($Method -eq 'GET' -and $Route -eq '/api/session') { return @{status=200; json=@{token=$script:AccessToken}} }
    if ($Method -ne 'POST' -or $Headers['x-schedule-token'] -cne $script:AccessToken) { return @{status=403; json=@{error='AUTH_REQUIRED'}} }
    if ($Headers['content-type'] -notmatch '^application/json') { return @{status=415; json=@{error='JSON_REQUIRED'}} }
    try {
        $request = ConvertFrom-Json -InputObject $Body
        if ($Route -eq '/api/list') { return @{status=200; json=(Get-FolderCatalog ([string]$request.path))} }
        if ($Route -eq '/api/open') {
            $document = Get-DocumentPath ([string]$request.root) ([string]$request.path)
            $start = New-Object Diagnostics.ProcessStartInfo
            $start.FileName = $document; $start.UseShellExecute = $true
            [void][Diagnostics.Process]::Start($start)
            return @{status=200; json=@{ok=$true}}
        }
        if ($Route -eq '/api/stop') { $script:StopServer = $true; return @{status=200; json=@{ok=$true}} }
        return @{status=404; json=@{error='NOT_FOUND'}}
    } catch {
        $code = $_.Exception.Message
        if ($code -notmatch '^[A-Z_]+$') { $code = 'READ_OR_OPEN_FAILED' }
        return @{status=400; json=@{error=$code}}
    }
}

function Send-LocalResponse($Stream, $Response) {
    $bytes = $Response.bytes
    $type = $Response.type
    if ($null -eq $bytes) { $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Response.json -Depth 12 -Compress)); $type = 'application/json; charset=utf-8' }
    $status = [int]$Response.status
    $header = "HTTP/1.1 $status Response`r`nContent-Type: $type`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nX-Frame-Options: DENY`r`nReferrer-Policy: no-referrer`r`nCross-Origin-Resource-Policy: same-origin`r`nConnection: close`r`n`r`n"
    $headBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headBytes, 0, $headBytes.Length); $Stream.Write($bytes, 0, $bytes.Length); $Stream.Flush()
}

if ($LibraryOnly) { return }
$listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $Port)
try { $listener.Start() } catch {
    try {
        $health = Invoke-RestMethod -Uri ($script:BaseUrl + '/api/health') -TimeoutSec 2
        if ($health.app -eq 'master-schedule-local-files') { if (-not $NoBrowser) { Start-Process $script:BaseUrl }; return }
    } catch { }
    throw 'The local helper port is busy. Close the previous helper and try again.'
}
try {
    if (-not $NoBrowser) { Start-Process $script:BaseUrl }
    while (-not $script:StopServer) {
        $client = $listener.AcceptTcpClient(); $stream = $client.GetStream(); $stream.ReadTimeout = 5000; $stream.WriteTimeout = 15000
        try {
            $headerBytes = New-Object 'System.Collections.Generic.List[byte]'
            while ($headerBytes.Count -lt 16384) {
                $b = $stream.ReadByte(); if ($b -lt 0) { throw 'INCOMPLETE_REQUEST' }; $headerBytes.Add([byte]$b)
                $n = $headerBytes.Count
                if ($n -ge 4 -and $headerBytes[$n-4] -eq 13 -and $headerBytes[$n-3] -eq 10 -and $headerBytes[$n-2] -eq 13 -and $headerBytes[$n-1] -eq 10) { break }
            }
            $lines = [Text.Encoding]::ASCII.GetString($headerBytes.ToArray()) -split "`r`n"
            $requestLine = $lines[0] -split ' '
            if ($requestLine.Count -ne 3 -or $headerBytes.Count -ge 16384) { throw 'BAD_REQUEST' }
            $headers = @{}
            foreach ($line in $lines[1..($lines.Length-1)]) { $colon = $line.IndexOf(':'); if ($colon -gt 0) { $key = $line.Substring(0,$colon).ToLowerInvariant(); if ($headers.ContainsKey($key)) { throw 'DUPLICATE_HEADER' }; $headers[$key] = $line.Substring($colon+1).Trim() } }
            if ($headers['transfer-encoding']) { throw 'UNSUPPORTED_BODY' }
            $length = 0
            if ($headers['content-length'] -and (-not [int]::TryParse($headers['content-length'], [ref]$length))) { throw 'BAD_LENGTH' }
            if ($length -lt 0 -or $length -gt 32768) { throw 'BODY_TOO_LARGE' }
            $buffer = New-Object byte[] $length; $offset = 0
            while ($offset -lt $length) { $read = $stream.Read($buffer,$offset,$length-$offset); if ($read -le 0) { throw 'INCOMPLETE_BODY' }; $offset += $read }
            $route = ($requestLine[1] -split '\?',2)[0]
            $response = Invoke-LocalRequest $requestLine[0] $route $headers ([Text.Encoding]::UTF8.GetString($buffer))
            Send-LocalResponse $stream $response
        } catch { try { Send-LocalResponse $stream @{status=400; json=@{error='BAD_REQUEST'}} } catch { } }
        finally { $stream.Dispose(); $client.Dispose() }
    }
} finally { $listener.Stop() }
