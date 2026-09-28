# Feasibility Study: Sierra SCI1 / SCI1.1 Graphics Driver for IBM XGA on PS/2 Model 55SX

**Author:** Retro Erik  
**Date:** May 2026  
**Status:** Archived reference; the SCI1/SCI1.1 target premise was invalidated  

---

## 1. Executive Summary

This study evaluates the technical feasibility of writing a Sierra SCI1 and SCI1.1
graphics driver that uses the IBM XGA Display Adapter/A for hardware-accelerated
rendering on an IBM PS/2 Model 55SX.

**Verdict: Premise invalidated — retained as reference only.**

> **Correction (added after review):**
> This study was written under false assumptions identified during review:
> 1. **SCI1/1.1 does not need acceleration on a 386SX-16.** These games were designed
>    for that hardware and run fine in VGA Mode 13h (320×200×256). There is no
>    performance problem to solve.
> 2. **The XGA coprocessor is inactive in VGA-compatible modes.** BitBLT, pattern fill,
>    and the hardware cursor only operate in XGA's own graphics modes (640×480×256 and
>    above). In Mode 13h the XGA behaves as a plain VGA chip — zero acceleration.
> 3. **SCI1.1 artwork is 320×200×256 on DOS, not 640×480×256.** The 640×480×256
>    resolution belongs to SCI2 (1993), which uses a 32-bit DOS extender engine.
>    Gabriel Knight, Police Quest 4, and Quest for Glory IV are SCI2 — not SCI1.1.
>
> **Consequence:** There is no valid premise for an XGA driver targeting SCI1 or SCI1.1.
> The correct target is **SCI2**, where the artwork is genuinely 640×480×256, the XGA
> coprocessor is active, and performance is a real concern. That is a harder, separate
> project requiring research into the SCI2 32-bit driver interface.
>
> This study is retained for its XGA hardware reference material, SCI driver format
> analysis, and lessons from PC1.DRV. Those sections remain accurate.

The primary barrier to any SCI driver project is the driver API itself,
which Sierra never documented publicly and must be recovered through reverse engineering
of existing drivers and the ScummVM/FreeSCI source base.

---

## 2. Target Platform

### IBM PS/2 Model 55SX
| Property | Value |
|----------|-------|
| CPU | Intel 386SX @ 16 MHz |
| Bus | MCA (Micro Channel Architecture) |
| Built-in video | VGA (slow, ~3–4 MB/s VRAM bandwidth) |
| RAM | 2–16 MB |
| DOS | PC-DOS 3.3 / 5.0 / 6.1 |

### IBM XGA Display Adapter/A (MCA)
| Property | Value |
|----------|-------|
| Type | 2D hardware accelerator |
| Bus interface | MCA, 16-bit |
| VRAM | 512 KB (standard) / 1 MB (extended) |
| VRAM bandwidth | 12–16 MB/s |
| Modes | 640×480×256, 800×600×256, 1024×768×256 |
| Accelerators | BitBLT, Pattern Fill, Line Draw, Hardware Cursor |
| Register interface | MCA I/O ports + memory-mapped aperture |
| Documentation | IBM XGA Hardware Reference (complete) |

The XGA is MCA-native and designed for this exact machine. It replaces the built-in
VGA for accelerated graphics and provides 3–4× the VRAM bandwidth of the VGA.

---

## 3. Sierra SCI Engine Versions

### 3.1 SCI1 (1990–1992)

Representative games: King's Quest V, Space Quest IV, Police Quest 3, Leisure Suit
Larry 5, Conquests of the Longbow, EcoQuest.

| Property | Value |
|----------|-------|
| Artwork resolution | 320×200 |
| Color depth | 256 colors (8-bit) |
| Display modes | 320×200×256 (VGA), 640×480×16 (EGA/VGA planar) |
| 640×480×256 support | **No** |
| View resource format | SCI1 view (different from SCI0) |
| Sound | SCI1 MIDI, Adlib, Roland |
| Driver format | `.DRV` with SCI1 dispatch table |
| Accelerated drivers shipped | **None** |

**What XGA adds to SCI1:**
> **Correction:** Nothing. SCI1 runs in VGA Mode 13h (320×200×256), a standard VGA
> mode. The XGA coprocessor (BitBLT, pattern fill, hardware cursor) only operates in
> XGA-native modes (640×480×256 and above). In Mode 13h the XGA is a plain VGA chip.
> Furthermore, SCI1 games were designed to run on a 386SX-16 and perform acceptably
> without any acceleration driver. There is no performance problem to solve here.

