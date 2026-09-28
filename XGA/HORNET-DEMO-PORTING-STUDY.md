# XGA Porting Study: Hornet.org Demo Analysis
## For IBM PS/2 Model 55SX (386SX-16 @ 16MHz) with XGA Display Adapter/A

**Author:** GitHub Copilot  
**Date:** May 12, 2026  
**Target Platform:** 640×480×256 XGA mode with BitBLT acceleration  
**Hardware:** IBM PS/2 Model 55SX (386SX-16MHz), IBM XGA-1 Display Adapter  

> **Status:** Historical planning document, not an active porting plan. The
> projected FPS and speedups below are estimates, not measurements. The current
> DOS demo and its test status are documented in [xga-demo/README.md](xga-demo/README.md).

---

## Executive Summary

From the Hornet.org demo collection, **scroll and blitting-heavy effects are ideal XGA targets**, while **pure calculation-heavy effects (plasma, mandelbrot, fire) gain minimal benefit**. The most impressive gain comes from **tile/sprite scrolling engines** and **panorama panning**, which can achieve **2–4× framerate improvement** through XGA BitBLT offloading.

---

## 1. XGA Capability Constraints (640×480×256)

### What XGA Accelerates Well
- **Rectangle copy (BitBLT)** with independent source/dest pitch
- **Pattern fills** (solid color, patterns)
- **Line drawing** (if using hardware line engine)
- **Hardware cursor** (not relevant to demos)

### What XGA Does NOT Accelerate
- **Per-pixel calculation** (plasma, fire, mandelbrot, perlin noise)
- **VGA 320×200×256 Mode 13h** (acceleration disabled at that resolution)
- **Complex raster effects** that require precise per-frame control
- **Polygon fill** (no native polygon accelerator in XGA-1)

### CPU Context: 386SX-16MHz with 80387 Math Coprocessor
- **Base CPU:** 386SX-16 (pipelined 32-bit @ 16MHz)
- **Math coprocessor:** 80387 (concurrent FP execution)
- Per-frame budget at 30 FPS: ~16,666 CPU cycles available
- At 60 FPS: ~8,333 cycles
- **80387 advantage:** FP trigonometry, matrix transforms, and perspective division can run *in parallel* with CPU, effectively "free" vs. fixed-point emulation
- Copying 307,200 bytes (640×480×256) by hand takes ~3M cycles → **impossible at 30FPS**, **obvious bottleneck**

**Impact on vector/3D effects:**
- Amnesia-style vector rotation is **NOT bottlenecked by FP math anymore**
- 3D demos can now spend more cycles on geometry without the penalty of fixed-point emulation
- Expected speedup for vector effects: **1.5–2×** with XGA (vs. 1.2–1.5× on 386SX without 387)

---

## 2. Hornet.org Demos: Suitability Analysis

### TIER 1: EXCELLENT XGA TARGETS
These demos will see **2–4× improvement** with XGA acceleration.

#### 🎯 "Panorama Scroll" Style (Based on scrolling backdrop principles)
- **Source:** Bytes & Kisses, Contrast, Inconexia all contain scrolling sections
- **Why it works:** Large off-screen buffer + repeated 640×480 BitBLT copies per frame
- **XGA benefit:** One hardware blit per frame vs. CPU writing 307KB manually
- **Expected FPS:**
  - **VGA path:** ~8–12 FPS (CPU bottleneck on 386SX-16)
  - **XGA path:** ~30–45 FPS (BitBLT hardware handles the pixel movement)
  - **Improvement factor:** ~3–4×

#### 🎯 "Tile Scroller" / "Scrolling Playfield" (Based on tilemap principles)
- **Source:** Inconexia effects, Fake Demo terrain layers
- **Why it works:** Tile-based background + sprite overlay + incremental redraws
- **XGA benefit:** BitBLT for column/row shifts; pattern fill for tiles
- **Expected FPS:**
  - **VGA path:** ~15–20 FPS
  - **XGA path:** ~40–60 FPS
  - **Improvement factor:** ~2–3×

