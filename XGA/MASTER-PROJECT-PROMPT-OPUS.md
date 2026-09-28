# Master Project Prompt: Amnesia XGA Port for IBM PS/2 Model 55SX

> **Archived prompt:** This describes an earlier Amnesia-port proposal and is
> retained for project history, not as current instructions. The active DOS demo
> and verified status are documented in [xga-demo/README.md](xga-demo/README.md).

## PROJECT SCOPE & OWNERSHIP

**Project Manager & Technical Lead:** Claude Opus 4.7  
**User Role:** Testing, validation, and direction  
**Target Platform:** IBM PS/2 Model 55SX (386SX-16MHz + 80387)  
**Graphics Card:** IBM XGA Display Adapter/A  
**Target Mode:** 640×480×256 colors  
**Assembler:** NASM (recently confirmed working)

---

## KEY DISCOVERY RESULTS

### Amnesia.asm Status
- ✅ **Successfully compiled to COM** (fixed 43 initial comment lines)
- ✅ **Fixed-point integer math only** (no 80387 FP instructions detected)
- ✅ **Original mode:** VGA 320×200×256 (Mode 13h assumption)
- **Implication:** Port focuses on scaling geometry and coordinate systems, not leveraging 80387

### XGA Documentation Status
- ❌ **Power Programming IBM XGA book (1992)** not freely available online
- ⚠️ **Will require:** Building XGA knowledge from register references, 86Box source code, reverse engineering
- **Fallback strategy:** Start with simple XGA test program to validate register layout, then expand to full Amnesia port

---

## PROJECT PHASES

### PHASE 1: BASELINE & VALIDATION (Week 1)
**Goal:** Establish working baseline, confirm compilation pipeline, test Amnesia in emulator.

#### 1.1 Baseline Compilation
- [ ] Confirm Amnesia.asm compiles to COM with NASM
- [ ] Create `bin/` folder structure
- [ ] Generate `.lst` listing file for debugging
- [ ] Document build command in workspace task

#### 1.2 Emulator Testing (DOSBox)
- [ ] Run compiled Amnesia.COM in DOSBox
- [ ] Document what you see:
  - Does the demo run? (stars, temple geometry?)
  - What resolution appears on screen?
  - Estimate framerate (smooth, choppy, frozen?)
  - Any graphics artifacts or crashes?
- [ ] Screenshot or video capture if possible
- [ ] Save results in `XGA/amnesia-baseline-results.md`

#### 1.3 86Box Testing
- [ ] Set up 86Box with PS/2 Model 55SX config
- [ ] Run Amnesia.COM
- [ ] Compare to DOSBox results
- [ ] Note any differences in rendering or performance

**DELIVERABLE:** Baseline document showing current state of Amnesia on original resolution.

---

### PHASE 2: XGA INFRASTRUCTURE (Week 1–2)

**Goal:** Build minimal XGA test suite to validate hardware access, BIOS modes, and direct register programming.

#### 2.1 XGA Documentation Research
- [ ] Search for and consolidate available XGA info:
  - BIOS int 10h extensions for 640×480×256 mode set
  - Register addresses (base + offsets for BitBLT control)
  - VRAM layout and framebuffer addressing
  - BitBLT operation sequence (source, dest, pitch, width, height, blit operation)
- [ ] Document sources in `XGA/XGA-DOCUMENTATION.md`

#### 2.2 Minimal XGA Test Program (test-xga.asm)
**Purpose:** Single-screen 640×480×256 mode set + draw test pattern.

**Features:**
- [ ] Int 10h call to set 640×480×256 XGA mode
- [ ] Fill screen with test pattern (checkerboard or gradient)
- [ ] Display message: "XGA 640x480x256 OK - Press ESC"
- [ ] Restore VGA text mode on exit
- [ ] ~100–200 lines of NASM code (minimal dependencies)

**Build:** `nasm -f bin test-xga.asm -o test-xga.COM`

#### 2.3 Test Program Validation
- [ ] Test in 86Box (PS/2 Model 55SX with XGA)
  - Does mode set work?
  - Is framebuffer accessible?
  - Can you write pixels?
- [ ] If 86Box test passes → test on real hardware
  - Use actual PS/2 55SX + XGA card
  - Validate that test program runs identically
  - **CRITICAL:** Confirm VRAM addresses and register layout match real hardware

**DELIVERABLE:** Working test-xga.COM that proves XGA is programmable.

---

### PHASE 3: XGA BITBLIT TEST (Week 2)

**Goal:** Validate XGA blitter functionality before integrating into Amnesia.