### 3.2 SCI1.1 (1992–1994)

Representative games: King's Quest VI, Space Quest 5, Gabriel Knight: Sins of the
Fathers, Quest for Glory 3, Leisure Suit Larry 6, Freddy Pharkas, Laura Bow 2.

| Property | Value |
|----------|-------|
| Artwork resolution | **320×200×256** (same as SCI1 — corrected) |
| Color depth | 256 colors (8-bit) |
| Display modes | 320×200×256 (VGA Mode 13h) |
| 640×480×256 support | **No** — 640×480×256 belongs to SCI2, not SCI1.1 |
| View resource format | SCI1.1 view |
| Driver format | `.DRV` with SCI1.1 dispatch table |
| Accelerated drivers shipped | **None** |

> **Correction:** This "historically significant" claim was wrong. SCI1.1 artwork is
> 320×200×256 on DOS — not 640×480×256. The 640×480×256 resolution belongs to SCI2
> (Gabriel Knight, Police Quest 4, Quest for Glory IV). SCI1.1 runs fine on a 386SX-16
> in Mode 13h. There is no "native resolution" to unlock for SCI1.1.

---

## 4. SCI1 / SCI1.1 Driver Interface

### 4.1 Driver File Format

SCI graphics drivers are 16-bit real-mode binary files (`.DRV`) loaded at runtime
by the SCI interpreter. The format is identical between SCI0, SCI1, and SCI1.1 in
structure, but the dispatch table entries and calling conventions differ.

**Common header structure:**
```
Offset 0x00   3-byte near JMP to dispatch function
Offset 0x03   6-byte signature: 00 21 43 65 87 00
Offset 0x09   Pascal-string: driver name
Offset 0x??   Pascal-string: driver description
Offset 0x??   Dispatch table: array of 16-bit offsets
```

This is identical to what was implemented in `PC1.DRV` (the SCI0 driver for the
Olivetti PC1). The entry convention and signature are shared across SCI versions.

### 4.2 Required Dispatch Functions — SCI1

| Index | Function | Description |
|-------|----------|-------------|
| 0 | `get_color_depth` | Return 8 (256-color) |
| 1 | `init_driver` | Detect hardware, set mode |
| 2 | `restore_mode` | Return to text mode |
| 3 | `update_rect` | Blit framebuffer region to display |
| 4 | `show_cursor` | Show mouse cursor |
| 5 | `hide_cursor` | Hide mouse cursor |
| 6 | `move_cursor` | Move cursor to (x, y) |
| 7 | `load_cursor` | Upload cursor shape |
| 8 | `shake_screen` | Screen shake effect |
| 9 | `set_palette` | Upload 256-color DAC palette |
| 10 | `save_screen` | Save screen region to buffer |
| 11 | `restore_screen` | Restore from buffer |

> **Note:** The exact index assignments and parameter conventions must be verified
> against a disassembly of a known SCI1 driver (e.g., `VGA.DRV` from KQ5 or SQ4).
> ScummVM source `engines/sci/graphics/drivers/` provides the best reference.

### 4.3 Required Dispatch Functions — SCI1.1 Additions

> **Correction:** The functions below were speculated based on the false premise that
> SCI1.1 supported native 640×480×256 artwork. SCI1.1 runs at 320×200×256. The real
> SCI1.1 additions over SCI1 are palette management (`set_palette` with animation
> support) and `save_screen`/`restore_screen`. The 640×480-specific entries below
> are unverified speculation and should not be relied upon.

| Index | Function | Description |
|-------|----------|-------------|
| — | `set_resolution` | ⚠️ Speculative — based on false 640×480 premise |
| — | `scale_cursor` | ⚠️ Speculative — based on false 640×480 premise |
| — | `draw_cel` | ⚠️ Speculative — based on false 640×480 premise |
| — | `blit_pic` | ⚠️ Speculative — based on false 640×480 premise |

> **Note:** SCI1.1 function indices require reverse engineering. ScummVM
> `engines/sci/graphics/drivers/` is the primary reference.

### 4.4 Known Differences from SCI0 Driver API

