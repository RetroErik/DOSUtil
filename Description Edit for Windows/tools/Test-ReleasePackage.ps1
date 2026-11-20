[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $ZipPath,
    [string] $ExpectedVersion = '1.0.7.0',
    [switch] $SlimPreview
)

# By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
# Verify the exact ZIP payload using an isolated copy, without associations or shortcuts.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$releaseName = [IO.Path]::GetFileNameWithoutExtension([IO.Path]::GetFullPath($ZipPath))
$zipPath = (Resolve-Path -LiteralPath $ZipPath).Path
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$verificationRoot = Join-Path $workspaceRoot ('.release-check-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $names = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    foreach ($name in $names) {
        if (-not $name.StartsWith($releaseName + '/') -or $name.Contains('../')) {
            throw "Unexpected archive path: $name"
        }
    }
    foreach ($relative in @('Install.cmd', 'Install.ps1', 'Uninstall.cmd', 'Uninstall.ps1', 'README.md', 'LICENSE',
        'app/DescriptionEditForWindows.exe', 'app/DescriptionEditForWindows.dll',
        'app/DescriptionEditForWindows.runtimeconfig.json', 'app/coreclr.dll',
        'app/Microsoft.UI.Xaml.dll', 'app/Microsoft.UI.Xaml.Controls.pri', 'app/Assets/DescriptionEditForWindows.ico',
        'app/DescriptionEditForWindows.pri', 'app/App.xbf', 'app/MainWindow.xbf')) {
        if (($releaseName + '/' + $relative) -notin $names) { throw "Missing ZIP entry: $relative" }
    }
    if ($SlimPreview) {
        $unused = @($names | Where-Object {
            $_ -match '/(onnxruntime|DirectML|Microsoft\.Windows\.AI\.[^/]+|Microsoft\.Windows\.Search[^/]*|Microsoft\.Windows\.Widgets[^/]*)\.dll$'
        })
        if ($unused.Count) { throw "Unexpected unused SDK components: $($unused -join ', ')" }
        Write-Host 'Unused AI/ML, search, and widgets payload checks passed.'
    }
    Write-Host "ZIP entries validated: $($names.Count)"
} finally { $archive.Dispose() }
[IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $verificationRoot)
$releaseRoot = Join-Path $verificationRoot $releaseName
$appRoot = Join-Path $releaseRoot 'app'
$runtime = Get-Content -LiteralPath (Join-Path $appRoot 'DescriptionEditForWindows.runtimeconfig.json') -Raw | ConvertFrom-Json
if ($runtime.runtimeOptions.frameworks -or $runtime.runtimeOptions.framework) { throw 'App still requests a shared .NET runtime.' }
if (-not $runtime.runtimeOptions.includedFrameworks) { throw 'Self-contained .NET runtime metadata missing.' }
$version = (Get-Item -LiteralPath (Join-Path $appRoot 'DescriptionEditForWindows.exe')).VersionInfo.FileVersion
if ($version -ne $ExpectedVersion) { throw "Unexpected EXE version: $version" }

# Redirect only the install destination and skip user associations and shortcuts.
$originalLocalAppData = $env:LOCALAPPDATA
$isolatedLocalAppData = Join-Path $verificationRoot 'isolated-localappdata'
try {
    $env:LOCALAPPDATA = $isolatedLocalAppData
    & (Join-Path $releaseRoot 'Install.ps1') -SkipFileAssociation -SkipStartMenuShortcut
} finally { $env:LOCALAPPDATA = $originalLocalAppData }
$installedRoot = Join-Path $isolatedLocalAppData 'Programs\Retro Erik\Description Edit for Windows'
$payload = @(Get-ChildItem -LiteralPath $appRoot -Recurse -File -Force)
foreach ($file in $payload) {
    $relative = $file.FullName.Substring($appRoot.Length + 1)
    $destination = Join-Path $installedRoot $relative
    if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "Installer omitted $relative" }
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw "Installed content differs: $relative"
    }
}
Write-Host "Installer payload verified: $($payload.Count) files, including subdirectories."
$fixture = Join-Path $verificationRoot 'fixture'
New-Item -ItemType Directory -Path $fixture | Out-Null
$testProcess = Start-Process -FilePath (Join-Path $installedRoot 'DescriptionEditForWindows.exe') -ArgumentList ('"' + $fixture + '"') -PassThru -WindowStyle Hidden
try {
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 250
        $testProcess.Refresh()
        if ($testProcess.HasExited) { throw "Packaged application exited early: $($testProcess.ExitCode)" }
        if ($testProcess.MainWindowHandle -ne 0 -and $testProcess.MainWindowTitle.Contains($fixture)) { break }
    }
    if ($testProcess.MainWindowHandle -eq 0 -or -not $testProcess.MainWindowTitle.Contains($fixture)) {
        throw "Packaged application did not open the test folder (PID $($testProcess.Id))."
    }
    $modules = @($testProcess.Modules)
    foreach ($moduleName in @('coreclr.dll', 'Microsoft.UI.Xaml.dll')) {
        $module = $modules | Where-Object { $_.ModuleName -ieq $moduleName }
        if (-not $module -or -not $module.FileName.StartsWith($installedRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Runtime was not loaded from the release payload: $moduleName"
        }
        Write-Host "Bundled runtime loaded: $moduleName"
    }
    Write-Host 'Packaged application opened the isolated test folder successfully.'
} finally {
    if (-not $testProcess.HasExited) {
        $null = $testProcess.CloseMainWindow()
        if (-not $testProcess.WaitForExit(5000)) { Write-Warning "Test process still open: $($testProcess.Id)" }
    }
}
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText($zipPath + '.sha256', $hash + '  ' + [IO.Path]::GetFileName($zipPath) + "`r`n", [Text.Encoding]::ASCII)
[ordered]@{ version = $version; zip = $zipPath; sha256 = $hash; zipBytes = (Get-Item -LiteralPath $zipPath).Length; installedBytes = ($payload | Measure-Object Length -Sum).Sum; slimPreview = [bool]$SlimPreview; payloadFiles = $payload.Count; installedExecutable = (Join-Path $installedRoot 'DescriptionEditForWindows.exe'); verificationRoot = $verificationRoot; startup = 'passed'; bundledRuntimes = 'passed'; installerCopy = 'passed' } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $verificationRoot 'verification.json') -Encoding UTF8
Write-Host "Release verification passed. Evidence: $verificationRoot"
