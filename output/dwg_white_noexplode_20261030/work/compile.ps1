param([string]$Version='3')
$ErrorActionPreference='Stop'
$work=$PSScriptRoot
Add-Type -TypeDefinition 'public class CompilerBootstrap {}'
$paths=@(Get-ChildItem -LiteralPath 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App\8.0.21' -Filter '*.dll' | Select-Object -ExpandProperty FullName)+@('C:\Program Files\Autodesk\AutoCAD 2025\acdbmgd.dll','C:\Program Files\Autodesk\AutoCAD 2025\accoremgd.dll')
$refs=[System.Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]]::new()
foreach($p in $paths) { try { $null=[Reflection.AssemblyName]::GetAssemblyName($p); $refs.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($p)) } catch [System.BadImageFormatException] {} }
$tree=[Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText((Join-Path $work 'WhiteNoExplode.cs')))
$options=[Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary)
$assemblyName='WhiteNoExplode'+$Version
$comp=[Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create($assemblyName, [Microsoft.CodeAnalysis.SyntaxTree[]]@($tree), $refs, $options)
$stream=[IO.File]::Create((Join-Path $work ($assemblyName+'.dll')))
try { $result=$comp.Emit($stream); $result.Diagnostics | ForEach-Object {$_.ToString()}; if(-not $result.Success) {throw 'Compilation failed'} } finally { $stream.Dispose() }