Our working SCI0 driver (`PC1.DRV`) uses this dispatch table:

```
0: get_color_depth
1: init_video_mode
2: restore_mode
3: update_rect
4: show_cursor
5: hide_cursor
6: move_cursor
7: load_cursor
8: shake_screen
9: scroll_rect
```

SCI1 adds `set_palette` (DAC control moves from interpreter to driver) and
`save/restore_screen`. SCI0's `scroll_rect` may be removed or repurposed. The
`get_color_depth` return value changes from 4 (16-color) to 8 (256-color).

---

## 5. XGA Hardware Mapping to SCI Functions

### 5.1 Function-to-Hardware Map

| SCI Function | XGA Mechanism | Notes |
|-------------|---------------|-------|
| `init_driver` | XGA mode-set via BIOS INT 10h AX=5F00h | Sets 640×480×256 |
| `update_rect` | BitBLT SRC_COPY from system mem to VRAM | Core acceleration |
| `set_palette` | DAC write via BIOS or direct I/O (0x2EC/0x2ED) | Standard VGA DAC |
| `show_cursor` | XGA hardware cursor enable (CR24/CR25) | Zero CPU cost |
| `hide_cursor` | XGA hardware cursor disable | Zero CPU cost |
| `move_cursor` | XGA cursor position registers | One MCA write |
| `load_cursor` | XGA cursor shape RAM (64×64, 2bpp) | 512-byte upload |
| `shake_screen` | XGA display start registers | Pure register write |
| `save_screen` | BitBLT VRAM-to-VRAM copy to off-screen area | Requires 1 MB VRAM |
| `restore_screen` | BitBLT VRAM-to-VRAM copy back | Same |
| `fill_rect` | XGA Pattern Fill Engine | Background clears |

### 5.2 XGA BitBLT Operation Overview

The XGA command processor accepts commands via a FIFO queue at a fixed MCA I/O base
address (varies by instance; read from POS registers). A BitBLT SRC_COPY command:

```
; XGA BitBLT registers (base = XGA_BASE from POS)
; Pixel Operations Register:   set SRC_COPY ROP (0xCC)
; Source map base:              system RAM address (for CPU-to-VRAM blit)
; Destination map base:         VRAM physical base
; Source map width:             framebuffer stride
; Destination map width:        VRAM stride (640 for 640×480 mode)
; BitBLT X/Y/Width/Height:     rectangle coordinates
; Write Mask:                   0xFF (all planes)
; Foreground Mix:               SRC_COPY
; Execute BitBLT command:       write to Pixel Operations register
```

The exact register offsets are documented in the IBM XGA Hardware Reference Guide,
Chapter 4 (Coprocessor Register Set). All values are fully known.

### 5.3 Mode Initialization: 640×480×256

XGA mode-set is via BIOS:

```nasm
; Set XGA 640×480×256 mode
mov ax, 0x5F00          ; XGA BIOS function
mov bx, 0x0105          ; mode 5 = 640×480×256
int 0x10
```

Alternatively, direct register programming is documented in the BIOS Technical
Reference. The BIOS path is preferred for compatibility with XGA and XGA-2.

### 5.4 Hardware Cursor

XGA provides a 64×64 hardware cursor with a 2bpp format (transparent, inverse,
color-0, color-1). The SCI cursor shapes are 16×16, so they fit comfortably.

The cursor RAM is accessible via the Sprite/Cursor registers at offsets documented
in the XGA Hardware Reference. This approach was proven in `PC1.DRV` where the
V6355D hardware sprite was used for the SCI0 cursor — same concept, different chip.

---

## 6. Comparison with Existing SCI0 Driver (PC1.DRV)

Our production `PC1.DRV` driver demonstrates that a custom SCI driver can be written
in NASM 16-bit assembly and deployed successfully. Key lessons that transfer:

| Lesson from PC1.DRV | Applies to XGA driver |
|--------------------|----------------------|
| 3-byte forced JMP entry | Identical requirement |
| Pascal-string name/description | Identical format |
| Dispatch table structure | Same concept, different indices |
| Palette isolation from interpreter | Confirmed for SCI1 |
| Hardware cursor via chip registers | XGA cursor = same principle |
| Rectangle-aware update (not full-screen) | Carried over |
| `shake_screen` = display offset register | XGA has display start registers |

