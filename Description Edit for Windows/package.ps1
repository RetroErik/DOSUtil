[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = $PSScriptRoot
$projectFile = Join-Path $projectRoot 'src\DescriptionEditForWindows\DescriptionEditForWindows.csproj'
[xml] $projectXml = Get-Content -LiteralPath $projectFile
$version = $projectXml.Project.PropertyGroup.Version | Select-Object -First 1
$releaseName = "DescriptionEditForWindows-$version-win-x64"
$artifactsDirectory = Join-Path $projectRoot 'artifacts'
$releaseDirectory = Join-Path $artifactsDirectory $releaseName
$appDirectory = Join-Path $releaseDirectory 'app'
$zipPath = Join-Path $artifactsDirectory ($releaseName + '.zip')

$resolvedRoot = [IO.Path]::GetFullPath($projectRoot)
$resolvedArtifacts = [IO.Path]::GetFullPath($artifactsDirectory)
if (-not $resolvedArtifacts.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to create release files outside the project directory.'
}

if (Test-Path -LiteralPath $releaseDirectory) {
    Remove-Item -LiteralPath $releaseDirectory -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

New-Item -ItemType Directory -Path $appDirectory -Force | Out-Null
& dotnet publish $projectFile -c Release -r win-x64 --self-contained true `
    -p:Platform=x64 -p:WindowsAppSDKSelfContained=true -o $appDirectory
if ($LASTEXITCODE -ne 0) { throw "Publish failed with exit code $LASTEXITCODE" }

Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Install.ps1') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Install.cmd') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Uninstall.ps1') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Uninstall.cmd') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $releaseDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination $releaseDirectory

Compress-Archive -LiteralPath $releaseDirectory -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $releaseDirectory -Recurse -Force
Write-Host "Created '$zipPath'."
