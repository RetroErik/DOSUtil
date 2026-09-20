# Description Edit for Windows

A modern WinUI 3 `DESCRIPT.ION` editor and file browser for Windows 11. It is the Windows companion to the DOS [DEDIT](../DEDIT/README.md) utility, with first-class descriptions for folders and files, Unicode support, safe backups, removal of stale `MISSING` lines, and direct navigation of local, mapped, and UNC network paths.

By **Dag Erik Hagesæter / Retro Erik using Codex in VS Code** — [YouTube: Retro Hardware and Software](https://www.youtube.com/@RetroErik)

![Platform](https://img.shields.io/badge/Platform-Windows%2011%20x64-blue)
![UI](https://img.shields.io/badge/UI-WinUI%203-0078D4)
![Runtime](https://img.shields.io/badge/Runtime-.NET%2010-purple)
![Language](https://img.shields.io/badge/Language-C%23-orange)
[![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-green)](LICENSE)

## Overview

Description Edit for Windows opens a directory together with its `DESCRIPT.ION`. The main WinUI table includes every real subdirectory and file—even entries without descriptions—and retains stale description lines as `MISSING` until they are explicitly deleted. Edit descriptions directly, press `Ctrl+S`, and move between folders without leaving the application.

### Product names

- **DEDIT** is the original DOS editor in `../DEDIT`.
- **DEDITWIN** is the name reserved for the earlier Windows version that did not use WinUI 3. Its source is not included in this directory.
- **Description Edit for Windows** is this WinUI 3 application.

| Component | Details |
|-----------|---------|
| **Target platform** | Windows 11 x64 |
| **User interface** | WinUI 3 / Windows App SDK 2.4.0 stable |
| **Runtime** | .NET 10 |
| **Descriptions** | Norton/4DOS-compatible `DESCRIPT.ION` |
| **Folder support** | Full display and editing support |
| **Network support** | UNC paths and mapped network drives |
| **Encoding** | UTF-8, UTF-16 LE/BE, and legacy Windows ANSI input; UTF-8 BOM output |
| **Backup behavior** | Safe temporary write plus `DESCRIPT.BAK` |

## Features

- Modern Fluent/WinUI 3 appearance with light and dark theme support.
- Uses DES/4DOS `ColorDir` rules to color folders and file types.
- Starts with `dirs:bri mag; zip arj:bri blu; com exe:bri gre; bat:bri red; gif jpg png:yel; txt me now:gre`.
- Lets each user change or restore the colors from **Colors…**.
- Uses English interface text on every Windows display language.
- Shows real folders first, then files, then stale `MISSING` entries.
- Displays Name, Type, Size, Modified, attributes, Description, and Status.
- Edits folder and file descriptions directly in each row.
- Deletes one `MISSING` line with its row button.
- Deletes multiple selected `MISSING` lines from the command bar or with `Delete`.
- Keeps deleted lines out of the next saved `DESCRIPT.ION`.
- Double-clicks folders to browse into them and files to open them through Windows.
- Supports Back, Up, Refresh, typed paths, and folder/file picker dialogs.
- Accepts UNC paths such as `\\server\share\games` in the path field.
- Enumerates directories on a worker thread so network access does not block the UI thread.
- Warns before discarding unsaved edits.
- Restores the current row's original description when `Esc` is pressed.
- Finishes the current row edit in memory when `Enter` is pressed; nothing is written until Save.
- Detects external changes before overwriting a sidecar.
- Supports column sorting while retaining folders/files/`MISSING` grouping.
- Supports quoted long names, doubled quotes, Unicode, and Ctrl-D metadata suffixes.
- Can associate `.ION` files with the installed application for the current user.
- Requires no administrator privileges for application installation or association.

## Quick Start

### Install from the release ZIP

The release ZIP is self-contained for Windows 11 x64. The user does not need Visual Studio, the .NET SDK, or a separate Windows App Runtime installation.

1. Download `DescriptionEditForWindows-1.0.3-win-x64.zip`.
2. Extract the entire ZIP to a normal folder. Do not run the program from inside the ZIP viewer.
3. Double-click `Install.cmd`.
4. Start **Description Edit for Windows** from the Start Menu.

Installation is per-user, needs no administrator rights, and copies the application to `%LOCALAPPDATA%\Programs\Retro Erik\Description Edit for Windows`. It also creates a Start Menu shortcut and registers `.ION` files. Windows may ask the user to confirm the default application.

For portable use, skip installation and run `app\DescriptionEditForWindows.exe` from the extracted folder. Keep all files in the `app` directory together.

### Requirements for building

- Windows 11 x64.
- .NET 10 SDK.
- Internet access for the initial restore of the official `Microsoft.WindowsAppSDK` 2.4.0 NuGet package.

### Build and test

From this directory:

```text
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Configuration Release
```

The executable is created under:

```text
src\DescriptionEditForWindows\bin\x64\Release\net10.0-windows10.0.19041.0\win-x64\DescriptionEditForWindows.exe
```

The build script also runs the dependency-free core tests.

### Create the release ZIP

```text
powershell -ExecutionPolicy Bypass -File .\package.ps1
```

This publishes a self-contained x64 application and creates:

```text
artifacts\DescriptionEditForWindows-1.0.3-win-x64.zip
```

### Install a source build for the current user

No elevated prompt is needed:

```text
powershell -ExecutionPolicy Bypass -File .\tools\Install.ps1
```

This builds when needed, copies the WinUI output to `%LOCALAPPDATA%\Programs\Retro Erik\Description Edit for Windows`, creates a Start Menu shortcut, and registers `.ION` for the current user.

Optional installation switches:

```text
.\tools\Install.ps1 -SkipFileAssociation
.\tools\Install.ps1 -SkipStartMenuShortcut
```

### Run without installing

```text
.\src\DescriptionEditForWindows\bin\x64\Release\net10.0-windows10.0.19041.0\win-x64\DescriptionEditForWindows.exe
.\src\DescriptionEditForWindows\bin\x64\Release\net10.0-windows10.0.19041.0\win-x64\DescriptionEditForWindows.exe C:\GAMES
.\src\DescriptionEditForWindows\bin\x64\Release\net10.0-windows10.0.19041.0\win-x64\DescriptionEditForWindows.exe \\server\share\games\DESCRIPT.ION
```

### Uninstall

From an extracted release ZIP, double-click `Uninstall.cmd`. From a source checkout, run:

```text
powershell -ExecutionPolicy Bypass -File .\tools\Uninstall.ps1
```

## Using the Editor

The Description field is editable. Enter the description and press `Ctrl+S` or choose **Save**.

| Action | Result |
|--------|--------|
| Double-click a folder | Open the folder and its `DESCRIPT.ION` |
| Double-click a file | Open it through Windows |
| Back / Up | Navigate through folders |
| Refresh | Reload the directory and sidecar |
| Save / `Ctrl+S` | Safely write descriptions and create a backup |
| `Enter` in a description | Finish editing the row in memory without saving the file |
| `Esc` in a description | Cancel the current row edit and restore its previous text |
| Clear a description | Remove it from the next saved sidecar |
| Click **Delete** on a `MISSING` row | Remove that stale line |
| Select stale rows and choose **Delete selected MISSING** | Remove all selected stale lines |
| Select stale rows and press `Delete` | Remove all selected stale lines |
| Type a path and press `Enter` | Open a local, mapped, or UNC path |

Deleting a `MISSING` row changes only the in-memory document initially. The line is removed permanently when the document is saved. Normal file and folder rows cannot be deleted through this command.

The `.ION` association can be registered or removed from the command bar's overflow menu. Association means files ending in `.ion`—especially `DESCRIPT.ION`—open in Description Edit for Windows when double-clicked. It does not refer to the files being described.

## Colors and Language

Choose **Colors…** in the overflow menu to edit the `ColorDir` rule. The syntax matches DES and 4DOS: put extensions before `:`, use `bri` for a bright color, and separate rules with semicolons. `dirs` controls folders. The setting is stored for the current user under `%LOCALAPPDATA%\Retro Erik\Description Edit for Windows\ColorDir.txt`.

All menus, dialogs, status messages, and controls are shown in English regardless of the Windows display language.

## Network Folders

Mapped drives work like local drives. For an unmapped share, type its UNC path:

```text
\\server\share
\\nas\retro\dos-games
```

The current Windows account must already have access. If credentials are required, connect to the share in Windows first. Saving requires create, rename, and delete permission because the editor writes a temporary file and rotates the backup.

Network servers and NAS devices vary in their atomic replacement support. Description Edit for Windows first attempts `File.Replace`; if unsupported, it uses a same-directory rename sequence and attempts to restore the original if the final rename fails.

## DESCRIPT.ION Format

Names without spaces can be written directly. Names containing spaces are quoted:

```text
MONKEY.EXE Monkey Island  1990 EGA/VGA/ADLIB
GAMES DOS games and utilities
"Blå mappe" Norske programmer
"Long file name.txt" Notes for this file
```

Matching is case-insensitive. A doubled quote inside a quoted name represents one literal quote. Only the visible field before an optional Ctrl-D (`04h`) metadata separator is displayed.

Input decoding order:

1. UTF-8 BOM.
2. UTF-16 little-endian or big-endian BOM.
3. Strict BOM-less UTF-8.
4. The active Windows ANSI code page.

Saved files use UTF-8 with a BOM.

## Safe Save and Backups

For `DESCRIPT.ION`, saving performs these operations in the same directory:

1. Write and flush the complete content to `DESCRIPT.$$$`.
2. Replace `DESCRIPT.ION` only after the temporary file is complete.
3. Preserve the previous file as `DESCRIPT.BAK`.
4. Restore the original when possible if a rename-based fallback fails.
5. Mark the saved description file and its backup as hidden.

For another `.ion` filename, the editor uses `<filename>.tmp` and `<filename>.bak`.

## Technical Notes

- The solution separates the platform-neutral editor core from the WinUI application.
- Directory enumeration runs in a worker task and does not recursively scan a share.
- `DESCRIPT.ION`, `DESCRIPT.BAK`, and `DESCRIPT.$$$` are omitted from editable rows.
- Empty descriptions are not written.
- Duplicate input names resolve to the last case-insensitive entry.
- The sidecar timestamp and length are recorded to detect external modification.
- Per-user association is stored under `HKCU\Software\Classes`.
- The project uses the supported Windows App SDK 2.4.0 stable channel, not a preview or experimental build.

## Known Issue

On some systems, the physical mouse wheel does not scroll the list while the pointer is over the right-hand Description or Status area. Scrolling works when the pointer is over the left-hand columns; the scroll bar, keyboard navigation, and all editing features remain usable. This is a known limitation of the current release.

## Project Layout

| Path | Purpose |
|------|---------|
| `DescriptionEditForWindows.sln` | Visual Studio solution |
| `src/DescriptionEditForWindows/` | Modern WinUI 3 application |
| `src/DescriptionEditForWindows.Core/` | Platform-neutral parser, models, directory merge, and safe save |
| `tests/DescriptionEditForWindows.Tests/` | Parser, folder, stale-line deletion, backup, Unicode, and path tests |
| `tools/Install.ps1` | Per-user installation and association |
| `tools/Uninstall.ps1` | Per-user removal |
| `build.ps1` | Restore, build, and test entry point |
| `package.ps1` | Self-contained release ZIP creator |

## Screenshots

No release screenshot is included yet. A useful screenshot should show the WinUI interface, Unicode folder descriptions, selection of several stale rows, and the `MISSING` delete controls.

## Testing

Automated tests cover parsing, Unicode serialization, folders, files, missing entries, deletion of stale lines, ordering, safe backup creation, external-change detection, and UNC syntax.

Before release, also test manually with:

- A writable Windows share and a NAS share.
- A read-only share and disconnected mapped drive.
- A directory containing thousands of entries.
- Unicode folder and file names.
- Concurrent editing of `DESCRIPT.ION`.
- Single and multiple `MISSING` deletion followed by save.
- Double-click association from Windows Explorer.

## Credits

- **Author:** Dag Erik Hagesæter / Retro Erik
- **Development:** By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
- **DOS inspiration:** [DEDIT 1.0](../DEDIT/README.md)
- **Related directory utility:** [DES 1.1](../DES/README.md)

## License

This project is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](LICENSE).

## Contributing

Bug reports and network-share testing are welcome. Include Windows version, server or NAS type, path form, sidecar encoding, permissions, and the exact error shown.

---

## YouTube

For more retro computing content, visit **Retro Hardware and Software**:
[https://www.youtube.com/@RetroErik](https://www.youtube.com/@RetroErik)
