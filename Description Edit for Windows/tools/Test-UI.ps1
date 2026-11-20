[CmdletBinding()]
param([ValidateSet('local')][string] $Target = 'local')

# By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
# Local UI regression checks. All writes are confined to a new disposable fixture.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$projectRoot = Split-Path $PSScriptRoot -Parent
$runRoot = Join-Path $projectRoot ('artifacts\ui-tests\' + [guid]::NewGuid().ToString('N'))
$fixture = Join-Path $runRoot 'fixture'
$sidecar = Join-Path $fixture 'DESCRIPT.ION'
$backup = Join-Path $fixture 'DESCRIPT.BAK'
$results = [Collections.Generic.List[object]]::new()
$screenshots = [Collections.Generic.List[string]]::new()
$appPid = 0
$hwnd = $null
$previousWorkflow = $env:WINAPP_UI_WORKFLOW_ID
$env:WINAPP_UI_WORKFLOW_ID = [guid]::NewGuid().ToString('N')

function Invoke-WinAppChecked {
    param([string[]] $Arguments)
    $output = @(& winapp @Arguments)
    if ($LASTEXITCODE -ne 0) { throw "winapp failed: $($Arguments -join ' ')`n$($output -join "`n")" }
    $output
}

function Invoke-Ui {
    param([string[]] $Arguments)
    if ($Arguments[0] -in @('invoke', 'set-value', 'focus', 'send-keys')) {
        $windows = @(Invoke-WinAppChecked @('ui', 'list-windows', '-a', "$appPid", '--json') | ConvertFrom-Json)
        $main = @($windows | Where-Object { $_.className -eq 'WinUIDesktopWin32WindowClass' })
        Assert-True ($main.Count -eq 1) 'Expected one test application window.'
        $title = [string]$main[0].title
        $separator = $title.IndexOf(' — ', [StringComparison]::Ordinal)
        Assert-True ($separator -ge 0) 'Test window does not identify its current document.'
        $currentDirectory = $title.Substring($separator + 3)
        Assert-True ($currentDirectory.Equals($fixture, [StringComparison]::OrdinalIgnoreCase) -or
            $currentDirectory.StartsWith($fixture + '\', [StringComparison]::OrdinalIgnoreCase)) `
            'Test window left its disposable fixture; stopping before further input.'
    }
    Invoke-WinAppChecked (@('ui') + $Arguments + @('-a', "$appPid"))
}

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Get-Elements {
    param($Nodes)
    foreach ($node in $Nodes) {
        if ($null -ne $node) { $node; Get-Elements $node.children }
    }
}

function Get-Tree {
    $tree = Invoke-Ui @('inspect', '--json', '--depth', '12') | ConvertFrom-Json
    @(Get-Elements @($tree.windows | ForEach-Object { $_.elements }))
}

function Assert-RowStatus {
    param([string] $Expected)
    $row = @(Get-Tree | Where-Object {
        $_.type -eq 'ListItem' -and @($_.children | Where-Object {
            $_.type -eq 'Edit' -and $_.name -eq 'demo.txt'
        }).Count -eq 1
    })
    Assert-True ($row.Count -eq 1) 'Expected one demo.txt row.'
    $status = @($row[0].children | Where-Object { $_.automationId -eq 'EntryStatus' })
    Assert-True ($status.Count -eq 1) 'Expected one status control.'
    Assert-True ([string]$status[0].name -eq $Expected) "Expected row status '$Expected'."
}

function Save-Screenshot {
    param([string] $Name)
    $path = Join-Path $runRoot $Name
    Invoke-WinAppChecked @('ui', 'screenshot', '-w', "$hwnd", '--output', $path) | Out-Null
    Assert-True ((Get-Item -LiteralPath $path).Length -gt 0) 'Screenshot missing or empty.'
    $screenshots.Add($path)
}

function Test-UI {
    param([string] $Name, [scriptblock] $Action)
    & $Action | Out-Null
    $results.Add(@{ name = $Name; status = 'PASS' })
    Write-Host "PASS $Name"
}

try {
    New-Item -ItemType Directory -Path (Join-Path $fixture 'Games') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $fixture 'demo.txt'), 'Disposable UI test file.')
    [IO.File]::WriteAllText($sidecar, "demo.txt Original description`r`nGONE.ZIP Stale description`r`n", [Text.UTF8Encoding]::new($true))
    $project = Join-Path $projectRoot 'src\DescriptionEditForWindows\DescriptionEditForWindows.csproj'
    $launch = Invoke-WinAppChecked @('run', $project, '-c', 'Debug', '--arch', 'x64', '-p', 'Platform=x64', '--detach', '--devtools', 'off', '--json', '--', $fixture) | ConvertFrom-Json
    Assert-True ([int]$launch.ProcessId -gt 0) 'No application process returned.'
    $appPid = [int]$launch.ProcessId
    Invoke-Ui @('wait-for', 'demo.txt', '--type', 'Edit', '-t', '10000') | Out-Null
    $windows = @(Invoke-Ui @('list-windows', '--json') | ConvertFrom-Json)
    $hwnd = ($windows | Where-Object { $_.title -ne 'PopupHost' } | Select-Object -First 1).hwnd
    Assert-True ($null -ne $hwnd) 'No main window returned.'

    Test-UI 'Initial state and accessible controls' {
        Invoke-Ui @('wait-for', 'PathBox', '--value', $fixture)
        Assert-RowStatus 'Described'
        $controls = @(Get-Tree | Where-Object { $_.type -in @('Button', 'Edit', 'List') })
        Assert-True ($controls.Count -gt 10) 'UI inspection did not return app controls.'
        Assert-True (@($controls | Where-Object { -not $_.automationId }).Count -eq 0) 'Interactive controls lack AutomationIds.'
        Assert-True (@($controls | Where-Object { $_.type -in @('Edit', 'List') -and -not $_.name }).Count -eq 0) 'Text boxes or list lack accessible names.'
        Save-Screenshot '01-initial.png'
    }

    Test-UI 'Status changes immediately when clearing and editing' {
        Invoke-Ui @('set-value', 'demo.txt', '', '--type', 'Edit')
        Assert-RowStatus ''
        Invoke-Ui @('set-value', 'demo.txt', 'Updated description', '--type', 'Edit')
        Assert-RowStatus 'Described'
        Save-Screenshot '02-edited.png'
    }

    Test-UI 'Save persists snapshot and creates backup' {
        Invoke-Ui @('invoke', 'SaveButton')
        Invoke-Ui @('wait-for', 'StatusText', '--value', 'Saved safely.', '--contains', '-t', '5000')
        Assert-True ([IO.File]::ReadAllText($sidecar).Contains('Updated description')) 'Edited text was not saved.'
        Assert-True ([IO.File]::ReadAllText($backup).Contains('Original description')) 'Original backup missing.'
    }

    Test-UI 'Keyboard save and refresh' {
        Invoke-Ui @('set-value', 'demo.txt', 'Keyboard saved description', '--type', 'Edit')
        $editSelector = (Get-Tree | Where-Object { $_.type -eq 'Edit' -and $_.name -eq 'demo.txt' }).selector
        Invoke-Ui @('focus', $editSelector)
        Invoke-Ui @('send-keys', 'ctrl+s', '--target', $editSelector, '--via', 'send-input')
        Invoke-Ui @('wait-for', 'StatusText', '--value', 'Saved safely.', '--contains', '-t', '5000')
        Assert-True ([IO.File]::ReadAllText($sidecar).Contains('Keyboard saved description')) 'Ctrl+S did not save.'
        Invoke-Ui @('focus')
        Invoke-Ui @('send-keys', 'f5', '--via', 'send-input')
        Invoke-Ui @('wait-for', 'demo.txt', '--type', 'Edit', '--value', 'Keyboard saved description', '-t', '5000')
    }

    Test-UI 'Cancel navigation preserves unsaved descriptions' {
        Invoke-Ui @('set-value', 'demo.txt', 'Unsaved description', '--type', 'Edit')
        Invoke-Ui @('set-value', 'PathBox', (Join-Path $fixture 'Games'))
        Invoke-Ui @('invoke', 'GoButton')
        Invoke-Ui @('wait-for', 'DocumentDialog', '-p', 'Name', '--value', 'Unsaved descriptions', '-t', '5000')
        Save-Screenshot '03-unsaved-dialog.png'
        Invoke-Ui @('wait-for', 'SaveButton', '-p', 'IsEnabled', '--value', 'False')
        Invoke-Ui @('wait-for', 'GoButton', '-p', 'IsEnabled', '--value', 'False')
        Invoke-Ui @('invoke', 'Close', '--type', 'Button')
        Invoke-Ui @('wait-for', 'DocumentDialog', '-p', 'Name', '--value', 'Unsaved descriptions')
        Invoke-Ui @('invoke', 'Cancel', '--type', 'Button', '--root', 'DocumentDialog')
        Invoke-Ui @('wait-for', 'demo.txt', '--type', 'Edit', '--value', 'Unsaved description', '-t', '5000')
        Assert-True (-not [IO.File]::ReadAllText($sidecar).Contains('Unsaved description')) 'Cancel wrote unsaved changes.'
    }

    Test-UI 'Save during navigation and Back' {
        Invoke-Ui @('invoke', 'GoButton')
        Invoke-Ui @('wait-for', 'DocumentDialog', '-p', 'Name', '--value', 'Unsaved descriptions', '-t', '5000')
        Invoke-Ui @('invoke', 'Save', '--type', 'Button', '--root', 'DocumentDialog')
        Invoke-Ui @('wait-for', 'PathBox', '--value', (Join-Path $fixture 'Games'), '-t', '5000')
        Assert-True ([IO.File]::ReadAllText($sidecar).Contains('Unsaved description')) 'Navigation save failed.'
        Invoke-Ui @('invoke', 'BackButton')
        Invoke-Ui @('wait-for', 'demo.txt', '--type', 'Edit', '--value', 'Unsaved description', '-t', '5000')
    }

    Test-UI 'External-change conflict Cancel preserves disk content' {
        Invoke-Ui @('set-value', 'demo.txt', 'Conflicting edit', '--type', 'Edit')
        $attributes = [IO.File]::GetAttributes($sidecar)
        [IO.File]::SetAttributes($sidecar, [IO.FileAttributes]::Normal)
        [IO.File]::WriteAllText($sidecar, "demo.txt Externally changed description`r`nGONE.ZIP Stale description`r`n", [Text.UTF8Encoding]::new($true))
        [IO.File]::SetAttributes($sidecar, $attributes)
        Invoke-Ui @('invoke', 'SaveButton')
        Invoke-Ui @('wait-for', 'DocumentDialog', '-p', 'Name', '--value', 'File changed', '-t', '5000')
        Invoke-Ui @('invoke', 'Cancel', '--type', 'Button', '--root', 'DocumentDialog')
        Invoke-Ui @('wait-for', 'SaveButton', '-p', 'IsEnabled', '--value', 'True', '-t', '5000')
        Assert-True ([IO.File]::ReadAllText($sidecar).Contains('Externally changed description')) 'Conflict Cancel overwrote the external file.'
    }

    Test-UI 'Discard reloads external file and stale-row deletion saves' {
        Invoke-Ui @('invoke', 'RefreshButton')
        Invoke-Ui @('wait-for', 'DocumentDialog', '-p', 'Name', '--value', 'Unsaved descriptions', '-t', '5000')
        Invoke-Ui @('invoke', 'Discard', '--type', 'Button', '--root', 'DocumentDialog')
        Invoke-Ui @('wait-for', 'demo.txt', '--type', 'Edit', '--value', 'Externally changed description', '-t', '5000')
        Invoke-Ui @('invoke', 'GONE.ZIP', '--type', 'Button')
        Invoke-Ui @('invoke', 'SaveButton')
        Invoke-Ui @('wait-for', 'StatusText', '--value', 'Saved safely.', '--contains', '-t', '5000')
        Assert-True (-not [IO.File]::ReadAllText($sidecar).Contains('GONE.ZIP')) 'Deleted MISSING line was saved again.'
        Save-Screenshot '04-final.png'
    }

    Test-UI 'Clean window closes normally' {
        Invoke-Ui @('invoke', 'Close', '--type', 'Button')
        $testProcess = Get-Process -Id $appPid -ErrorAction SilentlyContinue
        if ($testProcess) { Assert-True ($testProcess.WaitForExit(5000)) 'App did not close.' }
    }
} catch {
    $results.Add(@{ name = 'UI regression execution'; status = 'FAIL'; detail = "$_" })
    Write-Warning "UI tests stopped: $_"
} finally {
    try { Invoke-WinAppChecked @('ui', 'yield') | Out-Null }
    catch { $results.Add(@{ name = 'Release UI workflow'; status = 'FAIL'; detail = "$_" }) }
    $env:WINAPP_UI_WORKFLOW_ID = $previousWorkflow
}

$failed = @($results | Where-Object { $_.status -eq 'FAIL' }).Count
$reportPath = Join-Path $runRoot 'results.json'
[ordered]@{
    target = $Target; appPid = $appPid; fixture = $fixture
    passed = $results.Count - $failed; failed = $failed
    results = @($results.ToArray()); screenshots = @($screenshots.ToArray())
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-Host "Passed: $($results.Count - $failed); failed: $failed; report: $reportPath"
if ($failed) { exit 1 }
exit 0
