# XGA Panorama Flight

## Current working disk

Use `bin/dreams_xga_20260926_200009.img` as the known working demo. Its
`BUILD.TXT` records 2026-09-26 20:00:09 and `DBLIT.COM` in `AUTOEXEC.BAT`.
The VM configuration currently points to this image. Later timestamped images
and the current assembly source contain motion experiments that did not work
as intended in 86Box; building the source does not reproduce this disk.

DOS COM demo for the IBM PS/2 Model 55SX with MCA XGA-1. The 640×480×256
display is map A; an 800×800 indexed image is loaded once into off-screen
VRAM as map B. `PANORAMA.COM` does one initial source-copy BitBLT and then
pans the XGA scanout start address within the source image. This avoids a
307,200-pixel copy on every frame in 86Box. A small `FPS:nn` overlay counts
completed panorama updates per real-time clock second; it does not measure
host-window presentation. `PANBLT.COM` preserves the
original full-frame BitBLT animation for comparison. ESC restores text mode.

The layout uses 307,200 bytes for the screen and 640,000 bytes for the source:
947,200 of the card's 1,048,576 bytes. A 1 MB or 4 MB aperture must be
configured in MCA POS. The CPU uses the 64 KB A000 bank window only to load
the source image. The coprocessor maps use the 4 MB aperture address decoded
from POS, which is required by 86Box's XGA implementation.

## Build

From this directory:

```powershell
python build_mode_table.py
nasm -f bin -DTEST_MODE=1 xga_panorama.asm -o bin/test_xga_mode.COM -l bin/test_xga_mode.lst
nasm -f bin -DTEST_MODE=2 xga_panorama.asm -o bin/test_xga_blit.COM -l bin/test_xga_blit.lst
nasm -f bin -DPAN_STYLE=0 xga_panorama.asm -o bin/xga_panblt.COM -l bin/xga_panblt.lst
nasm -f bin xga_panorama.asm -o bin/xga_panorama.COM -l bin/xga_panorama.lst
python make_test_floppy.py --program PANORAMA --output xga_dos622_fps.img
```

The first binary draws a CPU-written gradient in XGA mode. The second copies
a 128×128 source rectangle to the display via BitBLT. The final binary shows
the moving panorama. Run `TESTMODE`, `TESTBLT`, `PANBLT`, or `PANORAMA` from
DOS; all accept ESC. The copied DOS floppy boots straight into `PANORAMA`.
Use `--program` with a distinct `--output` image to boot directly into a
diagnostic or the original full-frame BitBLT version.

`bin/vm/86box.cfg` is a copy of the existing 55SX/XGA-1 configuration with
the test floppy attached. The emulator ROMs remain in the existing 86Box
installation. Start it with:

```powershell
& 'D:\86Box-Windows-64-b8200\86Box.exe' -P '<absolute path to bin\vm>'
```

The demo creates `XGABOOT.TXT`, `XGADET.TXT`, `XGAMODE.TXT`, and finally
`XGAOK.TXT` on the test floppy as it reaches each stage. Error files begin
with `NO`. `XGAOK.TXT` proves that the first BitBLT command returned; it
does not prove the pixels are visually correct.

The CPU gradient was visually confirmed, then the 128×128 BitBLT test
produced a colored square after correcting the coprocessor map base.
The full-frame BitBLT panorama worked and returned to DOS with ESC, but the
user observed roughly one update per second and visible blinking in 86Box.
The scanout variant targets that performance issue; its visual result must
also be checked in the emulator.

Register values come from `XGA Toolkit/XGAKIT.ASM`, `MINI/XGA.INC`,
`xgadll/xgaregs.h`, `xgadll/xga.h`, and the 86Box XGA implementation.

## Dreams image and speed comparison

`prepare_dreams.py` uses the user's ImageMagick installation to convert the
1536×1024 `assets/Dreams.bmp` to
960×640 indexed color. `DREAMS.DAT` begins with 768 RGB palette bytes and
then contains 614,400 pixel indices. The preview is
`assets/Dreams-XGA-preview.png`. `make_dreams_floppy.py` creates a minimal,
bootable 1.44 MB DOS 6.22 disk from a copy of `Dos622-1.img` and includes the
data file plus three programs. The source DOS image is untouched.

```powershell
python prepare_dreams.py
nasm -f bin xga_dreams.asm -o bin/DREAMS.COM
nasm -f bin -DPAN_STYLE=0 xga_dreams.asm -o bin/DBLIT.COM
nasm -f bin -DPAN_STYLE=2 xga_dreams.asm -o bin/DCPU.COM
python make_dreams_floppy.py --program DREAMS
```

At 8 bits per pixel, the 640×480 display occupies 307,200 bytes. The full
960×640 image occupies another 614,400 bytes in off-screen VRAM. Together
they use 921,600 of 1,048,576 bytes and leave 126,976 bytes. The image is
loaded once from A: to VRAM. Animation reads it from VRAM thereafter.