#### 3.1 Extended Test Program (test-xga-blit.asm)
**Features:**
- [ ] Mode set to 640×480×256
- [ ] Set up off-screen buffer (address 0x4B000+)
- [ ] Load or generate simple test image (1024×480 or smaller)
- [ ] Issue XGA BitBLT command:
  - Source: off-screen buffer
  - Dest: framebuffer (0,0)
  - Size: 640×480
  - Operation: COPY
- [ ] Measure blit time (simple timer or instruction counter)
- [ ] Display: "Blit completed in X cycles - Press ESC"
- [ ] Compare blitter speed vs. CPU copy on same platform

#### 3.2 Blitter Validation
- [ ] Test in 86Box
  - Does blit execute without error?
  - Is result visible on screen?
  - Does off-screen buffer survive after blit?
- [ ] Test on real hardware (if 86Box passes)
  - Confirm blitter works identically
  - Measure actual timing on real 55SX CPU

**DELIVERABLE:** Working BitBLT test program + performance benchmark.

---

### PHASE 4: AMNESIA XGA PORT (Weeks 3–5)

**Goal:** Adapt Amnesia to 640×480×256 XGA mode with minimal source changes.

#### 4.1 Coordinate System Adaptation
**Key principle:** Keep original logic intact; only scale resolution-dependent values.

**Changes:**
- [ ] Update viewport constants (320→640 width, 200→480 height)
- [ ] Adjust perspective multiplier if needed (perspective = viewport_width / 2)
- [ ] Scale all screen-coordinate comparisons to new boundaries
- [ ] Preserve rotation tables, vector data, projection math

**Files to modify:**
- Viewport setup section
- Coordinate boundary checks
- Scanline rendering loop (if applicable)

#### 4.2 XGA Graphics Mode Integration
- [ ] Replace VGA mode set with XGA mode set (Int 10h call)
- [ ] Replace CPU-driven pixel writing with XGA pattern fill + BitBLT where applicable:
  - Polygon interior fill → XGA pattern fill (solid color)
  - Framebuffer clear → XGA fill rectangle operation
  - Sprite/object rendering → BitBLT if applicable
- [ ] Preserve original clipping and edge buffer logic (no major refactoring)

#### 4.3 Incremental Compilation & Validation
- [ ] Compile after each major change
- [ ] Test in 86Box after each phase:
  - Does mode set work?
  - Do objects appear on screen?
  - Any corruption or missing geometry?
- [ ] Compare 320×200 and 640×480 outputs side-by-side (visual parity)

**Milestones:**
- [ ] **M1:** XGA mode set + blank screen (no geometry)
- [ ] **M2:** Geometry renders (stars/temple visible, even if incomplete)
- [ ] **M3:** Full geometry + proper clipping
- [ ] **M4:** XGA acceleration enabled (blitter tests integrated)

---

### PHASE 5: BENCHMARKING & REAL HARDWARE (Weeks 5–6)

**Goal:** Measure performance gains and validate on actual 55SX hardware.

#### 5.1 VGA vs. XGA Comparison
**Setup:**
- Maintain separate code paths for VGA 320×200 and XGA 640×480
- Use compile-time flag (or runtime switch) to enable each path
- Build VGA version with original Amnesia code
- Build XGA version with ported code

**Benchmark:**
- [ ] Run both versions in 86Box
- [ ] Run both versions on real PS/2 Model 55SX
- [ ] Measure and document:
  - Frames per second (FPS)
  - Triangle/object count per frame
  - CPU cycles per frame (if measurable)
  - Visual quality (geometry completeness, clipping accuracy)

#### 5.2 Real Hardware Validation
- [ ] Test XGA version on actual PS/2 Model 55SX + XGA card
- [ ] Confirm visual output matches 86Box version
- [ ] Measure performance on real hardware
- [ ] Document any hardware-specific quirks or issues

#### 5.3 Documentation & Release
- [ ] Create final report:
  - Porting strategy & changes made
  - Performance benchmark results
  - Lessons learned
  - Instructions for rebuilding/modifying

**DELIVERABLE:** Dual-path demo (VGA 320×200 vs. XGA 640×480) with detailed benchmark results.

---

## TECHNICAL NOTES

### Fixed-Point Math in Amnesia
- No 80387 FP instructions detected
- All math is integer-based (sin/cos tables pre-computed)
- Porting does NOT require any FP code changes
- 80387 presence is beneficial for future features, not required for this port

### XGA Mode & VRAM Layout
**Mode 640×480×256:**
- One plane, 8-bit pixels per address
- Scanline pitch: 640 bytes
- Framebuffer size: 640 × 480 = 307,200 bytes
- Framebuffer address: 0x00000 (linear addressing at 0xA0000 + offset in card VRAM)
- Off-screen buffer: 0x4B000+ (remaining ~716 KB for textures, backbuffers, etc.)

