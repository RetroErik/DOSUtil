# Self-contained package size investigation

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
https://www.youtube.com/@RetroErik

## Promotion to 1.0.7

The component selection investigated below is the default from version 1.0.7.
The author accepted the completed local checks and explicitly waived additional
testing, including a clean-machine test. Version 1.0.7 is built and published
without rerunning the UI/core suites. The measurements and commands below record
the historical opt-in experiment at commit `d4327b3`; the current packaging entry
point is simply `package.ps1`. The previous 1.0.6 release remains preserved.

## Result — 2026-11-20

A component-based Windows App SDK trial reduced the ZIP download by **23.73%**,
while keeping both .NET and the Windows App Runtime bundled. No application
behavior, source XAML, SDK component version, or public release was changed.

| Measurement | Published 1.0.6 | Slim preview |
|---|---:|---:|
| ZIP bytes | 94,071,252 | 71,752,491 |
| ZIP size (decimal MB) | 94.1 | 71.8 |
| ZIP size (MiB) | 89.7 | 68.4 |
| Extracted bytes, including documentation | 234,907,921 | 180,456,734 |
| Extracted size (decimal MB) | 234.9 | 180.5 |
| Files in the ZIP | 530 | 467 |
| Application files verified by the installer check | 522 | 458 |

The preview saves **22,318,761 download bytes** and **54,451,187 extracted bytes**.
The original ZIP still has SHA-256:

```text
5817621b7c5d827282dcdd777bdf2ed8742cf119b0ee317ddec1e91c73682f69
```

## What changed

The normal build still references `Microsoft.WindowsAppSDK` 2.4.0. Only when
`UseSlimWinUI=true` is supplied does the project use these component packages:

| Component | Version |
|---|---|
| Microsoft.WindowsAppSDK.WinUI | 2.3.6 |
| Microsoft.WindowsAppSDK.InteractiveExperiences | 2.1.6 |
| Microsoft.WindowsAppSDK.DWrite | 2.1.0 |
| Microsoft.WindowsAppSDK.Runtime | 2.4.0 |
| Microsoft.WindowsAppSDK.Foundation (transitive) | 2.3.9 |
| Microsoft.WindowsAppSDK.Base (transitive) | 2.0.4 |

These match the versions resolved by the published umbrella package. Component
selection removes AI/ML, Search, and Widgets dependencies from the NuGet graph;
DLLs are not manually deleted after publishing. The app uses no APIs from the
removed components. Microsoft describes component references as the way to avoid
unused native SDK dependencies in [Windows App SDK issue #6015](https://github.com/microsoft/WindowsAppSDK/issues/6015).

Some of the removed files:

| File | Uncompressed bytes |
|---|---:|
| onnxruntime.dll | 21,659,280 |
| DirectML.dll | 18,700,224 |
| Microsoft.Windows.Search.dll | 3,379,512 |
| Microsoft.Windows.Widgets.dll | 2,469,688 |
| PerceptiveStreaming.dll | 1,759,008 |
| Microsoft.Windows.AI.MachineLearning.dll | 903,464 |

The .NET runtime, WinUI controls, graphics dependencies, localization files, and
compiled app PRI/XBF resources remain included. There is no .NET trimming,
Native AOT conversion, SDK upgrade, or change to the unpackaged install model.
See Microsoft's [self-contained deployment guidance](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/self-contained-deploy/deploy-self-contained-apps).

## Reproduce

Run from the application directory:

```text
powershell -ExecutionPolicy Bypass -File .\package.ps1 -SlimPreview
powershell -ExecutionPolicy Bypass -File .\tools\Test-ReleasePackage.ps1 -ZipPath .\artifacts\DescriptionEditForWindows-1.0.6-slim-preview-win-x64.zip -SlimPreview
```

The packaging script refuses to overwrite an existing ZIP. The experimental
output is named `DescriptionEditForWindows-1.0.6-slim-preview-win-x64.zip` and
contains `EXPERIMENTAL.txt`. Its executable still reports 1.0.6 because this is a
packaging investigation, not a new public version. Do not replace the released
1.0.6 asset with this file.

The verification tool extracts the archive to a fresh workspace directory,
redirects installation into an isolated LocalAppData tree, disables associations
and shortcuts, and hash-verifies every installed app file. It checks the
self-contained .NET metadata and confirms that the running process loads
`coreclr.dll` and `Microsoft.UI.Xaml.dll` from that isolated installation.
It writes `verification.json` and a SHA-256 file for the checked ZIP.

To exercise the exact installed preview, supply the executable path reported in
`verification.json` to the UI test tool:

```text
powershell -ExecutionPolicy Bypass -File .\tools\Test-UI.ps1 -Target local -ApplicationPath "<installed preview path>\DescriptionEditForWindows.exe"
```

This local test moves focus and sends keyboard shortcuts. Leave its window and
the keyboard alone during the run. Without `-ApplicationPath`, the existing UI
test continues to build and launch the normal Debug project.

## Validation

- Slim Release publish: zero warnings and errors.
- Slim Debug build and core tests: passed with zero warnings and errors.
- Normal Debug and Release builds and core tests: passed with zero warnings and
  errors after the experiment; the default dependency selection remains intact.
- ZIP inventory checks: AI/ML, Search, and Widgets payload absent; required
  .NET/WinUI runtime, resources, and icon present.
- Isolated install: all 458 app files hash-verified; startup and bundled runtime
  module-path checks passed.
- UI tests against that exact installed ZIP payload: **9 passed, 0 failed**.
- All four UI screenshots were inspected. The existing normal-folder Delete
  button appearance issue remains; no new layout regression was observed in
  the captured states.

Local evidence:

```text
artifacts/ui-tests/7adda14055034623a8585fc6c10b914d/results.json
../../.release-check-6451781e/verification.json
```

The preview ZIP SHA-256 is:

```text
827ea2da2e419f2394c37854af9a2fde1853206388e7191e431620a220bcf39e
```

## Recommendation and limits

The component-based self-contained approach is a good candidate for the next
release. Before promoting it, test on a clean Windows 11 x64 machine without
preinstalled .NET or Windows App Runtime. The host used here has shared runtimes;
loading bundled modules is strong local evidence but does not replace that clean
machine check. Windows Sandbox is not enabled on this host.

Also retain the existing manual checks for network shares, file pickers,
associations, alternate themes/DPI, and the known physical mouse-wheel issue.
No release was uploaded or replaced, and no change was merged into `main` as
part of this investigation. More aggressive .NET trimming or Native AOT would
be a separate investigation with different compatibility requirements.
