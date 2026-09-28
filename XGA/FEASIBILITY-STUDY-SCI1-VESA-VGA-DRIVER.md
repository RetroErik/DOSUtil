# Feasibility Study: Sierra SCI1 / SCI1.1 Graphics Driver for VESA VGA 640×480×256

**Author:** Retro Erik  
**Date:** May 2026  
**Status:** Archived feasibility study; no implementation is active  
**Related study:** [FEASIBILITY-STUDY-SCI1-XGA-DRIVER.md](FEASIBILITY-STUDY-SCI1-XGA-DRIVER.md)

---

## 1. Executive Summary

This study evaluates the feasibility of writing a Sierra SCI1 and SCI1.1 graphics
driver targeting **VESA VGA 640×480×256** (VESA mode 0x101) for standard DOS PCs.

**Verdict: Low end-user value for SCI1/SCI1.1 — useful only as engineering groundwork.**

> **Resolution correction (added after initial draft):**
> SCI1.1 runs at **320×200×256** on DOS — same resolution as SCI1. The 640×480×256
> native resolution belongs to **SCI2** (1993). A VESA driver for SCI1/SCI1.1 does
> not unlock new artwork or a better visual experience. See below.

> **Visual benefit analysis:**
> 1. **No "fill the screen" benefit** — VGA Mode 13h (320×200) already fills a CRT
>    monitor. The hardware stretches to 4:3. There are no black borders to fix.
> 2. **Aspect ratio gets worse, not better** — SCI1/1.1 artwork was drawn for
>    Mode 13h's non-square pixels (~5:6 PAR). A 2× integer upscale to 640×400
>    gives square pixels, making the image slightly squished vertically versus
>    how the artists intended it. Filling 640×480 requires non-integer vertical
>    scaling which is even harder and still wrong.
> 3. **Monitor compatibility** — Mode 13h sync problems were essentially never
>    a real-world issue.

**The genuine value of this project is engineering, not visual:**
- Learn and document the SCI1/SCI1.1 `.DRV` binary interface (required for any further driver work)
- Prove the driver framework works in DOSBox before touching real hardware
- Build the foundation needed to write a **SCI2 driver** — which *does* have native 640×480×256 artwork and a real visual payoff

A VESA-based driver compared to the XGA approach:
- Works on any PC with a VESA-compatible VGA card (S3, Tseng, Trident, Cirrus, ATI…)
- **Can be fully developed and tested in DOSBox** — no special hardware required
- Is significantly simpler to write: no hardware-specific accelerator to program
- Is the correct approach for a general-purpose, widely compatible driver

The trade-off is performance: VESA bank-switched modes are slow, especially with
INT 10h-based bank switching. On a genuine 386SX-16 the framerate may be marginal.
A 386DX-33 or 486SX-25 is the practical minimum for playable performance.

---

## 2. What Is VESA VGA 640×480×256?

### Standard VGA Limitation

Standard VGA (Mode 13h) provides 320×200×256 using a flat 64KB framebuffer window.
This is what all SCI1 games shipped with. However:

- 640×480×256 requires **307,200 bytes** (300 KB) of VRAM
- VGA's CPU-addressable window is only **64 KB** at a time (A000:0000)
- A 640×480×256 framebuffer does **not fit** in the standard VGA window

### VESA VBE Solution

The **VESA BIOS Extensions (VBE)** standard, published by VESA starting with VBE 1.0
(1989) and updated to VBE 1.2 (1991) and VBE 2.0 (1994), defines:

- A standard INT 10h interface for setting high-resolution modes
- A **bank-switching** mechanism to page through VRAM in 64KB windows
- Mode 0x101 = 640×480×256 (defined in VBE 1.0, present in all implementations)

For a 16-bit real-mode DOS driver, VESA VBE 1.2 is the target. The driver:
1. Sets mode 0x101 via INT 10h AX=4F02h BX=0101h
2. Writes pixels to the A000:0000 window
3. Switches banks via INT 10h AX=4F05h (or faster: direct window function call)

### Linear Framebuffer (VBE 2.0)

VBE 2.0 adds a **linear framebuffer** accessible above 1 MB via a 32-bit physical
address. This requires either:
- A DPMI host (DOS Protected Mode Interface) — available in Windows 3.1 DOS box,
  or via HIMEM.SYS + EMM386.EXE
- A custom DOS extender

For a 16-bit real-mode driver (compatible with DOS without extensions), the
bank-switched VBE 1.2 approach is appropriate. The linear framebuffer can be an
optional fast path when DPMI is available.

---

## 3. VESA Mode 0x101 — Technical Details

