"""Render source-art previews for XBALLS modes 4 and 5 (requires Pillow).

These images show the intended geometry, not a screenshot of XGA hardware.
By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
"""
from math import cos, pi, sin
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ASSETS = HERE / "assets"
W, H = 640, 480


def palette(name):
    colors = []
    for line in (HERE / name).read_text(encoding="ascii").splitlines():
        if line.strip().startswith("db "):
            colors.append(tuple(map(int, line.split("db ")[1].split(","))))
    return colors


def draw_masked(image, source, mask, source_y, left, top, size, colors):
    pix = image.load()
    for y in range(size):
        sy = top + y
        if not 0 <= sy < H:
            continue
        for x in range(size):
            sx = left + x
            if not 0 <= sx < W:
                continue
            if mask[y * (size // 8) + x // 8] & (1 << (x & 7)):
                index = source[(source_y + y) * size + x]
                pix[sx, sy] = colors[index]


dense_colors = palette("xga_dense_palette.inc")
dense_source = (ASSETS / "xga_ball24x4.bin").read_bytes()
dense_mask = (ASSETS / "xga_ball24_mask.bin").read_bytes()
dense = Image.new("RGB", (W, H), (7, 28, 34))
phase = 32
for lane in range(4):
    center = 60 + lane * 120
    for ball in range(32):
        sample = (phase + lane * 47 - ball * 11) & 255
        value = round(127 * sin(sample * 2 * pi / 256))
        top = center + (value * 31 >> 7) - 12
        left = 12 + ball * 19
        draw_masked(dense, dense_source, dense_mask, (lane & 3) * 24,
                    left, top, 24, [(0, 0, 0)] * 32 + dense_colors)
dense.save(ASSETS / "xga_balls_dense_preview.png")

orbit_colors = palette("xga_orbit_palette.inc")
orbit_masks = (ASSETS / "xga_orbit_masks.bin").read_bytes()
orbit = Image.new("RGB", (W, H), orbit_colors[7])
lines = [line.strip() for line in
         (HERE / "xga_orbit3d_frames.inc").read_text(encoding="ascii").splitlines()]
records = []
sizes = tuple(range(80, 185, 8))
mask_offsets = []
offset = 0
for size in sizes:
    mask_offsets.append(offset)
    offset += size * size // 8
for line in lines[lines.index("orbit3d_frames:") + 1:]:
    if line.startswith("db "):
        b0, b1, b2, packed = map(int, line[3:].split(","))
        position = b0 | b1 << 8 | b2 << 16
        left, top = position & 511, position >> 9
        size = sizes[packed >> 3]
        color = 96 + (packed & 7)
        offset = mask_offsets[packed >> 3]
        records.append((left, top, offset, size, color))
for left, top, offset, size, color in records[76 * 7:77 * 7]:
    mask = orbit_masks[offset:offset + size * size // 8]
    pix = orbit.load()
    for y in range(size):
        sy = top + y
        if not 0 <= sy < H:
            continue
        for x in range(size):
            sx = left + x
            if 0 <= sx < W and mask[y * (size // 8) + x // 8] & (1 << (x & 7)):
                pix[sx, sy] = orbit_colors[color - 96]
orbit.save(ASSETS / "xga_balls_orbit3d_preview.png")

flag_palette = palette("xga_flag_palette.inc")
flag_source = (ASSETS / "xga_flag_balls.bin").read_bytes()
flag_mask = (ASSETS / "xga_flag_mask.bin").read_bytes()
flag = Image.new("RGB", (W, H), orbit_colors[7])
flag_lines = (HERE / "xga_flag_colors.inc").read_text(encoding="ascii")
flag_colors = [int(number) for line in flag_lines.splitlines()
               if line.strip().startswith("db ")
               for number in line.strip()[3:].split(",")]
assert len(flag_colors) == 33 * 24
for col in range(33):
    angle = (50 + col * 7) * 2 * pi / 256
    wave_y = (round(127 * sin(angle)) * col) >> 7
    wave_x = (round(127 * cos(angle)) * col) >> 8
    left = 80 + col * 14 + wave_x
    for row in range(24):
        color = flag_colors[row * 33 + col]
        top = 65 + row * 14 + wave_y
        draw_masked(flag, flag_source, flag_mask, color * 16,
                    left, top, 16, [(0, 0, 0)] * 104 + flag_palette)
flag.save(ASSETS / "xga_balls_flag_preview.png")
print("Created dense snake, 3D orbit and Norwegian flag previews in assets/")
