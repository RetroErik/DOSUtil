[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\Retro Erik\Description Edit for Windows'
$programsDirectory = [Environment]::GetFolderPath('Programs')
$shortcutPath = Join-Path $programsDirectory 'Description Edit for Windows.lnk'
$classes = 'HKCU:\Software\Classes'
$progId = 'RetroErik.DescriptionEditForWindows.DescriptIon'

if (-not $PSCmdlet.ShouldProcess($installDirectory, 'Uninstall Description Edit for Windows for the current user')) { return }

$extensionPath = "$classes\.ion"
if (Test-Path -LiteralPath $extensionPath) {
    $current = (Get-Item -LiteralPath $extensionPath).GetValue('')
    if ($current -eq $progId) {
        (Get-Item -LiteralPath $extensionPath).DeleteValue('', $false)
    }
    $openWithPath = "$extensionPath\OpenWithProgids"
    if (Test-Path -LiteralPath $openWithPath) {
        Remove-ItemProperty -LiteralPath $openWithPath -Name $progId -ErrorAction SilentlyContinue
    }
}
Remove-Item -LiteralPath "$classes\$progId" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $shortcutPath -Force -ErrorAction SilentlyContinue

$resolvedParent = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\Retro Erik'))
$resolvedTarget = [IO.Path]::GetFullPath($installDirectory)
if (-not $resolvedTarget.StartsWith($resolvedParent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to remove an unexpected installation path.'
}
Remove-Item -LiteralPath $resolvedTarget -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'Description Edit for Windows was removed for the current user.'
