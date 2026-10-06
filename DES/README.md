# DES 1.3 - Description Enhanced System

A small, fast DOS `.COM` program written in NASM 8086 assembly. DES is a practical replacement for the DOS/4DOS `DIR` command, with support for 4DOS-compatible `DESCRIPT.ION` file descriptions and `COLORDIR` colors.

**By Dag Erik Hagesæter / Retro Erik using Codex in VS Code** - [YouTube: Retro Erik](https://www.youtube.com/@RetroErik)

![Platform](https://img.shields.io/badge/Platform-MS--DOS-blue)
![CPU](https://img.shields.io/badge/CPU-8086%2F8088-green)
![Language](https://img.shields.io/badge/Language-NASM%20assembly-orange)
[![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-green)](LICENSE)

## Overview

DES lists files and directories in the current DOS directory or in a directory selected by a path or wildcard. Directories are shown first, followed by files sorted alphabetically without regard to case.

The program is designed for small, real-mode DOS systems:

| Component | Details |
|-----------|---------|
| **Target platform** | MS-DOS and compatible DOS systems |
| **Executable format** | `.COM` |
| **Executable size** | 6,026 bytes (version 1.3) |
| **CPU target** | Intel 8086/8088-compatible instructions |
| **Assembler** | NASM |
| **Maximum entries** | 400 files and directories |
| **Descriptions** | 4DOS-compatible `DESCRIPT.ION` |
| **Colors** | `COLORDIR` rules read directly by DES |
| **Output** | DOS console, with safe fallback for redirected output |

## Features

- Lists files and directories with directories first.
- Sorts entries alphabetically, case-insensitively.
- Displays `<DIR>` for directories and file sizes rounded up to KB.
- Reads `DESCRIPT.ION` once into memory and matches descriptions to files.
- Supports `/P` pagination, one screen at a time.
- Accepts a drive-only path such as `D:` and lists that drive's current directory, as `DIR D:` does.
- Accepts a directory path such as `D:\GAMES` or `D:\GAMES\` without requiring `*.*`.
- Excludes hidden and system entries by default; `/A` includes them and marks their attributes with `H` and `S` beside the name.
- Optionally shows the selected drive's kind and FAT type with `/I`.
- Warns when more than 400 matching entries are found, so an incomplete listing is visible.
- Scrolls descriptions that are longer than the available line width when `/P` is active.
- Reads and applies 4DOS-style `COLORDIR` rules without requiring 4DOS.
- Does not require `ANSI.SYS` or `ANSI.COM`.
- Does not calculate free disk space, avoiding the slow free-space calculation that can delay `DIR` on some FAT16 systems.
- Supports `/H` and `/?` help screens.
- Preserves useful output when standard output is redirected to a file or pipe.

## Quick Start

### Requirements

- NASM, if you want to rebuild the program.
- DOSBox or a real DOS-compatible computer, if you want to run it.

### Build

From this directory:

```text
nasm -f bin des.asm -o DES.COM
```

The resulting executable is a small, self-contained DOS `.COM` program.

### Run in DOSBox

On Windows, run:

```text
RUN_DOSBOX.BAT
```

This opens DOSBox and mounts the project directory as drive `C:`. At the DOS prompt, try:

```text
DES
DES *.EXE
DES /P
DES /A
DES /I
DES /H
```

You can also run the compiled program from another DOS environment by copying `DES.COM` to the directory you want to inspect.

## Usage

```text
DES                  List *.* in the current directory
DES *.EXE            List matching files
DES D:               List *.* in D:'s current directory
DES D:\*.*           List *.* in D:'s root directory
DES D:\GAMES          List *.* in D:\GAMES
DES D:\GAMES\         Also list *.* in D:\GAMES
DES C:\GAMES\*.*     List a directory using a path and wildcard
DES /A               Include hidden and system files and directories
DES D:\GAMES /A      Include hidden and system entries in D:\GAMES
DES /P               Pause after each screen
DES *.EXE /P         Combine a wildcard with pagination
DES /I               Show drive kind and file system for the current drive
DES D: /I            Show drive information for D: and list its current directory
DES /I D:\GAMES      Show D: information and list D:\GAMES
DES /H               Show help
DES /?               Show help
```

The `/P`, `/A`, and `/I` switches may appear before or after the path pattern. `D:` does not change the current drive. DOS keeps a current directory for each drive, so `D:` and `D:\` can refer to different directories. With no `/A`, DES omits hidden and system entries. With `/A`, an `H` or `S` appears beside an entry's name for each matching attribute; both letters appear when both attributes are set. `DESCRIPT.ION`, `DESCRIPT.OLD`, and `DESCRIPT.BAK` remain omitted even with `/A`.

`/I` adds two lines to the header: **Drive kind** (`Fixed disk`, `Removable disk`, `CD-ROM`, `Network drive`, `SUBST drive`, or `Unknown`) and **File system** (`FAT12`, `FAT16`, `FAT32`, or `Unknown`). DES queries the drive named by the path, not necessarily the current drive. The FAT type is the DOS-visible volume type; emulators and DOS sessions may present a virtual FAT volume over a different host file system. For CD-ROMs and network drives, DES reports the file system as `Unknown`; a DOS drive letter does not reliably reveal the underlying format. USB storage may appear as fixed or removable according to its DOS driver. Unsupported DOS calls also result in `Unknown`. With `/P`, the two added lines count toward the first page.

For example, `/I` on a FAT12 floppy shows:

```text
 Drive kind: Removable disk
 File system: FAT12
```

DES stores at most 400 matching entries. If more are found, it shows a warning after the listing and returns DOS error level 1. Exactly 400 entries do not trigger the warning.

## Why DES Can Be Faster Than DIR

On some older DOS systems, especially DOS 4 and later using large FAT16
volumes, `DIR` may spend a long time calculating free disk space before it
prints the directory listing. DES does not calculate or display free disk
space. It can therefore avoid that particular delay and begin listing the
directory much sooner.

This is an intentional design choice, not a replacement for every use of
`DIR`. Programs that need a free-space value still need to request it from
DOS. DES is faster in this specific situation because it does not perform
that extra operation.

### FREESP and FREESPT

`FREESP.COM` and `FREESPT.COM` are separate utilities by **ChartreuseK** that
address the same slow DOS free-space calculation while continuing to use
`DIR` or other programs that ask DOS for free space:

- [`FREESP`](https://github.com/ChartreuseK/FREESP) is the non-TSR version.
	Run it for a drive, for example `FREESP C`, to calculate the free space and
	populate DOS's cached value before using `DIR`. It is intended for FAT16
	systems and DOS 4.0 or later.
- [`FREESPT`](https://github.com/ChartreuseK/FREESP) is the TSR version. It
	intercepts DOS `INT 21h/AH=36h` free-space requests and calculates the value
	when needed. It can monitor multiple drives, for example `FREESPT CDEF`.

The [FREESP releases](https://github.com/ChartreuseK/FREESP/releases) provide
pre-assembled `.COM` files. The project is also discussed in the
[VOGONS technical thread](https://www.vogons.org/viewtopic.php?t=78816) and
covered in [this Genesis8 article](https://www.genesis8bit.fr/archives/index.php?news_id=2139).

DES does not need FREESP or FREESPT for its own directory listings because it
does not calculate free space. These utilities remain useful if you want to
keep using `DIR`, 4DOS, or other programs that depend on DOS free-space
queries.

## DESCRIPT.ION

DES reads a `DESCRIPT.ION` file from the directory being listed. Each description uses the familiar 4DOS format:

```text
MONKEY.EXE Monkey Island  1990 EGA/VGA/ADLIB
```

`DESCRIPT.ION`, `DESCRIPT.OLD`, and `DESCRIPT.BAK` are not displayed in the file list.

## COLORDIR

DES can read the `COLORDIR` environment variable itself. 4DOS is not required. For example:

```text
SET ColorDir=dirs:bri mag; zip arj:bri blu; com exe:bri gre; bat:bri red; gif jpg png:yel; txt me now:gre
```

Directory rules use `dirs`; file rules use extensions. DES applies colors directly on supported local text screens and falls back to ordinary DOS output when output is redirected or the video mode is not supported.

See [Colordir readme.md](Colordir%20readme.md) for the more detailed ColorDir notes.

## Related Projects

[DEDIT - DESCRIPT.ION Editor](../DEDIT/README.md) is DES's full-screen companion
editor. It shows every file and directory, identifies missing descriptions and
stale entries, and safely maintains the `DESCRIPT.ION` files displayed by DES.

## Technical Notes

- The source intentionally uses 8086/8088-compatible instructions. It avoids 186+, 286+, and 386-only instructions.
- DES is a `.COM` program and uses the DOS program segment for runtime buffers, keeping the executable small.
- File entries are collected with DOS `Find First` / `Find Next` calls and sorted in memory.
- Before searching, DES expands `D:` to `D:*.*` or an existing directory path to `<directory>\*.*`. File names and wildcard patterns are used unchanged. The directory path is also used to find `DESCRIPT.ION` and build the displayed header.
- DOS Find First includes directories by default. `/A` adds hidden and system attribute bits to that search; DES also filters those entries from the normal listing if DOS returns them.
- `/I` checks MSCDEX for CD-ROMs, DOS IOCTL for network, SUBST, fixed, and removable drives, and DOS drive parameter blocks for FAT type. It does not read raw disk sectors or calculate free space.
- `DESCRIPT.ION` is loaded once rather than reopened for every file.
- On a supported 80-column text screen, colored lines are written directly to video memory for speed.
- Direct video writes are disabled when standard output is redirected, so commands such as `DES > listing.txt` continue to work.
- Long descriptions are animated together during `/P` pauses. Press a key to continue.

## Project Layout

| Path | Purpose |
|------|---------|
| `des.asm` | NASM source code |
| `DES.COM` | Compiled DOS program |
| `RUN_DOSBOX.BAT` | Windows DOSBox launcher |
| `oppstart-dosbox.conf` | DOSBox configuration for interactive use |
| `Screenshots/` | Screenshots of DES running on real DOS hardware |
| `test/` | Test files, directories, descriptions, and DOSBox configurations |
| `versions/v1.0/` | Archived first stable version |
| `versions/v1.1/` | Archived 1.1 source and executable |
| `versions/v1.2/` | Archived 1.2 source and executable |

## Screenshots

*DES 1.1 help screen running on real hardware:*

<p>
<img src="Screenshots/DES%20Help%20screen.png" width="80%" alt="DES help screen">
</p>

*DES 1.1 directory listing with the `/P` pagination switch on real hardware:*

<p>
<img src="Screenshots/DES%20directory%20listing%20with%20parameter%20p.png" width="80%" alt="DES directory listing with pagination">
</p>

## Documentation

The source file contains extensive implementation notes and is the primary technical reference for the program. Historical comments remain in Norwegian; new comments are in English.

## Testing

The `test` directory contains fixture files, directories, descriptions, and DOSBox configurations for testing sorting, pagination, scrolling, colors, and redirected output.

For drive-only parsing, compare `DES D:` with `DIR D:` while the current directory on D: is not the root. Also check `DES D:\*.*` and `DES D: /P`.

For directory paths, compare `DES D:\GAMES`, `DES D:\GAMES\`, and `DES D:\GAMES\*.*`. For attributes, check that hidden and system entries are absent by default and present with `DES /A`; repeat with `/A` before and after a path. Check `H`, `S`, and `HS` markers. The three `DESCRIPT.*` metadata files should stay hidden in both modes.

Check the entry limit with 400 and 401 matching files. The first listing should complete without a warning; the second should warn and return error level 1. Repeat with hidden files to confirm the warning counts only entries eligible for the selected `/A` setting.

For attribute tests in DOSBox 0.74-3, use a FAT image with `IMGMOUNT` or a real DOS disk. In testing, a host folder mounted with `MOUNT` did not expose Windows Hidden and System flags to DOS programs.

For `/I`, check a FAT12 floppy image, a local hard disk, and a CD-ROM; compare the reported drive letter with `DES D: /I` and `DES /I D:\GAMES`. Where the DOS driver cannot identify the format, check that DES reports `Unknown` rather than a guessed FAT type. Repeat with `/P` to check the first page height, and with output redirected to a file.

When changing the scrolling or direct-video code, test at least:

- Several pages of entries.
- Two or more long descriptions on the same page.
- A final partial page.
- Redirected output, for example `DES /P > output.txt`.

## Credits

- **Author:** Dag Erik Hagesæter / Retro Erik
- **Development assistance:** GitHub Copilot
- **Version 1.3 attribution:** By Dag Erik Hagesæter / Retro Erik using Codex in VS Code

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)**. You may use and modify DES for non-commercial purposes, provided that you give appropriate credit to Dag Erik Hagesæter / Retro Erik.

## Contributing

Bug reports, DOS compatibility testing, documentation improvements, and pull requests are welcome. Please include the DOS version, machine or emulator, command used, and observed output when reporting a problem.

---

## YouTube

For more retro computing content, visit **Retro Hardware and Software**:
[https://www.youtube.com/@RetroErik](https://www.youtube.com/@RetroErik)
