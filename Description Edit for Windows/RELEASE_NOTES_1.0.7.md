# Description Edit for Windows 1.0.7

A smaller self-contained Windows 11 x64 package for the WinUI 3 `DESCRIPT.ION` editor.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
[Retro Erik on YouTube](https://www.youtube.com/@RetroErik)

## Download and install

Download **DescriptionEditForWindows-1.0.7-win-x64.zip** from the release assets.
Extract the entire ZIP, open the extracted folder, and double-click **Install.cmd**.
Start **Description Edit for Windows** from the Start Menu.

For portable use, run `app\DescriptionEditForWindows.exe` and keep the entire
`app` directory together. Both .NET and Windows App Runtime are included;
Visual Studio, the .NET SDK, and separate runtime installation are not required.
Choose the named **win-x64 ZIP**, rather than GitHub's source-code archives.

## Changes from 1.0.6

- Use the same pinned Windows App SDK component versions without the unused
  AI/ML, Search, and Widgets components.
- Reduce the self-contained download from approximately **94 MB to 72 MB**.
  The trial measured a **23.73%** reduction, with extracted files reduced from
  approximately **235 MB to 180 MB**.
- Retain the existing application behavior, .NET/WinUI runtimes, graphics
  dependencies, language resources, and installation model.

The prior 1.0.6 release and its original ZIP remain available for rollback.

## Validation

The component-based trial passed Debug/Release builds, core tests, isolated
installation and bundled-runtime checks, and nine local UI checks against the
trial ZIP. Its four screenshots were reviewed. The author accepted those results
and waived further testing for promotion to 1.0.7. The 1.0.7 package is rebuilt
with its new version number; the test suites were not rerun for this release.
A clean Windows installation without preinstalled runtimes was not tested.

Known issues remain: physical mouse-wheel scrolling may fail over the Description
or Status area on some systems, and a normal folder's Delete button can appear
enabled after removing a MISSING row. The handler rejects non-MISSING entries
and does not delete real files or folders.

A SHA-256 checksum is supplied alongside the ZIP.

Licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).
