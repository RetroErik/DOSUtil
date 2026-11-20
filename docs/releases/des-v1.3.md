Ready-to-run **DES 1.3** for DOS and Intel 8086/8088-compatible machines.

Download **DES-1.3-DOS.zip**, extract it, and run `DES.COM` under DOS.
No assembler, 4DOS, or ANSI driver is required. GitHub's **Source code**
archives are separate from the ready-to-run package.

- Directory listings with 4DOS-compatible `DESCRIPT.ION` descriptions and `COLORDIR` colors.
- Alphabetical sorting, `/P` pagination, and plain redirected output.
- Drive and directory arguments, `/A` for hidden/system entries, and `/I` for drive information.
- Maximum 400 matching entries; larger results produce a warning. Free space is not calculated.

The ZIP contains `DES.COM`, `README.TXT`, and `LICENSE.TXT`.
Text files use DOS code page 437 and DOS line endings.
The matching `.sha256` asset verifies the ZIP download.

This is the first GitHub binary release of the existing 1.3 program;
it does not introduce a new program version.

Validation: rebuilt with NASM and matched the checked-in binary byte for byte.
Tested the extracted ZIP in DOSBox 0.74-3: `/H`, `/?`, directory listing,
redirected output including `/A` and `/P`, and `/I` drive information.
Checked package contents, code page 437 attribution, and DOS line endings.
These release checks did not include a new real-hardware test.

Licensed under CC BY-NC 4.0.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
([YouTube](https://www.youtube.com/@RetroErik)).
