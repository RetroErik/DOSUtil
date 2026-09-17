# PicoMEM DOS Startup Configuration

A DOS startup configuration for systems using a PicoMEM device. It provides selectable memory profiles at boot time, initializes PicoMEM services, optionally loads a CD-ROM drive, and prepares a 4DOS-based command-line environment.

By **Dag Erik Hagesaeter / Retro Erik** - [YouTube: Retro Hardware and Software](https://www.youtube.com/@RetroErik)

The [FreddyVRetro/ISA-PicoMEM PicoMEM documentation and firmware project](https://github.com/FreddyVRetro/ISA-PicoMEM) is a useful companion when using and configuring this startup setup.

![Platform](https://img.shields.io/badge/Platform-MS--DOS-blue)
![Hardware](https://img.shields.io/badge/Hardware-PicoMEM-green)
![Shell](https://img.shields.io/badge/Shell-4DOS-orange)

## Overview

The configuration is split into two standard DOS startup files:

- `CONFIG.SYS` defines the boot menu, memory managers, device drivers, and DOS settings.
- `AUTOEXEC.BAT` initializes utilities, environment variables, keyboard and hardware settings, CD-ROM support, and the command prompt.

The files assume that the required DOS utilities and PicoMEM software are installed on drive `C:` in the directories referenced by the configuration.

## Boot Profiles

When the computer starts, `CONFIG.SYS` displays a menu with the following profiles:

| Profile | Purpose |
|---------|---------|
| `EPCONV` | EuroPC / 286 using conventional memory only |
| `EPEMS` | EuroPC / 286 using PicoMEM expanded memory and CD-ROM support |
| `386CONV` | 386 or newer system using conventional memory only |
| `386EMS` | 386 or newer system using expanded memory through EMM386 and CD-ROM support |
| `386XMS` | 386 or newer system using extended memory through HIMEM and CD-ROM support |
| `386UMB` | 386 or newer system using upper memory, without EMS, and CD-ROM support |

The default profile is `386XMS`, selected after 10 seconds.

## Requirements

- An MS-DOS-compatible system or emulator.
- A PicoMEM device and its DOS utilities, when using PicoMEM-specific features.
- 4DOS installed as `C:\4DOS\4DOS.COM`.
- The utilities and drivers referenced by the startup files, including as applicable:
  - `C:\PicoMEM\PMEMM.EXE`
  - `C:\PicoMEM\CDMKE.SYS`
  - `C:\DOS\HIMEM.SYS`
  - `C:\DOS\EMM386.EXE`
  - `C:\UTIL\ANSI.COM` (ANSI 1.31, PC Magazine / Michael J. Mefford)
  - `C:\UTIL\SHSUCDX` or `C:\UTIL\SHCDX86`
  - `C:\UTIL\PMINIT.EXE`
- `COUNTRY.SYS` installed at `C:\DOS\COUNTRY.SYS`.

Some utilities are only used by particular boot profiles. For example, `HIMEM.SYS` and `EMM386.EXE` are used by the 386 profiles, while `PMEMM.EXE` is used by `EPEMS`.

`ANSI.COM` is the compact ANSI 1.31 driver identified in the program banner as copyright 1988 Ziff Communications Co., from PC Magazine by Michael J. Mefford. It is used here because of its small size and fast operation.

`SHSUCDX` and `SHCDX86` are DOS CD-ROM redirectors from the [SHSUCD suite](https://github.com/adoxa/shsucd). The latest `SHSUCDX` version used by this configuration is **3.07**.

## Installation

1. Back up the existing `CONFIG.SYS` and `AUTOEXEC.BAT` on the target DOS system.
2. Copy `CONFIG.SYS` and `AUTOEXEC.BAT` to the root directory of the boot drive, normally `C:\`.
3. Confirm that the directories and files referenced in both startup files exist on the target system.
4. Reboot the computer.
5. Select the required profile from the startup menu.

These files are intended for a system with the following general layout:

```text
C:\
+- DOS\
+- 4DOS\
+- PicoMEM\
+- UTIL\
+- mTCP\
+- ULTRASND\
```

The exact contents of these directories depend on the hardware and software installed on the system.

## AUTOEXEC.BAT

`AUTOEXEC.BAT` performs the following startup tasks:

- Enables a bright yellow-on-black console and loads `ANSI.COM`.
- Sets the DOS search path for DOS, 4DOS, PicoMEM-related utilities, networking, and Norton utilities.
- Defines `ColorDir` rules for 4DOS-compatible file and directory colors.
- Sets Sound Blaster and UltraSound environment variables.
- Configures keyboard repeat rate and the 4DOS prompt.
- Performs EuroPC-specific setup for the `EPCONV` and `EPEMS` profiles.
- Performs 386-specific video setup for the `386*` profiles.
- Initializes PicoMEM with `PMINIT.EXE`.
- Loads the appropriate CD-ROM redirector for profiles that support CD-ROM access.
- Displays a startup status line with CPU, free conventional memory, drive information, and the Retro Erik name.

The script uses the `CONFIG` environment variable created by DOS boot-menu processing to select the correct profile-specific commands.

## CONFIG.SYS

`CONFIG.SYS` configures the DOS boot menu and common system settings.

The common section enables:

- `BREAK=ON` for interrupting running programs with `Ctrl+Break`.
- `FILES=30` and `BUFFERS=20` for DOS file and disk buffering.
- `LASTDRIVE=G` for drive letters through `G:`.
- `COUNTRY=047,865` for the configured Norwegian country and code page settings.
- 4DOS as the command shell through `C:\4DOS\4DOS.COM /P`.

The memory profiles load the following drivers:

- `EPEMS` loads `PMEMM.EXE` and `CDMKE.SYS`.
- `386EMS` loads `HIMEM.SYS`, `EMM386.EXE RAM`, and `CDMKE.SYS` high.
- `386XMS` loads `HIMEM.SYS` and `CDMKE.SYS`.
- `386UMB` loads `HIMEM.SYS`, `EMM386.EXE NOEMS`, and `CDMKE.SYS` high.

The `EPCONV` and `386CONV` profiles intentionally load no additional memory manager or CD-ROM driver.

## CD-ROM Support

The CD-ROM driver is enabled for `EPEMS`, `386EMS`, `386XMS`, and `386UMB`. The driver uses:

```text
C:\PicoMEM\CDMKE.SYS /P:250 /D:PicoCD1
```

The matching redirector is loaded by `AUTOEXEC.BAT` and assigns the CD-ROM drive as `E:`:

```text
shsuCDX /Q+ /D:PicoCD1 /L:E
```

For `EPEMS`, the configuration uses `SHCDX86` instead. The `EPCONV` and `386CONV` profiles do not load CD-ROM support.

## Customization

Before using these files on another system, review:

- Drive letters and installation paths.
- The selected default profile and menu timeout.
- Country and code page settings.
- Sound card settings in `BLASTER` and `ULTRASND`.
- The `ColorDir` rules and 4DOS installation path.
- CD-ROM driver and redirector availability.
- The `LastDrive` value if more drive letters are needed.

Keep DOS device-driver paths consistent between `CONFIG.SYS` and `AUTOEXEC.BAT`. A driver loaded in `CONFIG.SYS` must exist before DOS starts, while its associated initialization or redirector command may be run later from `AUTOEXEC.BAT`.

## Project Layout

| Path | Purpose |
|------|---------|
| `AUTOEXEC.BAT` | DOS startup commands and environment setup |
| `CONFIG.SYS` | DOS boot menu, memory profiles, drivers, and common settings |
| `README.md` | Documentation for this configuration |

## Testing

Test each profile on the intended hardware or emulator after making changes:

1. Confirm that the boot menu appears and the intended default is selected.
2. Verify that the system reaches the 4DOS prompt without missing-file errors.
3. Check the reported free conventional memory and CPU information.
4. For memory profiles, verify the expected HIMEM, EMM386, or PicoMEM behavior.
5. For CD-ROM profiles, confirm that drive `E:` is available and uses the `PicoCD1` device name.
6. Confirm that `ColorDir`, keyboard repeat, sound variables, and the 4DOS prompt work as expected.
7. Test the conventional-memory profiles separately, because they intentionally omit memory managers and CD-ROM support.

## Credits

- **Configuration author:** Dag Erik Hagesaeter / Retro Erik
- **Documentation assistance:** GitHub Copilot
