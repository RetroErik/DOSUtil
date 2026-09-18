# QuitKey

A tiny DOS TSR (terminate-and-stay-resident) utility by **Dag Erik Hagesaeter / Retro Erik**.

Many old CGA-era games have no way to quit back to DOS - the only "solution" is to
reboot the machine. QuitKey installs a global hotkey, **Ctrl+Alt+Q** (or **F12** as a
backup), that force-quits whatever program is currently running and returns you
straight to DOS, as if that program had exited normally.

## Usage

```
QUITKEY          install the TSR (once per boot, e.g. from AUTOEXEC.BAT)
QUITKEY /?       show help and exit without installing
```

Once installed, press **Ctrl+Alt+Q** or **F12** at any time to terminate the
currently running program. F12 exists because some games use Alt themselves
(e.g. for an in-game menu), which would otherwise swallow the Ctrl+Alt+Q combo.
Running `QUITKEY` again while already installed does nothing (it just tells
you it's already loaded), so it's safe to put in `AUTOEXEC.BAT` unconditionally.

## How it works

- Hooks **INT 9** (keyboard IRQ) to watch raw scan codes for Ctrl+Alt+Q and set a
  pending-quit flag, then always chains to the original handler so normal typing is
  unaffected.
- Hooks **INT 16h** (BIOS keyboard services), which is how the vast majority of DOS
  games read the keyboard. When the pending-quit flag is set and it's currently safe
  to call DOS (checked via the InDOS/critical-error flags), it issues `INT 21h AH=4Ch`
  to terminate the current program and return to its parent (COMMAND.COM).
- Hooks **INT 2Fh** (multiplex interrupt) only to detect whether it's already
  installed, so it won't load twice.
- Before terminating a program, it cleans up after it: silences the PC
  speaker, resets the system timer (INT 8) back to 18.2 Hz, restores the
  INT 8/1Ch vectors and video mode that were active before QuitKey was
  installed, and re-installs its own INT 9/16h hooks. This is necessary
  because `INT 21h AH=4Ch` does not restore vectors a program changed (only
  INT 22h/23h/24h are restored automatically) - without this, games that hook
  the timer for music or install their own keyboard handler would leave the
  machine in 40-column mode, with stuck music, or hung the next time an
  interrupt fired into their now-freed memory.

## Limitations

- Only catches keyboard input read through INT 16h. A program that reads the
  keyboard buffer or port 60h directly, bypassing INT 16h entirely, won't be
  interrupted (this covers the great majority of DOS games, but not all).
- No uninstall command; it stays resident until reboot. This matches how it's
  normally used: loaded once from `AUTOEXEC.BAT`.
- Plain real-mode DOS TSR; not aware of DOS extenders or Windows.

## Will it work with my game?

There's no way to know for certain without trying it, but as a rule of thumb:

- **Tends to work**: slower-paced, menu- or parser-driven games, and simply-coded
  arcade clones (these usually read input through the standard BIOS keyboard
  service). Verified working: PX3, Zaxxon, Space Quest 3, Pac-Man, Frogger,
  Sopwith, Paratrooper.
- **Tends not to work**: fast real-time action games - platformers, shooters,
  flight/space sims - especially ports of arcade or 8-bit home-computer
  originals, since these often read the keyboard hardware directly for speed
  instead of going through DOS/BIOS. Verified not working: Hard Hat Mack,
  Elite, Ironman, Space Invaders, Tapper, MS Flight Simulator 3 (which also
  crashed instead of returning cleanly to DOS).

## Credit

Written using vibe coding - By Retro Erik

## Build

```
nasm -f bin quitkey.asm -o QUITKEY.COM
```

## Testing

`test/hang.asm` is a tiny fixture program that loops reading a key via INT 16h and
never exits on its own (simulating a game with no quit option), used to verify the
hotkey during development.