#### 🎯 "Masked Sprite Animation" (Based on blitting principles)
- **Source:** Amiga Boing Ball (already in your workspace), animation sequences from multi-effect demos
- **Why it works:** Small sprite regions copied to new positions each frame
- **XGA benefit:** Masked BitBLT is exactly what XGA is designed for
- **Expected FPS:**
  - **VGA path:** ~20–30 FPS (depends on sprite size/count)
  - **XGA path:** ~50–80 FPS
  - **Improvement factor:** ~2–3×

---

### TIER 2: MODERATE XGA TARGETS
These could benefit **1.5–2× improvement** if heavily rewritten for 640×480.

#### ⚡ "Tunnel Effect with Scrolling Texture" (Based on One Night Stand principle)
- **Source:** One Night Stand, Fake Demo tunnel section
- **Description:** 2D tunnel or 3D perspective-mapped passageway
- **Why it could work:** If the tunnel uses a precomputed texture that scrolls (blits across screen)
- **Caveat:** Most "tunnel" demos are pure per-pixel math; only accelerate if texture-blitting is the hot path
- **XGA benefit:** BitBLT for repeating texture columns
- **Expected FPS:**
  - **VGA path:** ~20–30 FPS
  - **XGA path:** ~35–50 FPS (modest improvement; CPU still does math)
  - **Improvement factor:** ~1.5–2×

#### 🎯 "Solid Polygon Rendering" (Based on wireframe/rasterization)
- **Source:** Amnesia vector, Inconexia geometric sections, Hello VGA in your own ASM-386-VGA folder
- **Description:** Draw wireframe or flat-shaded polygons to 640×480
- **Why it could work:** 3D rotation math is accelerated by 80387 coprocessor; polygon fills accelerated by XGA pattern fill
- **With 80387:** 3D transform math is no longer the dominant bottleneck; fill speed matters more
- **XGA benefit:** Hardware pattern fill + reduced CPU math overhead → more polygons per frame
- **Expected FPS (with 80387 + XGA):**
  - **VGA path:** ~18–25 FPS (387 still helps but fill is slow)
  - **XGA path:** ~25–35 FPS (fill acceleration is now visible)
  - **Improvement factor:** ~1.5–2× (better than without 387)

---

### TIER 3: MINIMAL OR NO XGA BENEFIT
These are **poor porting targets**.

#### ❌ "Plasma Effect" / "Per-Pixel Simulation"
- **Source:** Bytes & Kisses plasma, Byte B4 Christmas fire, Inconexia per-pixel FX
- **Why it fails:** Each pixel is computed independently; blitting doesn't help
- **CPU cost:** Calculation, not pixel movement
- **XGA benefit:** **None** — acceleration is not applicable
- **Expected FPS:** **No improvement** (same VGA or worse due to 640×480×256 overhead)

#### ❌ "Mandelbrot Zoom" / "Fractal Renderer"
- **Source:** Fake Demo mandelbrot section
- **Why it fails:** Per-pixel calculation, no blitting
- **XGA benefit:** **None**
- **Expected FPS:** **No improvement**

#### ❌ "Metaballs" / "Raytracing" (Mayhem)
- **Why it fails:** Per-pixel rendering or complex 3D math
- **XGA benefit:** **None** (unless post-processing uses blits, unlikely)
- **Expected FPS:** **No improvement**

#### ❌ "Text Scrolling" / "Sine-Wave Effects" on VGA 320×200×256
- **Source:** Asciiart demo, waveform effects in VGA mode
- **Why it fails:** XGA does not accelerate 320×200×256 (standard VGA)
- **Mitigation:** Would need to be ported to 640×480×256, which negates the point
- **XGA benefit:** **None** at the original resolution
- **Expected FPS:** **No improvement**

---

## 3. Recommended Porting Candidates (Ranked by Feasibility + Impact)

### Rank 1: "Custom Panorama Scroll Engine" ⭐⭐⭐⭐⭐
**Best overall choice for showcasing XGA.**

- **Source complexity:** Low (bitmap blitting is straightforward)
- **Assembly effort:** Medium (XGA BIOS or register I/O; you likely have examples)
- **Visual impact:** High (fast, smooth scrolling is immediately impressive)
- **Performance gain:** 3–4× improvement (obvious to any observer)
- **Recommendation:** **START HERE**