| Property | Value |
|----------|-------|
| Mode number | 0x101 |
| Resolution | 640 × 480 |
| Color depth | 8-bit (256 colors, planar DAC) |
| VRAM required | 307,200 bytes |
| Bytes per row | 640 (may vary; read from VESA mode info block) |
| Bank size | 64 KB (typical; confirm from mode info) |
| Bank granularity | 64 KB (some cards: 4 KB granularity) |
| Bank switches per full frame | 5 (307,200 ÷ 65,536 = 4.69, round up to 5) |
| Bank switch method | INT 10h AX=4F05h BX=0 DX=bank_number |
| Fast bank switch | Call window function pointer from VESA mode info block |
| Linear framebuffer | VBE 2.0 only (requires DPMI in real mode) |

### Bank Boundary Layout for 640×480×256

```
Bank 0:  rows   0–101  (65,536 bytes; row 102 starts at byte 65,280 = row 102×640)
         row 102 straddles banks 0/1 — split at column 256
Bank 1:  rows 102–203  (row 102 col 256 through row 203 col 384)
         row 203 straddles banks 1/2
Bank 2:  rows 203–307  ...
Bank 3:  rows 307–409  ...
Bank 4:  rows 409–479  (last 45,440 bytes)
```

**Key implementation note:** Row 102, 204 (approximately), etc. straddle bank
boundaries. The `update_rect` routine must handle rows that cross a bank boundary
by splitting the write into two parts and switching banks mid-row. This is the
hardest part of the VESA driver implementation.

---

## 4. SCI Engine Compatibility

### 4.1 SCI1 (1990–1992) — 320×200 Artwork

SCI1 games run in VGA Mode 13h (320×200×256). On a CRT monitor this already fills
the screen — the monitor stretches the signal to 4:3. There is no visual gap to fix.

For a VESA 640×480×256 driver, a 2× integer upscale to 640×400 (centred in 640×480
with 40-pixel black bars) would give square pixels. However, SCI1 artwork was drawn
for Mode 13h's non-square pixel aspect ratio (~5:6 PAR), so square pixels make the
image appear slightly squished vertically versus the original CRT experience. This
is arguably worse, not better.

**Conclusion:** There is no practical visual benefit over Mode 13h for end users.
The 640×480 mode makes sense only as an engineering baseline.

### 4.2 SCI1.1 (1992–1994) — 320×200×256, Same Resolution as SCI1

> **Correction note:** Wikipedia and the SCI wiki both confirm that SCI1.1 runs at
> **320×200×256** on DOS — identical screen resolution to SCI1. The 640×480×256
> resolution belongs to **SCI2** (1993), which is a separate, 32-bit protected-mode
> engine. SCI1.1 is "256-color VGA (enhanced)" — the enhancement is richer animation
> and sprite scaling, not resolution.

SCI1.1 artwork was created at 320×200×256. Compared to SCI1, SCI1.1 added:
- Improved sprite scaling and cel-based animation
- Enhanced palette management (the `Palette` kernel)
- Revised resource format (script/heap split)

For a VESA 640×480×256 driver targeting SCI1.1, the same Mode 13h analysis applies:
no visual benefit over the standard VGA driver. The VESA mode would display a
2×-upscaled or centred 320×200 image with the same aspect ratio problems as SCI1.

The genuine reason to build this driver is as **engineering groundwork** for the
SCI2 driver interface (see Section 5.3).

---

## 5. SCI Version and Resolution — Corrected Game Classification

> **Key correction from previous draft:** This section previously claimed SCI1.1
> games had "native 640×480×256 artwork." This was **wrong**. Per Wikipedia's SCI
> history table (sourced from sciwiki.sierrahelp.com), **640×480×256 belongs to
> SCI2**, not SCI1.1. Gabriel Knight and Police Quest 4 are SCI2 games, not SCI1.1.

### 5.1 SCI Version Resolution Summary

| Version | Year | DOS Resolution | Notes |
|---------|------|---------------|-------|
| SCI0 | 1988 | 320×200×16 (EGA) | Text parser |
| SCI1 | 1990 | 320×200×256 (VGA mode 13h) | Point-and-click |
| SCI1.1 | 1992 | 320×200×256 (VGA mode 13h) | Enhanced animation, same resolution |
| **SCI2** | **1993** | **640×480×256 (SVGA)** | **32-bit protected mode DOS extender** |
| SCI3 | 1996 | Native Windows 95 | Final version |

### 5.2 SCI1.1 Games (320×200×256 on DOS)

