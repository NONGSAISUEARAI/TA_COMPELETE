param(
    [string]$AutoCADPath = 'C:\Program Files\Autodesk\AutoCAD 2026',
    [string]$RuntimePath = 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App\8.0.33'
)

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $PSScriptRoot 'TA_FILTER_FROM_OBJECT.cs'
$outputPath = Join-Path $PSScriptRoot 'TA_FILTER_FROM_OBJECT.dll'
$roslynPath = Split-Path -Parent (Get-Process -Id $PID).Path

[void][System.Reflection.Assembly]::LoadFrom((Join-Path $roslynPath 'Microsoft.CodeAnalysis.dll'))
[void][System.Reflection.Assembly]::LoadFrom((Join-Path $roslynPath 'Microsoft.CodeAnalysis.CSharp.dll'))

$references = [System.Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]]::new()
foreach ($file in Get-ChildItem -LiteralPath $RuntimePath -Filter '*.dll') {
    try {
        [void][System.Reflection.AssemblyName]::GetAssemblyName($file.FullName)
        $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($file.FullName))
    } catch {
        # Native runtime DLLs do not carry managed metadata.
    }
}
foreach ($name in @('AcDbMgd.dll', 'AcCoreMgd.dll', 'AcMgd.dll')) {
    $references.Add(
        [Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile(
            (Join-Path $AutoCADPath $name)
        )
    )
}

$syntax = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText(
    [System.IO.File]::ReadAllText($sourcePath)
)
$options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new(
    [Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary
)
$syntaxTrees = [Microsoft.CodeAnalysis.SyntaxTree[]]@($syntax)
$compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create(
    'TA_FILTER_FROM_OBJECT', $syntaxTrees, $references.ToArray(), $options
)

$stream = [System.IO.File]::Create($outputPath)
try {
    $result = $compilation.Emit($stream)
} finally {
    $stream.Dispose()
}
foreach ($diagnostic in $result.Diagnostics) {
    if ($diagnostic.Severity -ne [Microsoft.CodeAnalysis.DiagnosticSeverity]::Hidden) {
        Write-Host $diagnostic.ToString()
    }
}
if (-not $result.Success) {
    throw 'TA_FILTER_FROM_OBJECT.dll compilation failed.'
}
Write-Host "Built $outputPath"
