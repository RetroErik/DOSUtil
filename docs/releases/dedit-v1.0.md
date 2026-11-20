Ready-to-run **DEDIT 1.0**, the full-screen `DESCRIPT.ION` editor and DES companion.

Download **DEDIT-1.0-DOS.zip**, extract it, and run `DEDIT.COM` under DOS.
Requires DOS 2.0 or later, an Intel 8086/8088-compatible CPU, and 80-column text
mode. No assembler, 4DOS, ANSI driver, or mouse is required. GitHub's
**Source code** archives are separate from the ready-to-run package.

- Edit descriptions for files and directories; copy and paste descriptions with the keyboard.
- Stale entries are marked `MISSING` and retained on save.
- `Ctrl+S` or `F10` saves through a temporary file and preserves the previous file as `DESCRIPT.BAK`.
- Limits: 400 entries, 127-character paths, 240-character new descriptions, shared 24 KiB description pool.

Back up important descriptions before editing. Each save replaces the previous
`DESCRIPT.BAK` backup.

The ZIP contains `DEDIT.COM`, `README.TXT`, and `LICENSE.TXT`.
Text files use DOS code page 437 and DOS line endings.
The matching `.sha256` asset verifies the ZIP download.

This is the first GitHub binary release of the existing 1.0 program;
it does not introduce a new program version.

Validation: rebuilt with NASM and matched the checked-in binary byte for byte.
Tested the extracted ZIP in DOSBox 0.74-3: command-line help and an automated
keyboard workflow opening an edit, accepting it, copying and pasting a
description, saving, and quitting. Verified the saved description, retention
of a stale entry, and a backup matching the original description file.
Checked package contents, code page 437 attribution, and DOS line endings.
These release checks did not include a new real-hardware test.

Licensed under CC BY-NC 4.0.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
([YouTube](https://www.youtube.com/@RetroErik)).