All run at standard VGA 320×200×256. A VESA driver displays these at 640×480 via
2× upscale or centered window — **not** at native 640×480 (the artwork does not
exist at that resolution for DOS).

| Game | Publisher | Year |
|------|-----------|------|
| King's Quest VI: Heir Today, Gone Tomorrow | Sierra | 1992 |
| Laura Bow 2: The Dagger of Amon Ra | Sierra | 1993 |
| Leisure Suit Larry 6: Shape Up or Slip Out | Sierra | 1993 |
| Quest for Glory 3: Wages of War | Sierra | 1993 |
| Space Quest 5: The Next Mutation | Sierra | 1993 |
| Freddy Pharkas: Frontier Pharmacist | Sierra | 1993 |
| Pepper's Adventures in Time | Sierra | 1993 |
| EcoQuest 2: Lost Secret of the Rainforest | Sierra | 1993 |

### 5.3 SCI2 Games (640×480×256 on DOS — Native SVGA)

These run at genuine 640×480×256 with high-resolution artwork. However, SCI2 uses
a **32-bit protected-mode DOS extender** — a fundamentally different architecture
from the 16-bit real-mode `.DRV` interface used by SCI0/SCI1/SCI1.1.

| Game | Publisher | Year | Notes |
|------|-----------|------|-------|
| **Gabriel Knight: Sins of the Fathers** | Sierra | 1993 | Photo-realistic backgrounds |
| **Quest for Glory IV: Shadows of Darkness** | Sierra | 1993 | |
| **Police Quest 4: Open Season** | Sierra | 1993 | Photo backgrounds |
| King's Quest VII (SCI2.1) | Sierra | 1994 | Slightly different sub-version |

> **Consequence for this study:** A 16-bit real-mode VESA `.DRV` targets SCI1/SCI1.1
> and gives 2×-upscaled 320×200 games in a 640×480 frame. Genuine native-resolution
> 640×480×256 for SCI2 games is a **separate, harder project** requiring
> understanding of the SCI2 32-bit driver interface.

### 5.4 KQ6 Windows CD-ROM — What It Actually Was

King's Quest VI shipped a Windows 3.1 CD-ROM version with higher-resolution art and
a Windows-native executable. This was **not** the DOS SCI1.1 interpreter running
at 640×480 — it was a separate Windows port using Windows GDI. The DOS version of
KQ6 is 320×200×256 only.

---

## 6. Hardware Speed Requirements

### 6.1 The Bottleneck: Bank-Switched VESA Writes

In VESA bank-switched mode, every 64KB of VRAM requires a bank-switch call. For
a full 640×480 screen update (307,200 bytes), there are 5 bank switches. Each INT
10h bank-switch call is expensive: **500–2000 CPU cycles** depending on the VGA
BIOS implementation.

For a **partial update** (only the dirty rectangle changes), the driver calls
`update_rect` with a bounding box. If 50% of the screen is dirty, expect 2–3 bank
switches per call.

The inner write loop is:
- Read 1 byte from SCI framebuffer (system RAM)
- Write 1 byte to A000:xxxx (VGA VRAM via ISA/VLB/PCI bus)
- Advance pointers
- Check for bank boundary; switch if needed

On 8-bit ISA VRAM access (old VGA), bus transfers are **slow**. On VLB/PCI VGA
(mid-1990s), VRAM writes are **much faster**.

### 6.2 Minimum Recommended CPUs

| CPU | Clock | Bus | VESA 640×480×256 | SCI1.1 Full Speed? |
|-----|-------|-----|------------------|--------------------|
| 286-12 | 12 MHz | ISA 8-bit | Possible but slow | No — unplayable |
| 386SX-16 | 16 MHz | ISA 16-bit | Marginal | Borderline |
| 386DX-33 | 33 MHz | ISA 32-bit | Yes | Playable |
| 386DX-40 | 40 MHz | ISA 32-bit | Yes | Comfortable |
| 486SX-25 | 25 MHz | ISA/VLB | Yes | Good |
| **486DX-33** | **33 MHz** | **ISA/VLB** | **Yes** | **Recommended minimum** |
| 486DX2-66 | 66 MHz | VLB | Excellent | Full speed |
| Pentium-60 | 60 MHz | PCI | Excellent | Full speed |

**Key factors:**
- ISA bus: ~8 MB/s max VGA write throughput
- VLB (VESA Local Bus): ~40–60 MB/s — enormous improvement
- PCI: ~130 MB/s — even faster
- INT 10h bank-switch penalty is the same regardless of bus speed

### 6.3 Fast Bank-Switch: Window Function Pointer