**Implementation outline:**
1. Load or generate a 1024×480 pixel art panorama at startup
2. Initialize XGA 640×480×256 mode
3. Copy panorama into off-screen VRAM (address 0x4B000+)
4. Each frame:
   - Adjust scroll_x, scroll_y based on user input or simple physics
   - Issue one XGA BitBLT: source=(scroll_x, scroll_y), dest=(0,0), size=640×480
5. Wrap around infinite scrolling with seam blitting

**Demo ideas:**
- Parallax scrolling (multiple layers, each with different scroll speed; use multiple BitBLTs)
- Smooth camera panning with easing
- Scrolling credits or narrative scene

---

### Rank 2: "Tile-Based Scrolling Playfield" ⭐⭐⭐⭐
**Strong candidate; familiar to classic arcade porting.**

- **Source complexity:** Medium (tile lookup, column/row shifts)
- **Assembly effort:** Medium-to-High
- **Visual impact:** High (game-like responsiveness)
- **Performance gain:** 2–3×
- **Recommendation:** **GOOD SECOND PROJECT**

**Implementation outline:**
1. Create a 32×30 tilemap (16-pixel tiles for simplicity) = 640×480
2. Store tile graphics in off-screen VRAM
3. Each frame:
   - Detect which columns/rows have scrolled onto/off screen
   - Use BitBLT to copy only newly exposed tile columns/rows
   - Update tilemap indices CPU-side
4. Optionally overlay sprites for entities

**Demo ideas:**
- Top-down adventure-game playfield
- Side-scrolling platformer backdrop
- Animated tile effects (water, lava, etc.)

---

### Rank 3: "Masked Sprite Animation Demo" ⭐⭐⭐⭐
**Proven concept; builds on existing code (Boing Ball).**

- **Source complexity:** Medium (masked copy logic, transparency)
- **Assembly effort:** Medium
- **Visual impact:** Medium (depends on sprite content)
- **Performance gain:** 2–3×
- **Recommendation:** **GOOD FOR BENCHMARKING**

**Use:** Boing Ball / animation sequences with 1–10 simultaneous sprites bouncing/moving on a simple background.

---

### Rank 4: "Amnesia Vector Engine (640×480 Version)" ⭐⭐⭐
**Upgraded priority with 80387 coprocessor; FP math is no longer dominant bottleneck.**

- **Source complexity:** High (3D math, sorting, clipping)
- **Assembly effort:** High (full port to 640×480, edge buffer adaptation)
- **Visual impact:** Impressive; showcases 3D on XGA
- **Performance gain:** 1.5–2× (vs. VGA; was 1.2–1.5× without 387)
- **80387 advantage:** FP trigonometry and matrix transforms run in parallel; enables more geometry per frame
- **Recommendation:** **COMPETITIVE WITH RANK 2; GOOD TECH DEMO**

**Why upgraded from Rank 4:**
- With 80387, the 3D math is no longer the sole bottleneck
- XGA polygon fill acceleration becomes more visible
- Expected ~25–35 FPS (vs. ~18–25 FPS on VGA with 387)
- A beautiful demonstration of coprocessor + accelerator synergy

**If you proceed:**
- Keep the original Amnesia vector data and rotation logic (387 handles the FP math efficiently)
- Recompile to 640×480 output resolution
- Use XGA pattern fill for interior polygon rendering
- Expect ~25–35 FPS (vs. ~18–25 on VGA with 387; better framerate and 640×480 resolution improvement)
- Compare framerate against original VGA version on same 55SX hardware

---

## 4. Expected Framerate Characteristics

### Baseline (VGA, 320×200×256, typical demoscene code)

| Effect Type | VGA (Stock) | VGA (55SX) | Notes |
|---|---|---|---|
| Simple 320×200 scroll | ~30–40 FPS | ~25–30 FPS | CPU-limited on 386SX-16 |
| Plasma (per-pixel) | ~10–15 FPS | ~8–12 FPS | Highly CPU-intensive |
| Sprite animation (5–10) | ~20–30 FPS | ~15–25 FPS | CPU math + blit |
| Vector wireframe | ~10–20 FPS | ~8–15 FPS | 3D math dominates |

