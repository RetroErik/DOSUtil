# XGA Acceleration Targets and Demo Ideas

**Author:** Retro Erik  
**Date:** May 2026  
**Status:** Reference notes

> **Status note:** This is a historical idea list, not the active work plan. Its
> performance figures are estimates, not measured results. The current DOS demo
> and verified test status are documented in [xga-demo/README.md](xga-demo/README.md).

---

## 1. Purpose

This file is a general reference for **what IBM XGA is good at** on the PS/2 Model 55SX,
which types of software can realistically benefit from it, and which demo ideas make sense
for real hardware.

It replaces the earlier Sierra SCI1 / SCI1.1-specific note, whose premise was invalidated.

---

## 2. Quick Correction on Sierra SCI

The original Sierra-specific XGA idea is no longer considered a valid target for these reasons:

1. **SCI1 and SCI1.1 on DOS are 320x200x256, not native 640x480x256.**
2. **The XGA coprocessor does not accelerate VGA Mode 13h.** In 320x200x256 the card behaves as plain VGA.
3. **SCI1/SCI1.1 already ran acceptably on 386SX-class hardware.** There is no real performance problem to solve.

If Sierra is revisited in the future, the meaningful XGA target is **SCI2**, not SCI1/SCI1.1.
SCI2 is a separate 32-bit protected-mode problem.

---

## 3. Hardware Context

### IBM PS/2 Model 55SX

- CPU: **386SX-16**
- Bus: **MCA**
- Built-in VGA is functional but not fast
- Good platform for testing whether a hardware blitter can materially improve DOS graphics work

### IBM XGA Display Adapter/A

- True 2D accelerator
- **BitBLT engine**
- **Pattern fill engine**
- **Line-draw engine**
- **Hardware cursor**
- Native accelerated modes begin at **640x480x256**
- Higher-bandwidth VRAM path than ordinary VGA on the same class of machine

XGA is best thought of as a DOS-era workstation graphics accelerator. Its value is not
"make VGA a little faster". Its value is using XGA-native graphics modes and offloading
rectangle copies, fills, lines, and cursor work from the CPU.

---

## 4. What XGA Is Actually Good At

XGA is most attractive when a project does one or more of these:

- Uses **640x480x256** as a true working mode
- Does frequent **rectangle copies** or sprite-style blits
- Redraws windows, panels, or scrolling regions
- Needs a **hardware cursor**
- Uses many **filled rectangles** or line primitives
- Is bottlenecked by CPU-driven VRAM writes on a 386SX

Good fits:

- Tile or panel-based games at 640x480
- Adventure or UI-heavy engines with lots of rectangle movement
- CAD, paint, charting, or scientific visualization software
- Demo effects built around block moves, masked animation, and layered redraws

Poor fits:

- Standard VGA games that stay in **320x200x256 Mode 13h**
- Software whose bottleneck is game logic rather than drawing
- Projects that never leave VGA-compatible modes

---

## 5. Demo Ideas That Make Sense

### 5.1 Boing Ball Style XGA Demo

This remains a very good XGA target.

Why it fits:

- Ball movement can use BitBLT-style masked copies
- Floor or background can use pattern fills
- Shadow and overlap effects can stress copy performance
- A hardware cursor is not required, so the demo can focus on blitter performance
- The result is visually clear and easy to benchmark against plain VGA

Possible demo goals:

- One bouncing ball with shadow and floor grid
- Multiple simultaneous balls to stress the blitter
- Windowed status overlay showing frame timing
- Side-by-side benchmark version: VGA path vs XGA path

### 5.2 Panorama Scroll Demo

A strong fit and possibly the simplest first XGA project.

**Core idea:** Load a large image (e.g. 1024×700 pixel art scene) into off-screen VRAM once
at startup. Each frame issue a single BitBLT command copying a 640×480 window from
`(scroll_x, scroll_y)` in the off-screen region to the display base. The CPU only touches
two integers per frame — the blitter does all pixel movement.

**VRAM layout at 640×480×256:**

- `0x00000`–`0x4AFFF` → visible display (307,200 bytes)
- `0x4B000`–`0xFFFFF` → off-screen storage (~716KB, fits a 1024×700 source)

**Key XGA feature used:** The BitBLT source pitch register can be set independently from
the destination pitch, so a 1024-wide source image blits correctly into a 640-wide display
without any CPU adjustment.

**Why it showcases XGA well:**

- The speedup is obvious and quantifiable: a 386SX-16 copying 307KB by hand each frame
  is painfully slow; the blitter does the same copy in a fraction of the time.
- Smooth diagonal scrolling with inertia (accelerate/decelerate toward a target position)
  looks polished for minimal code.
- Image content matters: a high-detail pixel art panorama makes 640×480×256 quality
  immediately visible alongside the scroll speed.
- Wrapping/infinite scroll requires only two or four blits per frame to paste the seam —
  still well within blitter budget.

**Compared to the Boing Ball:**

| | Boing Ball | Panorama Scroll |
|---|---|---|
| Blitter ops per frame | Many small masked blits | One large rectangle copy |
| CPU work per frame | Coordinate math | Two integer increments |
| Masking / transparency needed | Yes | No |
| Complexity | Medium | Lower |

### 5.3 Scrolling Tilemap Demo

Also a strong fit.

