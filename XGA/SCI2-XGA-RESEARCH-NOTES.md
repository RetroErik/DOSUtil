# SCI2 and IBM XGA Research Notes

**Author:** Retro Erik  
**Date:** May 2026  
**Status:** Exploratory and unverified; no SCI2 implementation is active

---

## 1. Purpose

This note records what is currently known about **SCI2** as an XGA target, based on:

- previously established SCI version corrections
- the ScummVM SCI engine architecture
- the absence of evidence for a classic SCI1-style external graphics driver

The goal is not to claim the SCI2 graphics path is understood. The goal is to mark the
boundary between what is known, what is likely, and what still requires reverse engineering.

---

## 2. What Is Known with High Confidence

### SCI2 is the first Sierra DOS engine version with genuine 640x480x256 artwork

Representative DOS SCI2 games:

- Gabriel Knight: Sins of the Fathers
- Police Quest 4: Open Season
- Quest for Glory IV: Shadows of Darkness

This makes SCI2 the first Sierra DOS target where XGA acceleration is conceptually meaningful:

- the artwork is actually high resolution
- the display mode is in XGA's native operating range
- frame presentation and blit work are heavier than SCI1/SCI1.1

### SCI2 is a 32-bit engine family, not the old 16-bit SCI1/SCI1.1 model

The existing evidence strongly indicates that SCI2 belongs to Sierra's later **SCI32** family.
In ScummVM, SCI2 and later versions are handled by a separate 32-bit graphics stack rather than
the older SCI0/SCI1/SCI1.1 render-driver model.

### The old interchangeable `.DRV` graphics model appears to stop before SCI2

ScummVM's SCI graphics driver table and render-mode detection cover the classic driver-file era:

- `EGA320.DRV`
- `CGA320C.DRV`
- `VGA320.DRV`
- `EGA640.DRV`
- `SCIWV.EXE` for certain SCI1.1 Windows graphics cases

Those selections are version-limited to pre-SCI2 engines. There is no matching evidence there for
a separate SCI2 DOS graphics driver file analogous to the older `.DRV` modules.

---

## 3. What This Probably Means

The most likely conclusion is:

**SCI2 graphics are implemented inside the 32-bit interpreter/executable, not as a drop-in DOS graphics `.DRV` module.**

That does not prove Sierra never used helper binaries internally, but it does mean the working
assumption should be:

- **SCI1/SCI1.1 project** = reverse engineer a driver file interface
- **SCI2 project** = reverse engineer or patch the interpreter's built-in graphics system

So an "SCI2 XGA driver" is probably not a classic driver-writing project. It is more likely one of:

1. a patched SCI2 interpreter executable
2. a loader/patch layer that hooks graphics functions at runtime
3. a replacement low-level graphics module inside the SCI2 engine binary

---

## 4. Evidence from ScummVM's SCI Architecture

ScummVM is not the original Sierra code, but it is useful as an architectural map.

For SCI2 and later, ScummVM switches to components such as:

- `GfxFrameout`
- `GfxPaint32`
- `GfxCursor32`
- `GfxPalette32`
- `Video32`

That is a very different shape from the older render-driver path used for SCI0 through SCI1.1.

The implication is important:

- the old "load graphics driver file, call dispatch table" assumption should not be carried over
- SCI2 work will likely center on frame buffer management, screen-item composition, cursor blending,
  palette handling, and final frame output inside the interpreter itself

---

## 5. Has Anybody Made an SCI2 Driver?

At the time of this note, no public evidence has been found for:

- a community-made replacement SCI2 DOS graphics driver
- a documented Sierra SCI2 external graphics-driver API comparable to SCI1/SCI1.1 `.DRV`
- an XGA-targeted SCI2 renderer project

This does **not** prove nobody ever experimented privately. It only means there is currently no
known public reference implementation to build from.

So the honest answer is:

**Sierra clearly had an SCI2 graphics implementation, but there is no evidence yet of a public, replaceable SCI2 graphics driver project in the same sense as classic SCI `.DRV` work.**

---

## 6. What Would Need to Be Reverse-Engineered

If SCI2 is pursued as an XGA target, the likely reverse-engineering targets are:

### A. Interpreter executable structure

- locate the 32-bit DOS extender executable and any companion binaries
- determine whether graphics code is built in or dispatched through an internal module layer
- identify startup mode detection and video initialization

### B. Frame output path

- where the final 640x480 image buffer lives
- how dirty rectangles or planes are tracked
- where the composed frame is pushed to hardware
- whether output is direct-to-VRAM or copied from a system-memory backbuffer

### C. Cursor path

- where cursor save/restore or blending occurs
- whether cursor rendering is software-only
- whether the XGA hardware cursor could replace or partially bypass that logic

### D. Blit and fill hot paths

- picture compositing
- cel/view drawing
- rectangle clears
- transitions and screen effects

### E. Palette and video playback interaction

- DAC updates
- movie playback overlays
- how palette morphs or fades interact with the frame-out path

---

## 7. Best Candidate Hook Points for XGA

If the goal is "make SCI2 use XGA well," the likely hook points are these:

### Best first hook: final frame-out / copy to hardware

This is the safest first target.

Why:

- it is centralized
- it avoids rewriting large parts of the engine immediately
- it may allow XGA-native presentation of an already-composed 640x480 frame

Possible result:

- initial proof of XGA mode set
- initial proof of 640x480 output on real hardware
- modest speed benefit if the original path is CPU-copy bound

### Second hook: cursor

The XGA hardware cursor is attractive because it is isolated and easy to demonstrate.

Why:

- small scope
- visually obvious
- removes software cursor redraw overhead

Risk:

- SCI2 may assume specific software cursor compositing behavior that must still be preserved

### Third hook: rectangle copy / fill acceleration

This is where XGA could deliver the biggest real benefit.

Why:

- XGA BitBLT and fill engines are well matched to 2D adventure-engine workloads
- UI redraw, window rectangles, and some compositing operations may map well

Risk:

- requires deeper knowledge of SCI2's internal draw model
- much easier to break correctness than a simple frame-out hook

---

## 8. Likely Development Order

If this project ever becomes active, the practical order is probably:

1. Identify the SCI2 DOS executable(s) and DOS extender used by one target game.
2. Confirm how the game sets 640x480x256 mode and where the final frame is sent.
3. Build a no-acceleration proof-of-understanding patch:
   log or intercept frame-out without changing behavior.
4. Add XGA mode initialization and a minimal XGA-backed final frame-out path.
5. Add hardware cursor support.
6. Only then investigate deeper BitBLT/fill acceleration.

This minimizes risk and gives useful milestones.

---

## 9. Bottom Line

SCI2 is still the only Sierra/XGA direction that makes technical sense.

Why:

- real 640x480x256 artwork exists
- XGA acceleration is active in the relevant mode
- the graphics workload is substantial enough to justify accelerator use

But the project is not "write a Sierra `.DRV` file."

It is most likely:

- a 32-bit interpreter reverse-engineering project
- followed by an executable patching or hook-layer project
- with XGA integration at frame-out, cursor, and later blit/fill stages

So this is a valid direction, but a much harder one than the original SCI1/SCI1.1 idea.