VESA VBE provides a **window function pointer** in the mode info block. Calling it
directly (far call to BIOS code) is 5–10× faster than INT 10h:

```nasm
; Instead of: INT 10h AX=4F05h BX=0 DX=bank
; Direct call:
mov   dx, bank_number
call  far [vesa_window_func]  ; ~50–100 cycles vs ~1000 for INT 10h
```

This optimization is mandatory for acceptable performance on a 386DX or 486SX.

### 6.4 Expected Performance on Target Hardware (640×480×256, partial updates)

| CPU | Bank switch method | Est. full-screen update | Frame rate (full) |
|-----|--------------------|------------------------|-------------------|
| 386DX-33 | INT 10h | ~80 ms | ~12 fps |
| 386DX-33 | Window function | ~20 ms | ~50 fps |
| 486DX-33 | INT 10h | ~40 ms | ~25 fps |
| 486DX-33 | Window function | ~10 ms | ~100 fps |
| 486DX2-66 | Window function | ~5 ms | ~200 fps |

SCI1.1 engine does not run at a fixed frame rate — it updates only dirty rectangles.
In practice, typical game scene updates are 20–60% of the screen, so real-world
frame times are proportionally better.

**Bottom line:** A **386DX-33 with window-function bank switching** is the practical
minimum for playable SCI1.1 at 640×480×256. A **486DX-33** is the recommended minimum
for comfortable play.

---

## 7. DOSBox Testing

### 7.1 VESA Support in DOSBox

**DOSBox fully emulates VESA VBE**, including mode 0x101 (640×480×256). This is a
major advantage over the XGA approach, where no emulator exists.

| Feature | DOSBox Status |
|---------|--------------|
| VESA mode 0x101 (640×480×256) | ✅ Supported |
| VESA mode info block | ✅ Supported |
| Bank switching (INT 10h AX=4F05h) | ✅ Supported |
| Window function pointer (direct call) | ✅ Supported |
| VBE 1.2 compliance | ✅ Supported |
| VBE 2.0 linear framebuffer | ✅ Supported (with `vesa_vbe20=true` in config) |
| 256-color DAC palette (INT 10h AX=4F08h) | ✅ Supported |
| Mode 0x101 display in DOSBox window | ✅ Renders at full internal resolution |

**DOSBox-X** supports VESA even more completely and allows fine-tuning of VBE
version and memory size.

### 7.2 DOSBox Configuration for VESA Development

In `dosbox.conf` (or `dosbox-dev.conf` for this workspace):

```ini
[dosbox]
memsize=16

[vbe]
vesa=true
svga_card=svga_vesa
vesa_mode=640x480x8

[cpu]
core=auto
cputype=pentium
cycles=50000    ; start high for development; lower to test on 386 equivalent
```

To simulate a 386DX-33:
```ini
[cpu]
cputype=386
cycles=15000    ; approx 386DX-33 equivalent
```

To simulate a 486DX-33:
```ini
[cpu]
cputype=486
cycles=30000
```

### 7.3 DOSBox Development Workflow

Because DOSBox supports VESA, the full driver development and debugging cycle can
run in DOSBox — no real hardware needed until final testing:

```
Edit NASM source  →  nasm -f bin  →  Run in DOSBox  →  See 640×480×256 output
```

This is a **complete development loop**: write, assemble, run, debug, iterate.
Compare to the XGA driver where every test requires the physical PS/2 Model 55SX.

The DOSBox `DEBUG` command and `LOG` feature allow inspection of VESA calls and
framebuffer contents. DOSBox-X adds a debugger with memory inspection.

### 7.4 Screenshot and Automated Testing

The existing `run_and_capture.py` workflow in `ASM-386-VGA/` can be adapted to
capture DOSBox screenshots of SCI1.1 games running at 640×480×256 — providing
visual verification of correct rendering.

---

## 8. SCI Kernel/Driver Interface — Insights from SCICompanion

*Source: https://scicompanion.com/Documentation/classlibrary.html and linked pages*

SCICompanion (by Phil Fortier) is the primary modern development tool for SCI1.1
games. Its documentation reveals the two-layer architecture of SCI and provides
important facts that directly affect driver implementation.

### 8.1 Two Distinct Layers — Do Not Confuse Them

| Layer | What it is | Documented by |
|-------|-----------|--------------|
| **Game script layer** | `Actor`, `Ego`, `Room`, `Prop`, `Motion` etc. — the SCI scripting class library | SCICompanion class library |
| **Kernel layer** | `DrawPic`, `DrawCel`, `Animate`, `Palette`, `Show` etc. — built-in functions the interpreter provides to scripts | SCICompanion kernel reference |
| **Driver layer** | The `.DRV` binary called by the interpreter for all hardware output | Must be reverse-engineered from existing `.DRV` files |

