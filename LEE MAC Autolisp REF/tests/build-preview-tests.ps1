$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.dll')
Add-Type -Path (Join-Path $PSHOME 'Microsoft.CodeAnalysis.CSharp.dll')
$runtime = Get-ChildItem 'C:/Program Files/dotnet/shared/Microsoft.NETCore.App' -Directory |
    Where-Object Name -Like '8.*' | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
$refs = [System.Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]]::new()
foreach ($file in (Get-ChildItem $runtime.FullName -Filter '*.dll')) {
    try { [Reflection.AssemblyName]::GetAssemblyName($file.FullName) | Out-Null } catch { continue }
    $refs.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($file.FullName))
}
foreach ($name in @('AcDbMgd.dll','AcCoreMgd.dll','AcMgd.dll')) {
    $refs.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile("C:/Program Files/Autodesk/AutoCAD 2026/$name"))
}
$tree = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText((Get-Content -LiteralPath (Join-Path $PSScriptRoot 'PreviewGeometry.cs') -Raw))
$trees = [System.Collections.Generic.List[Microsoft.CodeAnalysis.SyntaxTree]]::new()
$trees.Add($tree)
$options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary).WithPlatform([Microsoft.CodeAnalysis.Platform]::X64)
$compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create('CountPreviewGeometry', $trees, $refs, $options)
$stream = [IO.File]::Create((Join-Path $PSScriptRoot 'CountPreviewGeometry.dll'))
try { $result = $compilation.Emit($stream) } finally { $stream.Dispose() }
foreach ($diagnostic in $result.Diagnostics) { if ($diagnostic.Severity -ne 'Hidden') { Write-Output $diagnostic.ToString() } }
if (!$result.Success) { throw 'Compilation failed' }
Write-Output 'Built CountPreviewGeometry.dll'
