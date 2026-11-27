param(
    [string]$AutoCADPath = 'C:\Program Files\Autodesk\AutoCAD 2026',
    [string]$RuntimePath = 'C:\Program Files\dotnet\shared\Microsoft.NETCore.App\8.0.33'
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'src\HatchCommands.cs'
$outputDirectory = Join-Path $projectRoot 'bin'
$outputPath = Join-Path $outputDirectory 'TA_HATCH_FROM_BOUNDARY_v6.dll'
$presetSource = Join-Path $projectRoot 'TA_HATCH_PRESETS.json'
$presetOutput = Join-Path $outputDirectory 'TA_HATCH_PRESETS.json'
$roslynPath = Split-Path -Parent (Get-Process -Id $PID).Path

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

[void][System.Reflection.Assembly]::LoadFrom((Join-Path $roslynPath 'Microsoft.CodeAnalysis.dll'))
[void][System.Reflection.Assembly]::LoadFrom((Join-Path $roslynPath 'Microsoft.CodeAnalysis.CSharp.dll'))

$references = [System.Collections.Generic.List[Microsoft.CodeAnalysis.MetadataReference]]::new()
foreach ($file in Get-ChildItem -LiteralPath $RuntimePath -Filter '*.dll') {
    try {
        [void][System.Reflection.AssemblyName]::GetAssemblyName($file.FullName)
        $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($file.FullName))
    } catch {
        # Skip native runtime DLLs without managed metadata.
    }
}
foreach ($name in @('AcDbMgd.dll', 'AcCoreMgd.dll', 'AcMgd.dll')) {
    $referencePath = Join-Path $AutoCADPath $name
    if (-not (Test-Path -LiteralPath $referencePath)) {
        throw "Missing AutoCAD reference: $referencePath"
    }
    $references.Add([Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($referencePath))
}

$syntax = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText(
    [System.IO.File]::ReadAllText($sourcePath)
)
$options = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new(
    [Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary
).WithOptimizationLevel([Microsoft.CodeAnalysis.OptimizationLevel]::Release).WithPlatform(
    [Microsoft.CodeAnalysis.Platform]::X64
)
$compilation = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create(
    'TA_HATCH_FROM_BOUNDARY_V6',
    [Microsoft.CodeAnalysis.SyntaxTree[]]@($syntax),
    $references.ToArray(),
    $options
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
    throw 'TA_HATCH_FROM_BOUNDARY_v6.dll compilation failed.'
}

Copy-Item -LiteralPath $presetSource -Destination $presetOutput -Force
Write-Host "Built $outputPath"
Write-Host "Copied $presetOutput"