**BitBLT Register Model (TO BE VALIDATED):**
- Source address, destination address, source pitch, dest pitch, width, height, operation code
- Exact register addresses TBD during Phase 2 research

### Build Command
```bash
nasm -f bin -i XGA/Demoes\ vith\ source\ code/Amnesia/ Amnesia.asm -o bin/Amnesia.COM -l bin/Amnesia.lst
```

### Test Environment
- **Primary:** 86Box with PS/2 Model 55SX config (XGA enabled)
- **Validation:** Real PS/2 Model 55SX + XGA card (if available and Phase 2 testing succeeds)

---

## TESTING GATES & USER CHECKPOINTS

### Before proceeding from Phase 1 → Phase 2:
- [ ] Amnesia.COM compiles without errors
- [ ] Baseline runs in DOSBox (report what you see)
- [ ] Baseline runs in 86Box (report framerate & visuals)
- **USER DECISION POINT:** Proceed to XGA work?

### Before proceeding from Phase 2 → Phase 3:
- [ ] test-xga.COM sets 640×480×256 mode successfully
- [ ] Test pattern is visible and readable on real hardware
- **USER DECISION POINT:** Proceed to blitter testing?

### Before proceeding from Phase 3 → Phase 4:
- [ ] test-xga-blit.COM successfully executes BitBLT
- [ ] Blitter output matches CPU copy results
- [ ] Performance is measurable and positive
- **USER DECISION POINT:** Proceed to full Amnesia port?

### Before proceeding from Phase 4 → Phase 5:
- [ ] Amnesia XGA version compiles
- [ ] Geometry appears on screen in 640×480 mode
- [ ] Visual output is consistent with baseline (geometry parity)
- **USER DECISION POINT:** Proceed to real hardware testing?

---

## USER TESTING RESPONSIBILITIES

At each testing gate, you will:

1. **Compile** the code (Opus provides NASM build commands)
2. **Run** in 86Box or on real hardware as specified
3. **Report:**
   - Does the program run? (Yes/No/Crash)
   - What do you see on screen?
   - Any visual artifacts, corruption, or unexpected behavior?
   - Estimate framerate (smooth 30+, moderate 15–30, slow <15)
   - Any error messages or console output?
4. **Provide:** Screenshots, video capture, or detailed descriptions
5. **Decide:** Proceed to next phase, or troubleshoot?

---

## SUCCESS CRITERIA

**Phase 1:** Amnesia baseline working in both DOSBox and 86Box  
**Phase 2:** XGA test program validates mode set + register access  
**Phase 3:** BitBLT test confirms blitter functionality  
**Phase 4:** Amnesia runs in 640×480×256 mode with geometry visible  
**Phase 5:** Performance benchmark shows measurable improvement, code ready for release

---

## COMMUNICATION PROTOCOL

- **Opus** provides: Detailed technical guidance, code changes, build instructions, testing expectations
- **User** provides: Execution, testing results, decisions at checkpoints, real hardware validation
- **Feedback loop:** User reports result → Opus adapts strategy or requests clarification → User tests next step

---

**READY TO BEGIN PHASE 1: BASELINE & VALIDATION**

---

## APPENDIX: Key Files & Locations

```
Workspace Root: C:\Users\hages\OneDrive\VS Code\Olivetto Prodest PC1\

Amnesia Source:
  XGA/Demoes vith source code/Amnesia/Amnesia.asm (MODIFIED - first 43 lines now commented)
  XGA/Demoes vith source code/Amnesia/bin/ (output destination)

Test Programs (to be created):
  XGA/test-xga.asm (Phase 2)
  XGA/test-xga-blit.asm (Phase 3)

Documentation:
  XGA/HORNET-DEMO-PORTING-STUDY.md (overview & strategy)
  XGA/DOWNLOADED-DEMO-SOURCES-ANALYSIS.md (demo survey)
  XGA/XGA-DOCUMENTATION.md (research findings - Phase 2)
  XGA/amnesia-baseline-results.md (test results - Phase 1)
  XGA/amnesia-xga-port-log.md (porting progress - Phase 4)
```

---

**END OF MASTER PROJECT PROMPT**

---

## PHASE 1 IMMEDIATE TASKS

**User:**
1. Compile Amnesia.asm (Opus will provide exact command)
2. Run in DOSBox, observe and report
3. Run in 86Box, observe and report
4. Provide detailed description of what you see

**Opus:**
1. Generate Phase 1 build tasks
2. Create baseline testing protocol
3. Prepare Phase 2 deliverables based on Phase 1 results
