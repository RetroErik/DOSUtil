"""Extract the original CGA artwork, scroller and speaker score for XGADEMO."""
from pathlib import Path
import re
import subprocess


here = Path(__file__).resolve().parent
source = here.parents[2] / "CGADEMO" / "CGADEMO5-NASM.asm"
output = here / "bin" / "v2"
output.mkdir(parents=True, exist_ok=True)
binary = output / "CGADEMO5.COM"
listing = output / "CGADEMO5.lst"
subprocess.run(["nasm", "-f", "bin", str(source), "-o", str(binary),
                "-l", str(listing)], check=True)

offsets = {}
for line in listing.read_text(encoding="ascii", errors="replace").splitlines():
    match = re.match(r"\s*\d+\s+([0-9A-F]{8})\s+.*?\b(logo|byte_109|byte_110|byte_117|byte_11D|byte_124|scrollText|music):", line)
    if match:
        offsets[match.group(2)] = int(match.group(1), 16)

assert offsets.keys() == {"logo", "byte_109", "byte_110", "byte_117",
                          "byte_11D", "byte_124", "scrollText", "music"}, offsets
data = binary.read_bytes()
assert offsets["byte_109"] == offsets["logo"] + 16383
logo = (here.parents[2] / "CGADEMO" / "CGADEMO.COM").read_bytes()[-16384:]
assert len(logo) == 16384
assert logo[0x280:0x380] == data[offsets["logo"] + 0x280:offsets["logo"] + 0x380]
scroll = data[offsets["scrollText"]:offsets["music"]]
assert scroll.endswith(b"\x00")
music = data[offsets["music"]:]
assert music.endswith(b"\xff\xff")

raster = bytearray(b"\x10" * (0x4172 * 2))
top = bytes((0x14, 0x14, 0x1c, 0x1c, 0x1d, 0x1d, 0x1c, 0x1c, 0x14, 0x14))
patterns = (
    ("byte_109", (0x14, 0x14, 0x1c, 0x1c, 0x1d, 0x1d, 0x1c, 0x1c, 0x14, 0x14)),
    ("byte_110", (0x16, 0x16, 0x1e, 0x1e, 0x1f, 0x1f, 0x1e, 0x1e, 0x16, 0x16)),
    ("byte_117", (0x12, 0x12, 0x1a, 0x1a, 0x1b, 0x1b, 0x1a, 0x1a, 0x12, 0x12)),
    ("byte_11D", (0x13, 0x13, 0x1b, 0x1b, 0x1f, 0x1f, 0x1b, 0x1b, 0x13, 0x13)),
    ("byte_124", (0x11, 0x11, 0x19, 0x19, 0x1b, 0x1b, 0x19, 0x19, 0x11, 0x11)),
)
for frame in range(252):
    base = frame * 121
    raster[base:base + 10] = top
    raster[base + 110:base + 121] = top + b"\x10"
    for name, colors in patterns:
        position = data[offsets[name] + frame * 2] // 2
        raster[base + 10 + position:base + 20 + position] = bytes(colors)
raster = raster[:252 * 121]
assert raster[:10] == top and raster[:121] != raster[121:242]
(output / "xgademo_raster.bin").write_bytes(raster)

# CGA mode 4 stores even and odd scanlines in separate 8 KB banks.
# Emit only colored runs, scaled 2x in XGA's 640x480 8-bit pixel map.
runs = bytearray()
mask = bytearray(640 * 480 // 8)
for row in range(190):
    plane = (row & 1) * 8192 + (row >> 1) * 80
    pixels = [((logo[plane + col // 4] >> (6 - 2 * (col & 3))) & 3)
              for col in range(320)]
    for col, color in enumerate(pixels):
        if color:
            for screen_row in (40 + row * 2, 41 + row * 2):
                mask[screen_row * 80 + col // 4] |= 3 << ((col & 3) * 2)
    start = 0
    while start < 320:
        color = pixels[start]
        end = start + 1
        while end < 320 and pixels[end] == color:
            end += 1
        if color:
            runs.extend(bytes((color,)))
            runs.extend((start * 2).to_bytes(2, "little"))
            runs.extend((40 + row * 2).to_bytes(2, "little"))
            runs.extend(((end - start) * 2).to_bytes(2, "little"))
        start = end

assert len(runs) % 7 == 0
mask[334 * 80:362 * 80] = b"\xff" * (28 * 80)
mask[380 * 80:408 * 80] = b"\xff" * (28 * 80)
mask[420 * 80:440 * 80] = b"\xff" * (20 * 80)
mask[446 * 80:466 * 80] = b"\xff" * (20 * 80)
(output / "xgademo_logo.bin").write_bytes(runs)
(output / "XGAMASK.DAT").write_bytes(mask)
(output / "xgademo_scroll.bin").write_bytes(scroll)
(output / "xgademo_music.bin").write_bytes(music)
print(f"Logo: {len(runs) // 7} colored runs; text: {len(scroll)} bytes; "
      f"score: {len(music)} bytes")