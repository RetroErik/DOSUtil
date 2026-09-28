# Downloaded Demo Sources: Practical XGA Porting Assessment

**Author:** GitHub Copilot  
**Date:** May 12, 2026  
**Workspace:** `XGA/Demoes vith source code/`

> **Status:** Historical source survey, not a current roadmap. Porting plans,
> effort estimates, and expected frame rates below are speculative and were not
> benchmarked. See [xga-demo/README.md](xga-demo/README.md) for the current
> project and observed test results.

---

## Overview

You have **5 major demoscene source packages** downloaded. Here's a ranked assessment of their **practical value for XGA porting** on your 55SX with 80387.

---

## 1. **AMNESIA** ⭐⭐⭐⭐⭐
**Source:** Tran (Renaissance)  
**Language:** 100% NASM/TASM Assembly  
**Files:** `Amnesia.asm` (single file)  
**Difficulty:** Medium-High  
**Maturity:** Excellent code, tight optimizations

### What It Is
- **Protected-mode vector 3D engine**
- Temple geometry with rotating stars
- Flat-shaded polygon rendering
- Perspective projection with depth sorting
- Integer math with sin/cos tables

### XGA Suitability: ⭐⭐⭐⭐⭐ PERFECT
- **Why:** This is your **#1 target for tech demo showcase**
  - Already have it open and analyzed
  - 3D math benefits from 80387 coprocessor (runs in parallel)
  - Polygon fill is prime target for XGA pattern-fill acceleration
  - Visually impressive at 640×480×256
  - Expected framerate improvement: **25–35 FPS** (vs. 18–25 on VGA)

### Porting Strategy
1. **Keep all:** Rotation tables, vector data, projection math, depth sort
2. **Adapt for 640×480:**
   - Scale object coordinates if needed (or keep fixed perspective)
   - Adjust clipping plane to new viewport
   - Recompile edge buffers for 640-pixel width
3. **Use XGA pattern fill** for polygon interiors (instead of CPU scanline fill)
4. **Benchmark:** Single-file makes before/after comparison easy

### Estimated Effort: **2–3 weeks** (depends on 80387 FP code reuse)

### Why Not Just Run It?
- Current code targets **VGA 320×200 or protected-mode VESA modes**, likely not XGA-native
- No XGA register calls; would work but without acceleration benefit
- Porting to native XGA 640×480×256 is what captures the speedup

### Recommendation
**START HERE** — This is the crown jewel porting target. With 80387 handling rotation and XGA filling polygons, you get a beautiful demonstration of hardware synergy.

---

## 2. **BYTES & KISSES (bkisssrc)** ⭐⭐⭐⭐
**Source:** Jeff Lawson (JL Enterprise)  
**Language:** Assembly (real-mode)  
**Folders:** BOUNCE, SINUS, TUNNEL, IRIS, STRETCH, CREDITS, TITLE, LOADER  
**Complexity:** Low-to-Medium per effect

### What It Is
- **Multi-effect real-mode demo**
- Bouncing ball with shadow effects
- Sinus wave animations
- Tunnel effect
- Iris transitions
- Scrolling text/credits
- Tile-based sections

### XGA Suitability: ⭐⭐⭐⭐ EXCELLENT
- **Why:** Library of **proven blitting patterns**
  - Bounce/shadow effects → Perfect for masked BitBLT
  - Scrolling sections → Panorama scroll reference
  - Tile effects → Tilemap inspiration
  - Self-contained effects (easy to extract)