The SCI0 driver was ~900 lines of NASM. An XGA SCI1 driver will be larger due to:
- XGA command FIFO setup and FIFO-full polling
- MCA POS register scanning to find XGA base address
- Mode detection (SCI1 vs SCI1.1, 320 vs 640)
- 256-color palette management (not needed in PC1.DRV which used 16 colors)

Estimated size: **1200–1800 lines of NASM**.

---

## 7. Technical Risks and Challenges

### 7.1 CRITICAL — Driver API Must Be Reverse-Engineered

**Risk level: High**

The SCI1/SCI1.1 driver dispatch table indices and parameter passing conventions are
not publicly documented. They must be recovered from:

1. **Disassembly of `VGA.DRV`** from a known SCI1 game (KQ5, SQ4)
2. **ScummVM source** — `engines/sci/graphics/` has partial reconstruction
3. **FreeSCI source** — older but has driver interface notes
4. **Disassembly of the SCI1 interpreter** (`SCIV.EXE` or `SIERRA.EXE`)

This is the largest unknown. The SCI0 driver API was well-documented by the ScummVM
team; SCI1/SCI1.1 driver interfaces are less thoroughly covered. Plan for 2–4 weeks
of reverse-engineering work before writing a single line of driver code.

### 7.2 CRITICAL — No Emulator Support for XGA

**Risk level: High (development friction, not a blocker)**

No current emulator (DOSBox, DOSBox-X, PCem, 86Box, QEMU) emulates the IBM XGA
adapter. All development and testing must be performed on the real PS/2 Model 55SX
with the physical XGA card installed.

This means:
- No fast iteration cycle (build → test requires physical machine)
- Debugging is limited to DOS-era tools (`DEBUG.COM`, timing via border color tricks)
- A separate fallback to built-in VGA is mandatory for development

Mitigation: Write the driver so it falls back to VGA if XGA is not detected. Develop
and debug the SCI integration on VGA first, then enable XGA acceleration paths.

### 7.3 MEDIUM — XGA Command FIFO Polling

**Risk level: Medium**

The XGA command processor uses a FIFO queue. The driver must poll for FIFO space
before submitting each command. On a 386SX-16 the polling loop will have measurable
cost. Submitting a batch of commands (e.g., tiling a large blit as sub-rectangles)
requires careful FIFO management.

Reference: IBM XGA Hardware Reference, Chapter 4, Section 4.3 (Coprocessor Status).

### 7.4 MEDIUM — MCA Base Address Discovery

**Risk level: Medium**

XGA base I/O address is not fixed. It is read from the MCA POS (Programmable Option
Select) registers. The driver must scan MCA slots for an XGA adapter at startup:

```nasm
; Scan MCA slots 0–7 for XGA
; Enable POS for slot N: OUT 0x96, 0x08|N
; Read POS0 (ID low):  IN AL, 0x100
; Read POS1 (ID high): IN AL, 0x101
; XGA adapter ID: 0x8FD8 (XGA) or 0x8FDA (XGA-2)
; Read POS2 for I/O base address bits
```

This is well-documented in the IBM XGA Hardware Reference, Chapter 2. Not complex,
but it must be correct for the driver to find the card.

### 7.5 LOW — SCI1 vs SCI1.1 Cel Format Differences

**Risk level: Low (for initial version)**

