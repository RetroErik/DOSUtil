# Build DOS release packages without changing checked-in binaries or archives.
[CmdletBinding()]
param(
    [ValidateSet('DES', 'DEDIT', 'All')]
    [string]$Program = 'All',
    [string]$Nasm = 'nasm'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$outputRoot = Join-Path $repoRoot 'artifacts/dos-releases'
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$dosEncoding = [System.Text.Encoding]::GetEncoding(
    437, [System.Text.EncoderFallback]::ExceptionFallback,
    [System.Text.DecoderFallback]::ExceptionFallback)
$versions = [ordered]@{ DES = '1.3'; DEDIT = '1.0' }
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($name in $versions.Keys) {
    if ($Program -ne 'All' -and $Program -ne $name) { continue }
    $version = $versions[$name]
    $packageName = "$name-$version-DOS"
    $zipPath = Join-Path $outputRoot "$packageName.zip"
    $sumPath = Join-Path $outputRoot "$packageName.sha256"
    if ((Test-Path -LiteralPath $zipPath) -or (Test-Path -LiteralPath $sumPath)) {
        throw "Release already exists: $packageName. Existing packages are never overwritten."
    }
    $stage = Join-Path $outputRoot ("stage-$packageName-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    $project = Join-Path $repoRoot $name
    $binary = Join-Path $stage "$name.COM"
    & $Nasm -f bin (Join-Path $project ($name.ToLowerInvariant() + '.asm')) -o $binary
    if ($LASTEXITCODE -ne 0) { throw "NASM failed for $name" }
    $builtHash = (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash
    $checkedInHash = (Get-FileHash -LiteralPath (Join-Path $project "$name.COM") -Algorithm SHA256).Hash
    if ($builtHash -ne $checkedInHash) {
        throw "Rebuilt $name.COM differs from the checked-in binary. Review before releasing."
    }
    foreach ($item in @(@('README.TXT', 'README.TXT'), @('LICENSE', 'LICENSE.TXT'))) {
        $content = [System.IO.File]::ReadAllText((Join-Path $project $item[0]), $utf8)
        $content = ($content -replace "`r?`n", "`r`n")
        [System.IO.File]::WriteAllText((Join-Path $stage $item[1]), $content, $dosEncoding)
    }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zipPath)
    $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText($sumPath, "$zipHash  $packageName.zip`r`n", [System.Text.Encoding]::ASCII)
    Write-Output "Created $zipPath"
    Write-Output "SHA256 $zipHash"
    # Keep the small staging directory for inspection and DOS smoke tests.
}