- Use XGA BitBLT for scrolling the playfield
- Redraw only newly exposed columns/rows
- Add sprites on top to test mixed CPU + accelerator pipelines

### 5.3 Desktop / Windowing Demo

Another good showcase for XGA.

- Draggable overlapping windows
- Filled panels and borders
- Hardware cursor usage
- Save/restore rectangle operations

This is a natural way to show what XGA was designed for.

---

## 6. Other Software Targets Worth Considering

These are not all equally practical, but they are better-aligned with XGA than SCI1/SCI1.1.

### Strong candidates

- **Custom XGA demo framework**
- **Boing Ball / blitter showcase demo**
- **Scrolling tile engine prototype**
- **Paint or sprite editor prototype**
- **Windowing / desktop mockup**
- **Fractal or graph visualizer** where large filled or copied regions matter

### Interesting but harder

- Early GUI or CAD-style applications
- DOS paint programs with custom drivers
- Engines that can realistically be patched to use 640x480x256 and blit rectangles efficiently

### Be careful with these

- Existing commercial VGA games in 320x200: usually poor XGA targets unless the engine can be moved to an XGA-native mode
- Doom/Wolf-style software renderers: acceleration is much less direct because the hot path is not mostly rectangle BitBLT work

---

## 7. Commercial Game Candidate Evaluation

These are researched verdicts for specific titles considered as XGA targets.

### 7.1 NASCAR Racing (1994, Papyrus / Sierra)

**Verdict: Possible starting point, not a clean fit**

- The CD-ROM version **shipped with a real 640×480×256 SVGA mode** (`nascar -h`)
- Contemporary reviewers noted SVGA was "too demanding for most computers of its age"
- Later bundles were paired with Matrox Millennium and Diamond Edge 3D as showpiece hardware
- The rendering engine is **scanline/perspective-correct** (IndyCar Racing lineage), not a heavy polygon engine — CPU budget per frame is significantly lower than Strike Commander
- At 320×200 the game would likely run acceptably on a 55SX; the SVGA mode on a 386SX-16 would still crawl because the bottleneck is CPU-side scanline rendering, not the framebuffer blit
- XGA BitBLT would not help the core rendering work; it would only accelerate the final blit to screen, which is not the dominant cost
- **No public source code** — making it use XGA natively would require reverse engineering the SVGA rendering path
- Key distinction from other candidates: at least a 640×480×256 mode was actually shipped, so it is not a fictional target

**Bottom line:** The most realistic of the commercial candidates surveyed, but the CPU-side scanline rendering is still the bottleneck on a 386SX-16. Not a recommended first XGA project, but useful as a benchmark reference.

### 7.2 Frontier: Elite II (1993, Braben / Chris Sawyer port)

**Verdict: Poor XGA target**

- PC port by Chris Sawyer, written in 80286 assembly, heavily hand-optimised
- No evidence of native 640×480×256 DOS support; likely targeted standard VGA modes (probably 320×200×256)
- Adapting to 640×480×256 would be an engineering experiment, not unlocking an intended mode
- XGA would add nothing to the core 3D rendering
- **No public source code**

### 7.3 Strike Commander (1993, Origin / RealSpace engine)

**Verdict: Wrong hardware class**

- Gouraud shading, texture mapping; contemporary press called it "probably the most hardware-intensive game yet released"
- Recommended spec was 486-DX2/66 — a 386SX-16 is the wrong CPU regardless of the display path
- No evidence of native 640×480×256 mode; likely 320×200×256
- XGA would not help the 3D CPU bottleneck
- **No public source code** (reverse-engineering project by Fabien Sanglard / libRealSpace exists but is incomplete)

---

## 8. Sierra-Specific Takeaway


If the goal is to keep a Sierra note for reference, the only point worth preserving here is:

- **SCI1/SCI1.1 are not worthwhile XGA targets**
- **SCI2 may be**

See also: [SCI2-XGA-RESEARCH-NOTES.md](SCI2-XGA-RESEARCH-NOTES.md)

That should stay as a short historical note, not as the main subject of this file.

The detailed SCI discussion now belongs in the feasibility-study files, where the corrections
and invalidated assumptions are recorded explicitly.

---

## 9. Development Constraints

- **No mainstream emulator currently provides useful XGA support for this work**
- Real validation must happen on actual PS/2 XGA hardware
- This increases the value of smaller, self-contained demos before attempting larger software integrations

Practical consequence:

- Start with a **tight benchmarkable demo**
- Prove mode set, BitBLT, fill, line, and cursor primitives
- Only then consider larger integration work

---

## 10. Suggested Order of Work

1. **Write a minimal XGA mode-set and primitive test**
2. **Build a Boing Ball / blitter demo**
3. **Build a scrolling tile or windowing demo**
4. **Only after that, evaluate a larger software or engine target**

This order gives the clearest proof of what the hardware is actually good at.

---

## 11. Bottom Line

Yes, this file should be changed.

The Sierra SCI1 / SCI1.1 framing should not remain the main topic, because it is based on
false premises and points toward the wrong kind of project.

The useful material to keep is:

- XGA as a 2D acceleration target
- Demo concepts such as a **Boing Ball** showcase
- Other software categories that genuinely benefit from 640x480x256 acceleration
- The reminder that **SCI2**, not SCI1/SCI1.1, is the only Sierra direction that still makes sense

This renamed file is intended to serve exactly that role.