SCI1 uses a different cel/view resource format from SCI1.1. Since the driver itself
does not decode resource formats (that is the interpreter's job), the driver only
sees raw pixel data passed via function parameters. The difference in cel formats is
handled by the interpreter before the driver is called.

This risk affects only if the driver is expected to perform format-specific
transformations — which is unlikely based on SCI0 driver analysis.

### 7.6 LOW — Save/Restore Screen Requires 1 MB VRAM

**Risk level: Low**

`save_screen` / `restore_screen` are most efficiently implemented as VRAM-to-VRAM
BitBLT into an off-screen area. This requires the 1 MB VRAM version of the XGA card.
The 512 KB version cannot hold a full 640×480×256 off-screen buffer.

Fallback: use conventional DOS memory (up to 640 KB) as a system-RAM save buffer,
at the cost of a CPU-driven copy instead of a BitBLT.

---

## 8. Resources and Documentation Available

| Resource | Status | Usefulness |
|----------|--------|-----------|
| IBM XGA Hardware Reference Guide | ✅ Available | Complete register map, BitBLT formats |
| IBM XGA BIOS Technical Reference | ✅ Available | Mode-set, DAC, BIOS calls |
| OS/2 XGA driver source (partial) | ✅ Available | FIFO handling, BitBLT setup patterns |
| Linux XGA driver (xf86-video-ibmxga, historical) | ✅ Available | Register definitions |
| Windows 3.1 XGA driver | ✅ Available | Mode-set sequences, cursor patterns |
| SCI0 driver source (PC1.DRV) | ✅ In-workspace | Proven driver skeleton and conventions |
| ScummVM SCI engine source | ✅ Online | Driver API reconstruction, SCI1/1.1 details |
| `VGA.DRV` from KQ5/SQ4 | 🔲 Needs extraction | Primary reverse-engineering target |
| FreeSCI source | ✅ Archived | Partial SCI1 driver interface notes |
| SCI1 interpreter binary (SCIV.EXE) | 🔲 Needs extraction | Secondary RE target |

---

## 9. Development Plan

### Phase 1 — Reverse Engineering (4–6 weeks)

1. Extract `VGA.DRV` from King's Quest V (or Space Quest IV) installation.
2. Disassemble with IDA Free or Ghidra; map the dispatch table and each function.
3. Document parameter passing convention (stack vs registers vs DS-relative pointers).
4. Extract `VGA.DRV` from a SCI1.1 game (KQ6 or SQ5); diff the dispatch tables.
5. Cross-reference with ScummVM `engines/sci/graphics/drivers/` source.
6. Produce a written SCI1 and SCI1.1 driver API specification.

**Deliverable:** `SCI1-DRIVER-API.md` — a complete, verified function-by-function
description of the dispatch table for SCI1 and SCI1.1.

### Phase 2 — VGA Baseline Driver (2–3 weeks)

1. Write a minimal SCI1 driver targeting VGA 320×200×256 (Mode 13h).
2. Implement all required dispatch functions in pure software (no XGA).
3. Test with KQ5 or SQ4 on the PS/2 Model 55SX.
4. Confirm the driver API is correctly implemented before adding XGA.

**Deliverable:** `XGA-SCI1.DRV` (VGA-only mode), verified working with SCI1 games.

### Phase 3 — SCI1.1 Extension (2–3 weeks)

> **Correction:** The original goal — enabling 640×480×256 for SCI1.1 — is invalid.
> SCI1.1 runs at 320×200×256. Gabriel Knight is SCI2, not SCI1.1. A real Phase 3
> verifies that SCI1.1-specific dispatch differences from SCI1 (palette animation,
> save/restore_screen) are handled correctly. No resolution change is needed.

1. Verify SCI1.1-specific dispatch entries (palette animation, save/restore_screen).
2. Test with KQ6, LSL6, or Space Quest 5 (true SCI1.1 games, all at 320×200×256).
3. Confirm the driver works correctly across both SCI1 and SCI1.1.

**Deliverable:** Combined SCI1/SCI1.1 driver at 320×200×256, verified working.

### Phase 4 — XGA Acceleration Layer (3–4 weeks)

1. Implement MCA POS scanning and XGA detection.
2. Implement XGA 640×480×256 mode-set via BIOS.
3. Replace `update_rect` with an XGA BitBLT path.
4. Replace `fill_rect` / `save_screen` / `restore_screen` with XGA commands.
5. Replace software cursor with XGA hardware cursor.
6. Benchmark XGA vs VGA paths on the 386SX-16.

**Deliverable:** Full XGA-accelerated driver, `XGA-SCI1.DRV` production version.

### Phase 5 — Abandoned: Based on False Premise

> **Correction:** This phase was based on the false claim that SCI1.1 had native
> 640×480×256 artwork. It does not — that belongs to SCI2. KQ6 has no 640×480 DOS
> artwork.
>
> The equivalent real project is an **SCI2 driver** — a harder, separate undertaking
> requiring research into SCI2's 32-bit protected-mode DOS extender interface. SCI2
> (Gabriel Knight, Police Quest 4, Quest for Glory IV) has genuine native 640×480×256
> artwork, stresses hardware, and would actually benefit from XGA acceleration.
> That project is architecturally different from the 16-bit `.DRV` work described here.

---

## 10. Feasibility Verdict

| Factor | Assessment |
|--------|-----------|
| XGA hardware suitability | Not applicable to SCI1/SCI1.1; hardware notes may inform XGA-native projects |
| Documentation completeness | Good — XGA fully documented; SCI1 API needs RE |
| Existing reference code | Good — PC1.DRV provides proven driver skeleton |
| Development environment | Limited — no emulator; must use real hardware |
| Estimated total effort | 13–19 weeks, part-time retro hobbyist pace |
| Historical significance | **None for SCI1/1.1** — premise invalidated; correct target is SCI2 |
| Overall feasibility | **Premise invalidated** — see correction notes in Executive Summary |

### Recommendation

> **Correction:** The recommendation to proceed with this project as written is
> withdrawn. The XGA coprocessor cannot accelerate Mode 13h (320×200), SCI1/1.1
> does not need acceleration on a 386SX-16, and SCI1.1 has no native 640×480 artwork.

The XGA hardware documentation, register reference, and BitBLT command patterns
documented in this study remain accurate. If the goal is Sierra games on PS/2 with
real XGA acceleration, the correct target is **SCI2** — which has genuine native
640×480×256 artwork, a 32-bit DOS extender that stresses hardware, and games where
XGA BitBLT would deliver measurable benefit. SCI2 requires separate reverse-engineering
of its 32-bit driver interface (different from the 16-bit `.DRV` format described here).

This document is retained for its XGA hardware reference and driver format analysis.

---

## Appendix A: Key XGA Register Quick Reference

| Register | Address | Description |
|----------|---------|-------------|
| POS0/POS1 | 0x100/0x101 (with POS enabled) | Adapter ID (XGA = 0x8FD8) |
| POS2 | 0x102 | I/O base address select |
| VRAM aperture | 0xA0000 or configured via POS | Linear framebuffer |
| Pixel Operations | XGA_BASE + 0x48 | ROP and command trigger |
| BitBLT Source | XGA_BASE + 0x60 | Source address |
| BitBLT Dest | XGA_BASE + 0x68 | Destination address |
| BitBLT Width | XGA_BASE + 0x70 | Blit width in pixels |
| BitBLT Height | XGA_BASE + 0x74 | Blit height in pixels |
| Hardware Cursor X | XGA_BASE + 0x24 | Cursor X position |
| Hardware Cursor Y | XGA_BASE + 0x26 | Cursor Y position |
| Coprocessor Status | XGA_BASE + 0x4C | Bit 0: FIFO full |

---

## Appendix B: SCI1 Games — Driver Test Candidates

| Game | Engine | Resolution | Priority |
|------|--------|-----------|----------|
| King's Quest V | SCI1 | 320×200 | Primary test (well-known) |
| Space Quest IV | SCI1 | 320×200 | Secondary test |
| Police Quest 3 | SCI1 | 320×200 | Secondary test |
| King's Quest VI | SCI1.1 | **320×200** ✓ | Primary SCI1.1 test — corrected resolution |
| Gabriel Knight 1 | **SCI2** | **640×480** | ⚠️ SCI2, not SCI1.1 — different architecture |
| Space Quest 5 | SCI1.1 | **320×200** ✓ | Secondary SCI1.1 test — corrected resolution |

---

## Appendix C: Relationship to Existing Work

This project builds on the following completed work in this workspace:

- **`Sierra-SCI0-Driver-for-Olivetti-PC1/PC1.DRV`** — Production SCI0 driver for the
  Olivetti PC1, hardware-verified April 2026. Provides the driver skeleton, entry
  convention, dispatch table pattern, and hardware cursor approach that all carry
  forward to this project.

- **`Sierra-SCI0-Driver-Private/`** — Private research notes and development
  iterations for the SCI0 driver.

- **XGA/XGA-ACCELERATION-TARGETS-AND-DEMO-IDEAS.md** — General XGA target analysis,
  demo ideas, and the corrected conclusion that SCI1/SCI1.1 are not worthwhile XGA
  targets. The present study was derived from the earlier Sierra-specific research and
  is now kept mainly as a corrected reference record.

- **`XGA/XGA vs 8514A`** — Rationale for targeting XGA rather than 8514/A.

- **`XGA/XGA vs Amiga`** — Performance comparison establishing XGA as workstation-class
  for this type of use case.
