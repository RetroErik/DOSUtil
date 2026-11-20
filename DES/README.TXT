DES 1.3 - Description Enhanced System

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
https://www.youtube.com/@RetroErik

A small DOS directory utility with 4DOS-compatible file descriptions,
colors, alphabetical sorting, pagination, and redirected output.

REQUIREMENTS AND INSTALLATION

MS-DOS or a compatible DOS system, Intel 8086/8088 or later.
Extract the ZIP and copy DES.COM to your DOS machine, optionally to a
directory on PATH. No 4DOS, ANSI driver, or assembler is required.
This program runs under DOS, not directly in modern Windows.

USAGE

DES                  List the current directory
DES *.EXE            List matching files
DES C:\GAMES         List another directory
DES /P               Pause between pages; scroll long descriptions
DES /A               Include hidden and system entries
DES /I               Show drive kind and FAT information
DES /H               Show all command-line options
DES > LISTING.TXT     Save plain output to a file

DES reads DESCRIPT.ION descriptions and the COLORDIR environment variable.
It does not modify description files. Use DEDIT to edit descriptions.
At most 400 matching entries are listed. Larger results produce a warning
and DOS error level 1. Free disk space is intentionally not calculated.
DESCRIPT.ION, DESCRIPT.OLD, and DESCRIPT.BAK are omitted even with /A.
Drive information may be Unknown where DOS cannot identify the format.

PACKAGE

DES.COM       Ready-to-run DOS program
README.TXT    This guide (DOS code page 437)
LICENSE.TXT   CC BY-NC 4.0 license information (DOS code page 437)

SOURCE, DOCUMENTATION, AND REPORTING PROBLEMS

https://github.com/RetroErik/DOSUtil/tree/des-v1.3/DES
https://github.com/RetroErik/DOSUtil/issues

Report the DOS version, machine or emulator, command, and observed output.
To rebuild with NASM: nasm -f bin des.asm -o DES.COM