### With XGA Acceleration (640×480×256)

| Effect Type | XGA Path | Improvement | Notes |
|---|---|---|---|
| **Panorama scroll** | **30–45 FPS** | **+3–4×** | BitBLT is the win |
| **Tile scroll (with updates)** | **40–60 FPS** | **+2–3×** | Depends on redraw area |
| **Masked sprites** | **50–80 FPS** | **+2–3×** | Many small blits |
| **Vector fill (with 80387)** | **25–35 FPS** | **+1.5–2×** | 80387 enables parallel FP; XGA fill is faster |
| **Plasma (per-pixel)** | **~8–12 FPS** | **None** | Not applicable |
| **Fire / per-pixel sim** | **~6–10 FPS** | **None** | Not applicable |

---

## 5. XGA Functions Required in Ported Demos

### For Panorama Scroll
```
- Int 10h AX=0x4F02: Set 640×480×256 XGA mode
- Direct register I/O (or BIOS function if available):
  - BitBLT source address
  - BitBLT destination address
  - BitBLT source pitch (1024 pixels → 1024 bytes in 256-color)
  - BitBLT dest pitch (640 bytes)
  - BitBLT width/height
  - BitBLT command (copy)
  - Poll status register for completion
```

### For Tile Scroll
```
- Mode set (as above)
- BitBLT (as above) for column/row updates
- Pattern fill (if tiles use repeating patterns)
```

### For Masked Sprite Blit
```
- Mode set
- BitBLT with transparency mask (if hardware supports it)
  OR CPU-side masked copy with per-sprite visibility checks
```

### For Vector Polygon Fill
```
- Mode set
- Edge buffer setup (existing Amnesia code)
- Possibly pattern fill for interior rasterization
  OR CPU-driven scanline fill at 640×480 resolution
```

---

## 6. Demo-Specific Notes

### "Bytes & Kisses" Source
- Contains scrolling, plasma, shadebobs
- **Good for extracting:** Scrolling framework
- **Skip:** Plasma (not XGA-friendly)
- **Use:** As a foundation for panorama scroll variant

### "Contrast" (TFL-TDV)
- Multi-coder demo; documented effects
- May include tilemap or window-based sections
- Worth reading for UI / blitting patterns

### "Fake Demo" (Pelusa)
- Sinus waver, wormhole, rotating landscape, fire, scrollie, shadebobs, lens, mandelbrot
- **Excellent source material** for multiple effect types
- **Extract:** Scrolling landscape, waveform effects
- **Study:** Mandelbrot for baseline (no XGA improvement, for comparison)

### "Inconexia" (Iguana)
- Collection of effects; good reference library
- Multiple scrolling and blitting patterns

### "Lasse Reinbong" (Party '95 winner)
- High-quality code
- May have advanced blitting or sprite techniques

### "One Night Stand" (Quantum Porcupine)
- Tunnel effects (mostly math, check if texture-blitting is involved)
- Source is relatively simple assembly

---

## 7. Recommendations & Next Steps

### Immediate Actions

1. **Confirm XGA BIOS / Register Documentation**
   - Do you have IBM XGA-1 BIOS interrupt documentation?
   - Or are you planning to use direct register access (port I/O)?
   - This determines your acceleration library structure.

2. **Secure Panorama Scroll Source Art**
   - Create or extract a 1024×480 or 1024×600 pixel-art image
   - (e.g., landscape, space background, abstract pattern)
   - Must fit in off-screen VRAM (>307KB available after framebuffer)

3. **Set Up XGA Mode Switch Code**
   - Test XGA 640×480×256 mode initialization on actual hardware
   - Verify VRAM accessibility and BitBLT register layout

### Short-Term Goals (Next 2–4 weeks)

1. **Implement "Panorama Scroll Engine"** (Rank 1)
   - Proof of concept: Simple panorama, linear scroll
   - Benchmark: VGA path vs. XGA path on 55SX
   - Document framerate results

