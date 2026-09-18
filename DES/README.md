# DES 1.1 - Description Enhanced System

A small, fast DOS `.COM` program written in NASM 8086 assembly. DES is a practical replacement for the DOS/4DOS `DIR` command, with support for 4DOS-compatible `DESCRIPT.ION` file descriptions and `COLORDIR` colors.

By **Dag Erik Hagesaeter / Retro Erik** - [YouTube: Retro Hardware and Software](https://www.youtube.com/@RetroErik)

![Platform](https://img.shields.io/badge/Platform-MS--DOS-blue)
![CPU](https://img.shields.io/badge/CPU-8086%2F8088-green)
![Language](https://img.shields.io/badge/Language-NASM%20assembly-orange)
[![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-green)](LICENSE)

## Overview

DES lists files and directories in the current DOS directory or in a directory selected by a path and wildcard. Directories are shown first, followed by files sorted alphabetically without regard to case.

The program is designed for small, real-mode DOS systems:

| Component | Details |
|-----------|---------|
| **Target platform** | MS-DOS and compatible DOS systems |
| **Executable format** | `.COM` |
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
DES /H
```

You can also run the compiled program from another DOS environment by copying `DES.COM` to the directory you want to inspect.

## Usage

```text
DES                  List *.* in the current directory
DES *.EXE            List matching files
DES C:\GAMES\*.*     List a directory using a path and wildcard
DES /P               Pause after each screen
DES *.EXE /P         Combine a wildcard with pagination
DES /H               Show help
DES /?               Show help
```

The `/P` switch may appear before or after the path pattern.

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

## Technical Notes

- The source intentionally uses 8086/8088-compatible instructions. It avoids 186+, 286+, and 386-only instructions.
- DES is a `.COM` program and uses the DOS program segment for runtime buffers, keeping the executable small.
- File entries are collected with DOS `Find First` / `Find Next` calls and sorted in memory.
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

## Screenshots

*DES help screen running on real hardware:*

<p>
<img src="Screenshots/DES%20Help%20screen.png" width="80%" alt="DES help screen">
</p>

*DES directory listing with the `/P` pagination switch on real hardware:*

<p>
<img src="Screenshots/DES%20directory%20listing%20with%20parameter%20p.png" width="80%" alt="DES directory listing with pagination">
</p>

## Documentation

The source file contains extensive implementation notes and is the primary technical reference for the program. The comments and documentation in `des.asm` are written in Norwegian. That is intentional, so that you can use it as a good opportunity to learn a little Norwegian. :-) 

## Testing

The `test` directory contains fixture files, directories, descriptions, and DOSBox configurations for testing sorting, pagination, scrolling, colors, and redirected output.

When changing the scrolling or direct-video code, test at least:

- Several pages of entries.
- Two or more long descriptions on the same page.
- A final partial page.
- Redirected output, for example `DES /P > output.txt`.

## Credits

- **Author:** Dag Erik Hagesaeter (Retro Erik)
- **Development assistance:** GitHub Copilot

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)**. You may use and modify DES for non-commercial purposes, provided that you give appropriate credit to Dag Erik Hagesaeter / Retro Erik.

## Contributing

Bug reports, DOS compatibility testing, documentation improvements, and pull requests are welcome. Please include the DOS version, machine or emulator, command used, and observed output when reporting a problem.

---

## YouTube

For more retro computing content, visit **Retro Hardware and Software**:
[https://www.youtube.com/@RetroErik](https://www.youtube.com/@RetroErik)
