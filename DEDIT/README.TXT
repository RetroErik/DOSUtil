DEDIT 1.0 - DESCRIPT.ION Editor

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
https://www.youtube.com/@RetroErik

A full-screen DOS editor for 4DOS-compatible DESCRIPT.ION descriptions.
DEDIT is a companion to the DES directory utility.

REQUIREMENTS AND INSTALLATION

DOS 2.0 or later, Intel 8086/8088 or later, 80-column text mode.
Extract the ZIP and copy DEDIT.COM to your DOS machine, optionally to a
directory on PATH. No 4DOS, ANSI driver, mouse, or assembler is required.
This program runs under DOS, not directly in modern Windows.

USAGE

DEDIT                 Edit descriptions in the current directory
DEDIT C:\GAMES        Edit descriptions in another directory
DEDIT /H              Show command-line help

KEYBOARD

Up/Down, PgUp/PgDn     Move through the directory
Home/End              Move to the first or last entry
Enter or F2           Edit a description
F4 or Ctrl+C          Copy a description
F5 or Ctrl+V          Paste a description
Delete                Clear a description
Ctrl+S or F10         Save
F1                    Show help
Esc                   Quit (prompts for unsaved changes)

In an edit field, Enter accepts the edit and Esc cancels it.

SAVING AND LIMITS

Back up important descriptions before editing. Saving writes a temporary
DESCRIPT.$$$ file, moves the previous DESCRIPT.ION to DESCRIPT.BAK, and
renames the temporary file to DESCRIPT.ION. The previous backup is replaced
on the next save. Description and backup files are marked hidden.
Missing files are marked MISSING; their descriptions are retained on save.
Limits: 400 entries including stale entries, 127-character paths,
240 characters per new description, and a shared 24 KiB description pool.
The path argument selects a directory, not a wildcard.

PACKAGE

DEDIT.COM     Ready-to-run DOS program
README.TXT    This guide (DOS code page 437)
LICENSE.TXT   CC BY-NC 4.0 license information (DOS code page 437)

SOURCE, DOCUMENTATION, AND REPORTING PROBLEMS

https://github.com/RetroErik/DOSUtil/tree/dedit-v1.0/DEDIT
https://github.com/RetroErik/DOSUtil/issues

Report the DOS version, machine or emulator, command, and observed output.
To rebuild with NASM: nasm -f bin dedit.asm -o DEDIT.COM