2. **Extend to Parallax Scrolling** (if Rank 1 succeeds)
   - Multiple layers at different scroll speeds
   - Stress-test the blitter

### Medium-Term Goals (Month 2+)

1. **"Tile Scroll Engine"** (Rank 2) OR **"Amnesia Vector Port"** (Rank 4, now upgraded)
   - Both are competitive; choose based on preference (tile scroll = more polished game feel; Amnesia = tech showcase)
2. **"Sprite Animation Demo"** (Rank 3) — Use Boing Ball as reference
3. **Optional:** The alternative from Medium-Term #1 (if time permits)

---

## 8. Anticipated Challenges

### Hardware Emulation
- **86Box** has XGA support; **DOSBox** does not
- Testing will likely require **real PS/2 Model 55SX hardware** with XGA card
- Consider acquiring or setting up an actual test rig if you don't have one already

### VGA vs. XGA Mode Switching
- Ensure your code correctly handles the video mode switch
- Verify palette and VRAM addressing are correct post-switch
- Return to VGA cleanly on exit (restore original mode)

### Off-Screen VRAM Layout
- Carefully document where framebuffer ends and off-screen storage begins
- At 640×480×256, visible = 307,200 bytes; remaining ~716KB is available
- Ensure tiles/sprites/panorama data don't collide with framebuffer

### Masked Blitting (If Needed)
- XGA BitBLT may not have hardware transparency
- May need to use CPU-side masking or multi-blit techniques

---

## 9. Reference Material Checklist

- [ ] IBM XGA-1 register reference (BitBLT registers, status polling)
- [ ] BIOS interrupt documentation for XGA mode set
- [ ] Your workspace files: `XGA-ACCELERATION-TARGETS-AND-DEMO-IDEAS.md`
- [ ] Hornet.org source files (Bytes & Kisses, Fake Demo, Inconexia, One Night Stand)
- [ ] Existing Amnesia.asm (for vector/transform patterns, if porting later)
- [ ] Boing Ball demo (for masked sprite reference)

---

## 10. Conclusion

**Best starting point:** **Panorama Scroll Engine** (Tier 1)
- Lowest complexity
- Highest XGA benefit (3–4× speedup)
- Fastest time-to-result
- Excellent demonstration of XGA capability

**Most impressive tech demo:** **Amnesia Vector Engine (with 80387 + XGA)**
- Medium-high complexity
- Strong XGA benefit (1.5–2× speedup; improved with 387)
- Showcases coprocessor + accelerator synergy
- Real 3D on 640×480×256 is visually striking

**Recommended sequence:**
1. Panorama Scroll (quick win, establish XGA baseline)
2. *Either* Tile Scroll *or* Amnesia Vector (parallel effort or sequential based on interest)
3. Sprite Animation Demo (or remaining effect from #2)
4. Parallax Panorama or advanced effects (optional polish)

---

**Questions or clarifications needed?** See section 11 below.

---

## 11. Outstanding Questions for User

Before proceeding with detailed port planning, please clarify:

1. **XGA Development Tools**
   - Do you have XGA BIOS int 10h documentation? Or register specs?
   - Do you have example XGA mode-set or BitBLT code already?
   - Will you target BIOS functions or direct register I/O?

2. **Demo Source Availability**
   - Which Hornet.org demo sources have you already downloaded?
   - Do you have access to any of: Bytes & Kisses, Fake Demo, Inconexia, One Night Stand, Lasse Reinbong source?

3. **Test Hardware**
   - Do you have a real PS/2 55SX with XGA card for testing?
   - Or will you be testing in 86Box?
   - Either way, what OS/config are you using for assembly and testing?

4. **Priority**
   - Do you prefer a quick "proof of concept" first, or the most impressive final result?
   - Is benchmarking (VGA vs. XGA comparison) a key deliverable?

5. **Porting Depth**
   - Would you consider rewriting demo effects in NASM for XGA, or adapting existing source code?
   - Are there specific effects from the Hornet collection you find most interesting?

---

**END OF STUDY**
