param([string]$AutoCAD = 'C:\Program Files\Autodesk\AutoCAD 2026', [switch]$Tests)
$ErrorActionPreference = 'Stop'
# Build with PowerShell 7's bundled Roslyn compiler; a .NET SDK is not needed.
Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.dll')
Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.CSharp.dll')
$runtime = Get-ChildItem 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App' -Directory |
    Where-Object Name -Like '8.*' | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
$desktop = Get-ChildItem 'C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App' -Directory |
    Where-Object Name -Like '8.*' | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (!$runtime -or !$desktop) { throw '.NET 8 runtime and Windows Desktop runtime are required.' }
$references = [System.Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]]::new()
foreach ($file in (Get-ChildItem $runtime.FullName -Filter '*.dll')) {
    try { [Reflection.AssemblyName]::GetAssemblyName($file.FullName) | Out-Null } catch { continue }
    $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($file.FullName))
}
foreach ($name in @('System.Windows.Forms.dll', 'System.Windows.Forms.Primitives.dll')) {
    $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile((Join-Path $desktop.FullName $name)))
}
foreach ($name in @('AcDbMgd.dll', 'AcCoreMgd.dll', 'AcMgd.dll')) {
    $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile((Join-Path $AutoCAD $name)))
}
$trees = [System.Collections.Generic.List[Microsoft.CodeAnalysis.SyntaxTree]]::new()
$sources = @(Get-ChildItem (Join-Path $PSScriptRoot 'src') -Filter '*.cs')
if ($Tests) { $sources += @(Get-ChildItem (Join-Path $PSScriptRoot 'tests') -Filter '*.cs') }
foreach ($file in $sources) {
    $trees.Add([Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText($file.FullName)))
}
$options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary)
$options = $options.WithPlatform([Microsoft.CodeAnalysis.Platform]::X64)
$assemblyName = if ($Tests) { 'TA_UPDATE_BLOCK_TESTS' } else { 'TA_UPDATE_BLOCK' }
$compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create($assemblyName, $trees, $references, $options)
$outDir = Join-Path $PSScriptRoot $(if ($Tests) { 'tests\bin' } else { 'bin\Release\net8.0-windows' })
[IO.Directory]::CreateDirectory($outDir) | Out-Null
$output = Join-Path $outDir ($assemblyName + '.dll')
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
Write-Output "Built $output"