### What to Extract
- **BOUNCE/** → Sprite positioning, shadow casting, masked copy patterns
- **SINUS/** → Waveform animation without heavy CPU math (easing functions)
- **TUNNEL/** → Check if uses blitted textures or pure math
- **CREDITS/** → Scrolling text with backdrop

### NOT Ideal For
- TUNNEL is probably per-pixel math (skip for XGA)
- IRIS transitions (palette effects, not blitting)

### Estimated Effort: **1–2 weeks per extracted effect**

### Recommendation
**SECONDARY SOURCE** — Use this as a **reference library** after Amnesia. Extract the BOUNCE effect for:
1. Masked sprite blitting reference
2. 2D collision/physics baseline
3. Benchmarking XGA BitBLT vs. CPU copy

---

## 3. **CONTRAST (contrsrc)** ⭐⭐⭐
**Source:** TFL-TDV (Type One, Morflame, Sam, Bismarck, Gopi, Karma)  
**Language:** C + Assembly hybrid  
**Complexity:** HIGH (multi-coder, complex integration)  
**Size:** ~1.1 MB source

### What It Is
- **Large, professional party demo**
- Effects: 32-bit 3D, 3D ice, ANSI art, distortion, plasma, rotazoom, shadeline, snake warp, title sequence
- Award-winning composition
- Well-commented by individual coders

### XGA Suitability: ⭐⭐⭐ MODERATE
- **Pros:**
  - Multiple different effect styles
  - Good ASM comments (per coder)
  - Some effects (distortion, rotazoom) could benefit from XGA 640×480×256 mode
- **Cons:**
  - Tightly integrated; hard to extract individual effects
  - C + ASM hybrid = complex build setup
  - Each effect written by different person; inconsistent architecture
  - VGA-centric; major refactoring to use 640×480×256 per effect

### Best Extracts
- **3DICE.OBJ / 3D ICE:** Solid polygon rendering (like Amnesia but different approach)
- **DISTORT.OBJ / PLASMA.OBJ:** CPU-heavy; less XGA benefit, but study reference
- **ROTAZOOM.OBJ:** Could benefit from 640×480 native mode for texture quality

### Estimated Effort: **3–4 weeks** to extract and adapt one effect

### Recommendation
**LOWER PRIORITY** — Use as **backup reference** if you need:
- Alternative 3D approach (compare to Amnesia)
- Plasma implementation for comparative benchmarking (show XGA doesn't help per-pixel)
- Distortion or transformation techniques

---

## 4. **HELL (hellsrc)** ⭐⭐
**Source:** Tran (protected mode)  
**Language:** 100% Assembly (TASM)  
**Complexity:** VERY HIGH  
**Status:** **REQUIRES ORIGINAL HELL.EXE** (data not included)

### What It Is
- **Protected mode 3D demo**
- Requires external data/music from original EXE
- Tight, optimized assembly
- GUS-dependent (music timing)

### XGA Suitability: ⭐⭐ POOR
- **Cons:**
  - Cannot compile standalone (missing original data)
  - Extremely tight code (hard to read without deep knowledge)
  - Protected mode extender overhead
  - GUS timing dependencies (your hardware likely different)
  - Would require reverse-engineering to understand data format

### Why Not Use It
- **Blocker:** Requires original binary data that's no longer available/documented
- **Too specialized:** The tight assembly is for elegance and skill demo, not reusability
- **Overkill:** Features you don't need (GUS, complex protected mode)

### Recommendation
**SKIP** — Use Amnesia instead (simpler, standalone, Tran's code quality is similar).

---

## 5. **COPPER FAKED (cfsource)** ⭐
**Source:** Stefan Ohrhallinger (The Faker / Aardvark)  
**Language:** Pascal + Assembly hybrid  
**Complexity:** MEDIUM  
**Age:** ~1993

### What It Is
- **VGA palette cycling "copper" effects**
- ANSI art and palette manipulation
- Rasterline-synchronized palette changes

### XGA Suitability: ⭐ VERY POOR
- **Why:**
  - Copper effects = **per-rasterline palette tricks**, VGA-specific
  - XGA 640×480×256 has different timing/architecture
  - Not applicable to 3D, blitting, or geometry-heavy work
  - Palette cycling is a **1990 VGA technique**, not a useful XGA pattern

### Recommendation
**SKIP FOR XGA** — Interesting as a reference for VGA understanding, but not porting material.

---

## Recommended Porting Sequence

### Phase 1: Proof of Concept (Weeks 1–3)
**Primary:** Amnesia vector engine
- Adapt to 640×480×256 XGA native mode
- Implement XGA pattern-fill for polygon interiors
- Benchmark VGA vs. XGA on real hardware
- Expected result: **25–35 FPS** (visible improvement)

### Phase 2: Complementary Effects (Weeks 4–6)
**Option A (safer):**
1. Extract Bytes & Kisses **BOUNCE** for masked sprite demo
2. Build simple tile-scroll panorama (custom)

**Option B (more ambitious):**
1. Contrast **3D ICE** or **ROTAZOOM** (if time permits)
2. B&K BOUNCE as reference validation

### Phase 3: Polish & Benchmarking (Weeks 7+)
- Side-by-side VGA/XGA demos
- Performance documentation
- Optional: Multi-demo collection or advanced parallax effects

---

## Summary Table

| Source | XGA Rating | Effort | Recommendation | Priority |
|---|---|---|---|---|
| **Amnesia** | ⭐⭐⭐⭐⭐ | 2–3 wks | START HERE | 🥇 |
| **B&K (Bounce)** | ⭐⭐⭐⭐ | 1–2 wks | Extract sprite ref | 🥈 |
| **Contrast** | ⭐⭐⭐ | 3–4 wks | Backup reference | 🥉 |
| **Hell** | ⭐⭐ | 4+ wks | Skip (needs data) | Skip |
| **Copper Faked** | ⭐ | N/A | Skip (VGA-only) | Skip |

---

## Immediate Next Steps

### You Now Have:
1. ✅ **Amnesia.asm** (already open in editor)
2. ✅ **Bytes & Kisses source** (multiple effect folders)
3. ✅ **Contrast** (large reference library)
4. ✅ **Study document** (HORNET-DEMO-PORTING-STUDY.md)

### To Proceed, Please Clarify:

1. **XGA Register Access:**
   - Do you have **XGA BIOS function documentation**? (int 10h extensions)
   - Or will you use **direct register I/O** (port-based)?
   - Either way, do you have example code from another XGA project?

2. **Amnesia Baseline:**
   - Does the current Amnesia.asm run on your 55SX?
   - What resolution/mode does it currently target?
   - Is 80387 code already in use, or fixed-point only?

3. **Test Hardware:**
   - Plan to test on **real PS/2 Model 55SX** with XGA?
   - Or prototype in **86Box first**, then migrate to real hardware?

4. **Graphics Library:**
   - Do you have an existing **XGA/VGA abstraction layer**?
   - Or will you build the XGA access layer from scratch as part of this project?

---

**END OF ASSESSMENT**