The class library page documents Layer 1. The kernel reference documents Layer 2.
**The driver `.DRV` interface (Layer 3) is not documented by SCICompanion** — it
is what we must reverse-engineer from existing `VGA.DRV` binaries.

### 8.2 Key Kernel Functions That Drive the Hardware

These kernel functions are the ones that eventually result in calls into our `.DRV`:

#### `Graph grGET_COLORS`
Returns the color resolution the interpreter is running in.
- Returns `16` in EGA mode
- Returns `-1` in CGA mode
- Returns `25` in original VGA interpreter (note: NOT 256 — this needs investigation)
- Returns `256` in ScummVM

**Driver implication:** Our `get_color_depth` dispatch function (index 0) must
return the value the interpreter expects. The original VGA driver returns `25` per
the SCICompanion example. This quirk must be confirmed by disassembly — if the
interpreter uses this value internally for rendering decisions, returning `256`
instead of `25` could break things. Most likely the interpreter only checks `> 16`
to distinguish VGA from EGA.

#### `Animate`
The main game loop rendering function. Internally calls all drawing operations,
then triggers the driver's `update_rect` to push dirty rectangles to the display.
This is the most-called driver entry point in any SCI game.

#### `Show(screen)`
Primarily a debugging utility that forces a full repaint of the visual, priority,
or control screen. Sets the `picNotValid` flag so the background is redrawn on
the next cycle. Not the primary update path — `Animate` handles normal rendering.

#### `SetVideoMode(number)`
Confirmed by SCICompanion: **"Used by KQ6's intro. This is not supported by the
Sierra interpreter included in the SCI1.1 template game."**

This is a significant finding. It means:
- `SetVideoMode` is a KQ6-specific kernel, not standard SCI1.1
- Most SCI1.1 games do not call `SetVideoMode` at all
- The video mode is set once in `init_driver` at game startup and does not change
- Only KQ6's FMV intro sequences may trigger a mode switch mid-game
- For a first-version driver, `SetVideoMode` can be implemented as a no-op

#### `Palette` (SCI1.1 only)
A rich palette management kernel with sub-functions:
- `palSET_INTENSITY` — fade color ranges in/out
- `palANIMATE` — cycle palette colors (animated fire, water effects)
- `palSET_FROM_RESOURCE` — load a 256-color palette from a PAL resource
- `palFIND_COLOR` — find nearest palette entry to an RGB value
- `palSAVE` / `palRESTORE` — push/pop palette state

The interpreter assembles all these palette changes into a final 256-entry RGB table
and calls the driver's `set_palette` with the result. The driver simply writes the
256×3 bytes to the VGA DAC — it does not need to understand `palANIMATE` itself.

**Driver implication:** `set_palette` receives 256 RGB triplets and writes them to
VGA ports 0x3C8/0x3C9. This is straightforward. However, palette animation
(`palANIMATE`) may result in `set_palette` being called once per game cycle — the
driver must be fast. A VGA DAC write of 256 colors takes ~150 µs at VGA speed,
which is acceptable.

#### `Graph grSAVE_BOX` / `Graph grRESTORE_BOX`
These operate on **the interpreter's internal visual buffer**, not on display VRAM.
The driver's `save_screen` / `restore_screen` are therefore called for a different
purpose: saving and restoring the *displayed* pixels behind popup dialogs and menus
that overlay the rendered game image.

**Driver implication:** `save_screen` / `restore_screen` must save/restore actual
VRAM pixels (what is currently visible on screen), not the internal back-buffer.
For a VESA driver this means reading back from VRAM — which is slow on VGA hardware.
An alternative is to maintain a shadow copy of the last-displayed frame in system
RAM and use that as the save/restore source.

### 8.3 SCICompanion as a Development Tool

SCICompanion can be used during driver development for:

| Task | How |
|------|-----|
| Open any SCI1.1 game folder | File → Open, point at the game directory |
| List all resources | Left pane shows views, pics, scripts, palettes etc. |
| Decompile SCI scripts | Right-click a script resource → Decompile |
| Examine resource formats | Palette editor shows the 256-color palettes |
| Check interpreter version | Game → Version detection |

The decompiler is particularly useful for understanding which kernel functions a
specific game calls at startup and in its main game loop — revealing exactly which
dispatch indices are most critical to implement first.

