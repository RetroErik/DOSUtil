# Publishing DOS releases

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
([Retro Erik on YouTube](https://www.youtube.com/@RetroErik)).

DES and DEDIT have independent versions and tags: `des-v1.3` and `dedit-v1.0`.
Keep archived versions unchanged. Fixes to published programs require a new
version, tag, and package. Do not overwrite published ZIPs.

## Build and inspect

On Windows with PowerShell and NASM, from the repository root:

```text
powershell -NoProfile -File scripts/package-dos.ps1
powershell -NoProfile -File scripts/package-dos.ps1 -Program DES -Nasm C:\Tools\NASM\nasm.exe
```

The script builds from source, requires the result to match the checked-in
binary, and creates ZIPs and SHA-256 checksum files in `artifacts/dos-releases/`.
It refuses to overwrite an existing package. Staging directories remain for
inspection. Each ZIP contains just the COM program, `README.TXT`, and
`LICENSE.TXT`. Packaged text uses code page 437 and CRLF; source text uses UTF-8.

Extract each ZIP into a fresh test directory. Check help and normal operation
in DOSBox or DOS. For DES, check descriptions, redirected output, and `/I`.
For DEDIT, check editing, saving, and preservation of the previous description
file in `DESCRIPT.BAK`. Use disposable files. Record the tested environment in
the release notes; do not imply real-hardware validation from emulator tests.

## Publish

Commit the source, package documentation, and download links. Push the commit
before creating releases. Pin each tag to the exact commit used to build the
package. Create a draft, attach its ZIP and checksum, and inspect the notes
before publishing. Use the program-specific notes in `docs/releases/`.

Keep the Windows editor release as the repository's latest release during the
initial DOS publication. Program-specific links in the README identify each
download independently of GitHub's repository-wide latest-release selection.

After publication, download both ZIPs again, verify their SHA-256 checksums,
and check the README download links. For future versions, update the version
in source, package script, documentation, release notes, and download links.
