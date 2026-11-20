# Description Edit for Windows 1.0.6

A WinUI 3 editor and file browser for Norton/4DOS `DESCRIPT.ION` descriptions.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
[Retro Erik on YouTube](https://www.youtube.com/@RetroErik)

## Download and install

Download **DescriptionEditForWindows-1.0.6-win-x64.zip** from the release assets.
This self-contained Windows 11 x64 package includes .NET and the Windows App
Runtime. Visual Studio, the .NET SDK, and a separate Windows App Runtime
installation are not required.

1. Extract the entire ZIP to a normal folder.
2. Open the extracted `DescriptionEditForWindows-1.0.6-win-x64` folder.
3. Double-click `Install.cmd`.
4. Start **Description Edit for Windows** from the Start Menu.

Installation is per-user and does not require administrator rights. It registers
the `.ION` file association; Windows may ask you to confirm the default app.
For portable use, run `app\DescriptionEditForWindows.exe` and keep the complete
`app` folder together. Use `Uninstall.cmd` to remove a per-user installation.

The source-code ZIP and TAR.GZ automatically supplied by GitHub are source
archives. Choose the named **win-x64 ZIP** above for the ready-to-run app.

## Changes

- Correct Windows ANSI decoding on .NET 10, including Windows-1252 characters.
- Update row status immediately when descriptions are edited or cleared.
- Capture save values on the UI thread and prevent overlapping document operations.
- Serialize dialogs and protect pending work during navigation and close requests.
- Improve accessible names and automation identifiers.
- Include WinUI analysis, VS Code build/debug tasks, and regression guidance.
- Preserve asset and runtime subdirectories during installation.
- Protect existing release ZIPs from accidental overwrites.

## Validation and remaining checks

Debug and Release builds and core regression tests passed for the application
changes. Nine local UI checks passed for editing, status, saving, backup contents,
keyboard shortcuts, navigation dialogs, conflict cancellation, stale-line removal,
and closing. See the included `DEVELOPMENT.md` for details and remaining coverage.

Known issues: physical mouse-wheel scrolling may fail over the Description or
Status area on some systems; a Delete button can appear enabled on a normal
folder after removing a MISSING row. The handler rejects non-MISSING rows and
does not delete real files or folders.

Licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).
