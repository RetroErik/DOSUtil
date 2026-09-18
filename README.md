# DOS Utilities and Programs

A collection of DOS programs and startup configurations created by **Dag Erik Hagesaeter / Retro Erik**.

[YouTube: Retro Hardware and Software](https://www.youtube.com/@RetroErik)

![Platform](https://img.shields.io/badge/Platform-MS--DOS-blue)
![Language](https://img.shields.io/badge/Environment-DOS-orange)

## Contents

So far, this repository contains a DOS directory utility, a hotkey force-quit TSR, and
the startup files for a PicoMEM-based DOS system:

| Directory | Description |
|-----------|-------------|
| [`DES/`](DES/) | DES, a fast DOS directory utility with 4DOS-compatible descriptions and colors |
| [`QUITKEY/`](QUITKEY/) | QuitKey, a TSR that force-quits DOS games with no exit option via a hotkey |
| [`PicoMEM/`](PicoMEM/) | `AUTOEXEC.BAT`, `CONFIG.SYS`, and documentation for selectable PicoMEM DOS startup profiles |

See the [DES README](DES/README.md) for build instructions, usage, features, and testing information.

See the [QuitKey README](QUITKEY/README.md) for how it works, usage, and game compatibility notes.

See the [PicoMEM startup files README](PicoMEM/README.md) for installation instructions, boot profiles, memory configuration, CD-ROM support, and required utilities.

## DES

[DES (Description Enhanced System)](DES/) is a small, fast DOS directory utility and a practical replacement for the DOS/4DOS `DIR` command. It supports 4DOS-compatible `DESCRIPT.ION` file descriptions, `COLORDIR` colors, alphabetical sorting, pagination, and redirected output.

Open the [DES project documentation](DES/README.md) for build instructions, usage examples, technical notes, and test information.

## QuitKey

[QuitKey](QUITKEY/) is a small DOS TSR for old games that have no way to quit back to DOS. Once installed, pressing Ctrl+Alt+Q or F12 force-quits whatever program is currently running and returns straight to DOS, as if it had exited normally.

Open the [QuitKey project documentation](QUITKEY/README.md) for how it works, usage, limitations, and which kinds of games it tends to work with.

## Other Repositories

Related DOS utilities, graphics programs, and demos are available in these repositories:

| Repository | Description |
|------------|-------------|
| [CGA-Composite-to-VGA](https://github.com/RetroErik/CGA-Composite-to-VGA) | A DOS TSR that gives CGA composite games 16 colors on many VGA systems |
| [PalSwap](https://github.com/RetroErik/PalSwap) | `PalSwap` and `PalSwapT`, programs that set the CGA palette to any color from the EGA (64) or VGA (256) palette |
| [Plantronics-BMP-Viewer](https://github.com/RetroErik/Plantronics-BMP-Viewer) | A BMP image viewer for Plantronics graphics cards; supports uncompressed 320x200, 16-color BMP files |
| [Boing-Plantronics](https://github.com/RetroErik/Boing-Plantronics) | An Amiga Boing ball demo written in assembly for PC and Plantronics graphics |

## Project Status

This collection is growing. Additional DOS programs and configurations may be added over time.