| Program | Per-frame method | Purpose |
| --- | --- | --- |
| `DREAMS` | Change XGA scanout start address | Fast reference; no per-frame copy |
| `DBLIT` | XGA VRAM-to-VRAM BitBLT of 640×480 | Accelerated copy throughput |
| `DCPU` | CPU copies 640×480 via banked A000 and a 640-byte RAM row | Same copy without the blitter |

All three versions now draw the FPS text through XGA's 64×64 hardware sprite
at the top left. The sprite overlays the display independently of VRAM
scanout and is updated only when the measured value changes. The sprite
routines reproduce the working `dreams_xga_20260926_193007.img` version;
the programs now use a new sine motion path. `DBLIT` and `DCPU` copy the full
640×480 region, so their frame rates measure the same area. The counter divides completed frames
by the actual elapsed BIOS clock ticks (normally 36 ticks), including frames
that take several seconds. The previous counter stopped at 99.9 and
underreported very slow frames. This is guest animation throughput rather
than host-window presentation. The 18 Hz fallback in `DREAMS` has been
removed; all three versions now run without a frame-rate cap. The monitor can
still display only its own refresh rate. Press ESC to return to DOS,
then type another program name to compare on the same booted machine.

`DBLIT` starts without a vertical-retrace wait. Press `S` to turn the wait
on or off while it runs. An `S` with a small gap after the FPS number marks the
enabled state. The code polls Input Status Register 1, bit 3, for a new
vertical retrace before starting each full-frame BitBLT. This changes frame
pacing; it does not disable the monitor's physical sync signal. A single
buffer can still tear if a BitBLT continues beyond the retrace interval.
Without `S`, each iteration submits a new BitBLT immediately after the
previous one completes. The loop reads the BIOS clock directly from its data
area, redraws the hardware-sprite counter only on a new measurement, and
checks the keyboard every eight fast iterations to reduce benchmark overhead.
The first `DBLIT` and `DREAMS` FPS readings use nine BIOS ticks; subsequent
readings use 36 ticks. `DBLIT` displays whole completed copies per second through the same
hardware sprite, with a four-digit ceiling of 9999. `DREAMS` and `DCPU`
retain tenths and a 999.9 ceiling.

Image motion follows the 256-entry sine table from `demo5a.asm`, with a
quarter-cycle Y offset and twice the Y phase rate. Uncapped `DREAMS` and
`DBLIT` advance the path according to completed frame counts. Every FPS
measurement recalculates the number of frames per sine step, targeting about
60 motion steps per second without waiting for retrace. With `S` enabled,
`DBLIT` advances once after each retrace wait. At 60 steps per second, X takes
about 4.3 seconds per cycle and Y about 2.1 seconds. `DCPU` uses elapsed BIOS
ticks. The crop oscillates around the center of the 960×640 source image.

The FPS counters measure completed guest loops per guest BIOS time, including
the full-frame BitBLT command for `DBLIT`; they do not count unique frames
presented by the host window. 86Box's XGA implementation executes the BitBLT
inside the command-register write handler, so the result should not be read as
a measured throughput of physical XGA-1 hardware.

The palette and a CRC-based image identity are embedded in each COM. Before
opening `DREAMS.DAT`, the program checks a marker in unused VRAM and three
pixels spread across the source. A matching cache skips the floppy load. On
a miss, a visible progress bar advances for each of the 150 transferred 4 KB
pages, then the marker is written. The loader reads up to 32 KB per DOS call
(19 calls for this image) and copies into VRAM as 16-bit words. Mode changes
or reboot can invalidate
VRAM, so the cache is opportunistic. The loading indicator is inspired by
the disk activity display in `PC1-BMP.asm` but uses XGA pixels.

The floppy builder stamps every inserted file with the local build date and
time in its FAT directory entry, so `DIR` shows when the COM and DAT files
were packaged. `BUILD.TXT` records the build time and the AUTOEXEC choice.
Use a distinct timestamped `.img` filename for each new emulator test.

Build a disk with `--program DBLIT` to start directly in the hardware
blitter benchmark. With no `--output` argument the filename includes the
same local timestamp as `BUILD.TXT`. `DREAMS.COM` is the
scanout version, not an older copy of the same algorithm.

The original 1536×1024 image would take 1,572,864 bytes as 8-bit pixels,
which is larger than the 1 MB XGA VRAM. An indexed prototype at
`assets/Dreams-full-256.png` is 713,124 bytes; its pixel stream compresses
to 703,300 bytes with zlib. A future RAM-source
variant could load/decompress it into extended memory and let XGA busmaster
from system RAM to the visible VRAM framebuffer. That path requires extended
memory allocation and a separate hardware/emulator test; it is not used by
the three current programs.

An earlier line-compare build put the FPS text on a black strip at the bottom.
That was not the method in the user's verified 19:30:07 disk image. The
verified version programs the XGA hardware sprite and streams the 64×10 FPS
bitmap into its sprite buffer; the rest of the 64×64 sprite is transparent.