**Note:** SCICompanion does not open `.DRV` files (they are not SCI resources). The
`.DRV` binary interface still requires disassembly with Ghidra or IDA Free.

---

## 9. Driver Architecture

### 8.1 Memory Layout

The SCI engine maintains its own internal framebuffer in conventional DOS memory
(320×200 or 640×480, 8-bit). The driver's `update_rect` is called to push a dirty
rectangle from this buffer to the display.

For VESA 640×480×256:

```
SCI internal framebuffer (640×480×1 byte):  307,200 bytes  ~300 KB in DOS RAM
VESA VRAM (via A000:0000 + bank switch):    307,200 bytes  on VGA card
```

**Memory concern:** 640×480 = 307,200 bytes of conventional memory for the
framebuffer. Combined with the SCI interpreter, game resources, and DOS overhead,
this approaches the 640 KB DOS limit. In practice SCI1.1 games typically use EMS
or XMS for resource caching; the framebuffer must fit in conventional memory.

- 307,200 bytes for the framebuffer is tight but feasible (many SCI1.1 games load
  their interpreter + data well under 400 KB before framebuffer).
- An XMS-based framebuffer is an advanced optimization for a later version.

### 8.2 update_rect with Bank Switching

The core function. Pseudocode:

```nasm
; update_rect(left, top, right, bottom)
; src = SCI framebuffer base + top*640 + left
; dst = VRAM offset = top*640 + left

for each row from top to bottom:
    dst_offset = row * 640 + left
    bank_needed = dst_offset / 65536
    if bank_needed != current_bank:
        call switch_bank(bank_needed)
        current_bank = bank_needed
    
    ; check if this row straddles a bank boundary
    row_end_offset = dst_offset + width - 1
    if (row_end_offset / 65536) != bank_needed:
        ; split: write first_chunk bytes, switch bank, write remainder
        first_chunk = 65536 - (dst_offset & 0xFFFF)
        rep movsb   ; first_chunk bytes
        call switch_bank(bank_needed + 1)
        current_bank++
        rep movsb   ; remaining bytes
    else:
        rep movsb   ; full row, no bank crossing
```

The bank-split case is rare (5 rows per frame) but must be handled correctly or
the display will tear/corrupt at bank boundaries.

### 8.3 set_palette

VESA 640×480×256 uses the standard VGA DAC registers (ports 0x3C8/0x3C9). The
`set_palette` call receives 256 RGB triplets from the SCI engine:

```nasm
set_palette:
    mov  dx, 0x3C8
    xor  al, al       ; start at color 0
    out  dx, al
    mov  dx, 0x3C9
    ; loop 256 × 3 bytes (R, G, B — each 0–63 in VGA DAC)
    ; SCI provides 0–255 values; shift right 2 to get 0–63
    rep outsb
```

### 8.4 Hardware Cursor Strategy

VESA 640×480×256 has no hardware cursor. Options:

**Option A — Software sprite cursor:**
- Save the pixels under the cursor on `show_cursor` / `move_cursor`
- Render the cursor shape on top
- Restore on `hide_cursor`
- Cost: 2 extra blits (save + draw) per cursor move
- This is how Sierra's original VGA drivers handle the cursor

**Option B — Transparent software cursor (preferred):**
- Always render the cursor on top of the dirty rectangle in `update_rect`
- No separate save/restore step
- Simpler but requires cursor position tracking in the update loop

Option A is the standard approach and maps cleanly to the dispatch table.

### 8.5 Full Dispatch Table

| Index | Function | Implementation |
|-------|----------|---------------|
| 0 | `get_color_depth` | Return 8 |
| 1 | `init_driver` | Set VESA mode 0x101; save old mode |
| 2 | `restore_mode` | Restore original video mode |
| 3 | `update_rect` | Bank-switched VESA blit |
| 4 | `show_cursor` | Software sprite: save + draw |
| 5 | `hide_cursor` | Restore saved pixels |
| 6 | `move_cursor` | Hide, reposition, show |
| 7 | `load_cursor` | Store cursor shape in driver |
| 8 | `shake_screen` | Adjust display start address register |
| 9 | `set_palette` | VGA DAC write (ports 0x3C8/0x3C9) |
| 10 | `save_screen` | Blit VRAM region to system RAM buffer |
| 11 | `restore_screen` | Blit system RAM buffer back to VRAM |

---

## 10. Comparison: VESA VGA Driver vs XGA Driver

