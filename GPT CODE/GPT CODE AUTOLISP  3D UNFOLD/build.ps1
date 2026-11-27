param([string]$AutoCAD = 'C:\Program Files\Autodesk\AutoCAD 2026')
$ErrorActionPreference = 'Stop'

# AutoCAD 2026 uses .NET 8.  PowerShell 7 already carries the Roslyn compiler,
# so this builder works on the production PC without installing a full SDK.
Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.dll')
Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.CSharp.dll')

$runtime = Get-ChildItem 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App' -Directory |
    Where-Object Name -Like '8.*' | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (!$runtime) { throw '.NET 8 runtime is required.' }

$references = [System.Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]]::new()
foreach ($file in (Get-ChildItem $runtime.FullName -Filter '*.dll')) {
    try { [Reflection.AssemblyName]::GetAssemblyName($file.FullName) | Out-Null } catch { continue }
    $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($file.FullName))
}
foreach ($name in @('AcDbMgd.dll', 'AcDbMgdBrep.dll', 'AcCoreMgd.dll', 'AcMgd.dll')) {
    $path = Join-Path $AutoCAD $name
    if (!(Test-Path -LiteralPath $path)) { throw "AutoCAD reference not found: $path" }
    $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($path))
}

$trees = [System.Collections.Generic.List[Microsoft.CodeAnalysis.SyntaxTree]]::new()
foreach ($file in (Get-ChildItem (Join-Path $PSScriptRoot 'src') -Filter '*.cs')) {
    $trees.Add([Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText($file.FullName)))
}
$options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary)
$options = $options.WithPlatform([Microsoft.CodeAnalysis.Platform]::X64)
$compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create('TA_3D_UNFOLD', $trees, $references, $options)
$outDir = Join-Path $PSScriptRoot 'bin\Release\net8.0-windows'
[IO.Directory]::CreateDirectory($outDir) | Out-Null
$output = Join-Path $outDir 'TA_3D_UNFOLD.dll'
$temporary = $output + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
try {
    $stream = [IO.File]::Create($temporary)
    try { $result = $compilation.Emit($stream) } finally { $stream.Dispose() }
    foreach ($diagnostic in $result.Diagnostics) {
        if ($diagnostic.Severity -ne 'Hidden') { Write-Output $diagnostic.ToString() }
    }
    if (!$result.Success) { throw 'Compilation failed.' }
    [IO.File]::Move($temporary, $output, $true)
} finally {
    if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
}
$portable = Join-Path $PSScriptRoot 'TA_3D_UNFOLD.dll'
[IO.File]::Copy($output, $portable, $true)
Write-Output "Built $output"
Write-Output "Copied portable DLL beside LISP: $portable"
