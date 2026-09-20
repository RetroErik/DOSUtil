[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $SkipFileAssociation,
    [switch] $SkipStartMenuShortcut
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$packagedAppDirectory = Join-Path $PSScriptRoot 'app'
$projectRoot = Split-Path $PSScriptRoot -Parent
$buildOutputDirectory = Join-Path $projectRoot 'src\DescriptionEditForWindows\bin\x64\Release\net10.0-windows10.0.19041.0\win-x64'
$sourceDirectory = if (Test-Path -LiteralPath (Join-Path $packagedAppDirectory 'DescriptionEditForWindows.exe')) {
    $packagedAppDirectory
} else {
    $buildOutputDirectory
}
$sourceExe = Join-Path $sourceDirectory 'DescriptionEditForWindows.exe'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\Retro Erik\Description Edit for Windows'
$installedExe = Join-Path $installDirectory 'DescriptionEditForWindows.exe'
$programsDirectory = [Environment]::GetFolderPath('Programs')
$shortcutPath = Join-Path $programsDirectory 'Description Edit for Windows.lnk'
$progId = 'RetroErik.DescriptionEditForWindows.DescriptIon'

if (-not (Test-Path -LiteralPath $sourceExe) -and -not (Test-Path -LiteralPath $packagedAppDirectory)) {
    Write-Host 'Release build not found; building it now.'
    & (Join-Path $projectRoot 'build.ps1') -Configuration Release
    if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
}

if (-not (Test-Path -LiteralPath $sourceExe)) {
    throw "Application files were not found at '$sourceDirectory'."
}

if (-not $PSCmdlet.ShouldProcess($installDirectory, 'Install Description Edit for Windows for the current user')) { return }

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Get-ChildItem -LiteralPath $sourceDirectory -File | Copy-Item -Destination $installDirectory -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Uninstall.ps1') -Destination $installDirectory -Force

if (-not $SkipFileAssociation) {
    $classes = 'HKCU:\Software\Classes'
    New-Item -Path "$classes\.ion\OpenWithProgids" -Force | Out-Null
    Set-Item -Path "$classes\.ion" -Value $progId
    New-ItemProperty -Path "$classes\.ion\OpenWithProgids" -Name $progId -PropertyType Binary -Value ([byte[]]@()) -Force | Out-Null
    New-Item -Path "$classes\$progId\DefaultIcon" -Force | Out-Null
    New-Item -Path "$classes\$progId\shell\open\command" -Force | Out-Null
    Set-Item -Path "$classes\$progId" -Value 'DESCRIPT.ION File'
    Set-Item -Path "$classes\$progId\DefaultIcon" -Value ('"{0}",0' -f $installedExe)
    Set-Item -Path "$classes\$progId\shell\open\command" -Value ('"{0}" "%1"' -f $installedExe)
}

if (-not $SkipStartMenuShortcut) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $installedExe
    $shortcut.WorkingDirectory = $installDirectory
    $shortcut.Description = 'Edit DESCRIPT.ION files on local and network folders'
    $shortcut.Save()
}

Write-Host "Installed Description Edit for Windows at '$installedExe'."
if (-not $SkipFileAssociation) {
    Write-Host 'The per-user .ION association was registered. Windows may ask you to confirm the default app on first use.'
}