| Property | VESA VGA Driver | XGA Driver |
|----------|-----------------|-----------|
| Target hardware | Any 386/486 with VESA VGA | IBM PS/2 with XGA card |
| Compatibility | Universal (millions of PCs) | One specific machine family |
| DOSBox testing | **Yes — full DOSBox support** | No — real hardware only |
| Implementation complexity | Medium | High |
| Bank switching required | Yes (slow ISA writes) | No (linear VRAM) |
| Blit performance | CPU-driven, ISA bus | Hardware BitBLT engine |
| Performance on 386SX-16 | Marginal | Good |
| Performance on 486DX-33 | Good | Not applicable |
| VGA card required | Any VESA card | IBM XGA/XGA-2 |
| Hardware cursor | Software only | Hardware (free) |
| Estimated effort | **6–10 weeks** | 13–19 weeks |
| Historical significance | Low for SCI1/1.1 — engineering practice only | Highest (world-first on XGA) |
| Recommended order | **Build this first** | Build after VESA baseline |

**Recommendation:** Write the VESA driver first only if the goal is to learn the
SCI1/SCI1.1 `.DRV` interface and test the framework before attempting SCI2. It
provides:
- A testable driver skeleton in DOSBox
- Proof that the dispatch table and parameter conventions are correct
- The foundation for an SCI2 driver (which has genuine native 640×480 artwork)

If the goal is visual impact, skip VESA and target SCI2 directly — accepting that
the SCI2 32-bit driver interface needs separate reverse-engineering work.

---

## 11. Relationship to Existing SCI0 Driver (PC1.DRV)

The production SCI0 driver in `Sierra-SCI0-Driver-for-Olivetti-PC1/PC1.DRV` provides:

- Verified driver entry convention (3-byte JMP, 6-byte signature, Pascal strings)
- Working dispatch table pattern (reuse indices 0–9 directly)
- Hardware cursor approach (adapt software sprite for VESA)
- `shake_screen` pattern (display offset registers)
- NASM 16-bit real-mode build system (identical `nasm -f bin`)

The SCI1/SCI1.1 additions are:
- `set_palette` (new — SCI1 moves palette control to the driver)
- `save_screen` / `restore_screen` (new — needed for portrait/dialog overlays)
- VESA mode-set instead of V6355D port writes
- Bank-switching in `update_rect` (replaces interlace-bank logic)
- 256-color output (replaces 16-color nibble packing)

Estimated ~60% of the driver structure is directly reusable from PC1.DRV.

---

## 12. Development Plan

### Phase 1 — Reverse Engineer SCI1/SCI1.1 Driver API (3–5 weeks)

1. Extract `VGA.DRV` from a SCI1 game installation (KQ5, SQ4, or PQ3).
2. Disassemble with Ghidra or IDA Free; map every dispatch table entry.
3. Document parameter passing: stack layout, register usage, return values.
4. Extract `VGA.DRV` (or `256.DRV`) from a SCI1.1 game (KQ6, LSL6).
5. Diff the two dispatch tables; identify new/changed functions.
6. Cross-reference with ScummVM `engines/sci/graphics/drivers/` source code.

**Deliverable:** `SCI1-DRIVER-API.md` — complete function specification.

### Phase 2 — VESA Baseline in DOSBox (2–3 weeks)

1. Write minimal driver: `init_driver` sets VESA 0x101; `update_rect` does a
   bank-switched VESA blit using INT 10h bank switching.
2. Implement `set_palette` via VGA DAC.
3. Implement software cursor (save/draw/restore).
4. Test with King's Quest V (SCI1) in DOSBox — verify 640×480 display
   (with 2× upscale of 320×200 artwork).
5. Test with King's Quest VI (SCI1.1) in DOSBox — verify 640×480×256 output.

**Deliverable:** `VESA.DRV` version 0.1 — functional in DOSBox.

### Phase 3 — Performance Optimization (1–2 weeks)

1. Replace INT 10h bank switch with window function pointer call.
2. Implement `rep movsd` (32-bit) inner loop for VRAM writes.
3. Add dirty-rectangle tracking to skip unchanged regions.
4. Benchmark in DOSBox with `cycles=15000` (386DX-33 equivalent).

**Deliverable:** `VESA.DRV` version 0.5 — optimized for real hardware.

### Phase 4 — Real Hardware Testing (1–2 weeks)

1. Test on a 486DX-33 or 486DX2-66 PC with a VESA VGA card.
2. Verify bank-split row handling is correct (critical visual check).
3. Verify palette and cursor on real hardware vs DOSBox.
4. Record KQ6 running in 640×480×256 on real 1993 hardware.

**Deliverable:** `VESA.DRV` version 1.0 — production release.

### Phase 5 (optional) — XGA Acceleration Layer

