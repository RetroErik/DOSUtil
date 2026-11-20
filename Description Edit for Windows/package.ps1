[CmdletBinding()]
param([switch] $SlimPreview)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = $PSScriptRoot
$projectFile = Join-Path $projectRoot 'src\DescriptionEditForWindows\DescriptionEditForWindows.csproj'
[xml] $projectXml = Get-Content -LiteralPath $projectFile
$version = $projectXml.SelectSingleNode('/Project/PropertyGroup/Version').InnerText
$variant = if ($SlimPreview) { '-slim-preview' } else { '' }
$releaseName = "DescriptionEditForWindows-$version$variant-win-x64"
$artifactsDirectory = Join-Path $projectRoot 'artifacts'
$releaseDirectory = Join-Path $artifactsDirectory $releaseName
$appDirectory = Join-Path $releaseDirectory 'app'
$zipPath = Join-Path $artifactsDirectory ($releaseName + '.zip')

$resolvedRoot = [IO.Path]::GetFullPath($projectRoot)
$resolvedArtifacts = [IO.Path]::GetFullPath($artifactsDirectory)
if (-not $resolvedArtifacts.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to create release files outside the project directory.'
}
$resolvedRelease = [IO.Path]::GetFullPath($releaseDirectory)
if (-not $resolvedRelease.StartsWith($resolvedArtifacts + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to stage release files outside the artifacts directory.'
}

if (Test-Path -LiteralPath $releaseDirectory) {
    throw "Release staging directory already exists: '$releaseDirectory'. Preserve or inspect it before packaging again."
}
if (Test-Path -LiteralPath $zipPath) {
    throw "Release ZIP already exists: '$zipPath'. Existing releases must be preserved."
}

New-Item -ItemType Directory -Path $appDirectory -Force | Out-Null
$publishArguments = @('publish', $projectFile, '-c', 'Release', '-r', 'win-x64',
    '--self-contained', 'true', '-p:Platform=x64', '-p:WindowsAppSDKSelfContained=true', '-o', $appDirectory)
if ($SlimPreview) { $publishArguments += '-p:UseSlimWinUI=true' }
& dotnet @publishArguments
if ($LASTEXITCODE -ne 0) { throw "Publish failed with exit code $LASTEXITCODE" }

Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Install.ps1') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Install.cmd') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Uninstall.ps1') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Uninstall.cmd') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'DEVELOPMENT.md') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'AGENTS.md') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination $releaseDirectory
if ($SlimPreview) {
    @'
EXPERIMENTAL SLIM PACKAGE - NOT THE PUBLISHED 1.0.6 RELEASE
This trial uses selected Windows App SDK components instead of the full package.
Both .NET and the Windows App Runtime remain bundled. Keep the app folder intact.
It has not been validated on a clean Windows installation without shared runtimes.
By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
'@ | Set-Content -LiteralPath (Join-Path $releaseDirectory 'EXPERIMENTAL.txt') -Encoding UTF8
}

Compress-Archive -LiteralPath $releaseDirectory -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $releaseDirectory -Recurse -Force
Write-Host "Created '$zipPath'."