Replace `update_rect`, cursor, and fill functions with XGA hardware acceleration.
See [FEASIBILITY-STUDY-SCI1-XGA-DRIVER.md](FEASIBILITY-STUDY-SCI1-XGA-DRIVER.md)
for details. This phase reuses the dispatch table and API work from Phases 1–4.

---

## 13. Feasibility Verdict

| Factor | Assessment |
|--------|-----------|
| VESA VBE support on target hardware | Excellent — ubiquitous from 1991 onward |
| DOSBox testing | Full support — complete dev loop possible |
| Implementation complexity | Medium — bank splitting is the hard part |
| SCI1/SCI1.1 API reverse engineering | Required — same gating risk as XGA study |
| Minimum viable hardware | 386DX-33 with VESA card |
| Recommended hardware | 486DX-33 with VESA card |
| Estimated effort | **6–10 weeks** |
| Historical significance | Engineering practice; stepping stone to SCI2 |
| Overall feasibility | **YES — simpler and more testable than XGA** |

This is useful only as an engineering stepping stone. Build `VESA.DRV` to learn
the SCI1/SCI1.1 `.DRV` binary interface and prove the framework in DOSBox. The
real project with visual payoff is an **SCI2 driver** — where the artwork genuinely
exists at native 640×480×256.

---

## Appendix A: VESA VBE INT 10h Quick Reference

| Function | AX | Parameters | Returns |
|----------|----|-----------|---------|
| Get VBE info | 4F00h | ES:DI → 512-byte buffer | AX=004Fh on success |
| Get mode info | 4F01h | CX=mode, ES:DI → 256-byte buffer | AX=004Fh |
| Set video mode | 4F02h | BX=mode (set bit 14 to keep VRAM) | AX=004Fh |
| Get current mode | 4F03h | — | BX=current mode |
| Bank switch | 4F05h | BX=0 (write), DX=bank number | AX=004Fh |
| Get/set DAC width | 4F08h | BL=1 (get), BL=0 (set), BH=bits | — |

Mode numbers:
- 0x100 = 640×400×256
- **0x101 = 640×480×256** ← target
- 0x103 = 800×600×256
- 0x105 = 1024×768×256

---

## Appendix B: VESA Mode Info Block (partial — key fields)

```c
struct VBE_ModeInfo {
    uint16_t ModeAttributes;      // +0x00: bit 7 = linear framebuffer available
    uint8_t  WinAAttributes;      // +0x02
    uint8_t  WinBAttributes;      // +0x03
    uint16_t WinGranularity;      // +0x04: bank granularity in KB
    uint16_t WinSize;             // +0x06: bank size in KB (typically 64)
    uint16_t WinASegment;         // +0x08: typically 0xA000
    uint32_t WinFuncPtr;          // +0x0C: ← fast bank-switch function pointer
    uint16_t BytesPerScanLine;    // +0x10: bytes per row (may be > 640)
    uint16_t XResolution;         // +0x12: 640
    uint16_t YResolution;         // +0x14: 480
    ...
    uint8_t  BitsPerPixel;        // +0x19: 8
    ...
    uint32_t PhysBasePtr;         // +0x28: VBE 2.0 linear framebuffer address
};
```

The `WinFuncPtr` at offset 0x0C is the fast bank-switch call target. Store it at
driver initialization and use it instead of INT 10h for all bank switches.

---

## Appendix C: Relevant VGA Cards with VESA Support (1991–1994)

| Card | Chip | VESA | Max Resolution | Notes |
|------|------|------|---------------|-------|
| S3 805/928 | S3 | Native | 1024×768×256 | Excellent DOS VESA; VLB versions fast |
| Tseng ET4000 | Tseng | Native | 1024×768×256 | Very fast ISA card; popular DOS choice |
| Tseng ET4000/W32 | Tseng | Native | 1024×768×256 | VLB; extremely fast |
| Cirrus Logic GD5422/5428 | Cirrus | Native | 1024×768×256 | Common budget card |
| Trident 8900C/9000 | Trident | Native | 1024×768×256 | Slower; widespread |
| ATI Mach32 | ATI | Native | 1024×768×256 | Good all-round; has 2D accel too |
| Paradise/WD | Western Digital | VESA TSR | 640×480×256 | Older; may need UNIVBE |
| OAK OTI-077 | OAK | Native | 1024×768×256 | Budget; decent VESA |

Cards without native VESA BIOS can use **UNIVBE** (Universal VESA BIOS Extension)
— a TSR that patches the BIOS and adds VBE support. This makes even very old VGA
cards (Trident 8800, older Paradise cards) work with a VESA driver.
