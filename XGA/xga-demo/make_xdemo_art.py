"""Build 96x90 four-level shaded dot-BOB glyphs and the CGA + ramp palette.

Each dot is shaded like an xga_balls sphere (xga_balls.make_balls_assets.py's
light = max(0, -0.42*nx - 0.58*ny + 0.69*nz) formula), quantized into four
cumulative 1-bit masks per letter (darkest rim first, brightest highlight
spot last) instead of a full 8bpp bitmap, to fit the .COM's 64 KB budget.

Glyph dimensions and the palette layout are duplicated as literals in
xdemo_scene.inc (XDEMO_GLYPH_W/H, XDEMO_GLYPH_LEVELS, XDEMO_SHADE_BASE) -
keep both in sync.
"""
from math import sqrt
from pathlib import Path

glyphs = {
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "I": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
    "K": ("10001", "10010", "10100", "11000", "10100", "10010", "10001"),
    "X": ("10001", "10001", "01010", "00100", "01010", "10001", "10001"),
    "G": ("01111", "10000", "10000", "10011", "10001", "10001", "01111"),
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "0": ("01110", "10001", "10011", "10101", "11001", "10001", "01110"),
    "2": ("01110", "10001", "00001", "00010", "00100", "01000", "11111"),
    "6": ("00110", "01000", "10000", "11110", "10001", "10001", "01110"),
    "e": ("00000", "00000", "01110", "10001", "11111", "10000", "01111"),
    "t": ("00100", "00100", "11111", "00100", "00100", "00100", "00011"),
    "r": ("00000", "00000", "10110", "11001", "10000", "10000", "10000"),
    "o": ("00000", "00000", "01110", "10001", "10001", "10001", "01110"),
    "i": ("00100", "00000", "01100", "00100", "00100", "00100", "01110"),
    "k": ("10000", "10000", "10010", "10100", "11000", "10100", "10010"),
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
    " ": ("00000",) * 7,
}

WIDTH = 96
HEIGHT = 90
COLS = 5
ROWS = 7
DOT = 18
MARGIN = 6
LEVELS = 4
LEVEL_LIGHT_THRESHOLDS = (0.0, 0.35, 0.6, 0.8)
# Vivid 0-63 VGA-DAC anchor hues, one per lane; xdemo_colors indexes these.
LANE_HUES = (
    (63, 10, 8),    # 0 red
    (63, 55, 8),    # 1 yellow
    (10, 55, 15),   # 2 green
    (10, 50, 58),   # 3 cyan
    (55, 15, 54),   # 4 magenta
    (15, 25, 63),   # 5 blue
    (50, 50, 50),   # 6 silver/white
    (46, 28, 10),   # 7 brown
)
SHADE_VALUES = (0.15, 0.45, 0.75, 1.0)

base_cga = (
    (0, 0, 0), (0, 0, 42), (0, 42, 0), (0, 42, 42),
    (42, 0, 0), (42, 0, 42), (42, 21, 0), (42, 42, 42),
    (21, 21, 21), (21, 21, 63), (21, 63, 21), (21, 63, 63),
    (63, 21, 21), (63, 21, 63), (63, 63, 21), (63, 63, 63),
)

art = ["xdemo_palette:", "    ; 0..15: base CGA colors"]
colors = [component for color in base_cga for component in color]
for red, green, blue in LANE_HUES:
    art.append("    ; lane shades (dark to bright)")
    for value in SHADE_VALUES:
        scale = 0.23 + 0.73 * value
        white = 0.70 * max(0.0, (value - 0.77) / 0.23)
        rgb = [min(63, round(channel * scale * (1 - white) + 63 * white))
               for channel in (red, green, blue)]
        colors.extend(rgb)
for offset in range(0, len(colors), 12):
    art.append("    db " + ",".join(map(str, colors[offset:offset + 12])))

art.append("xdemo_masks:")


def grid_pos(index, count, span):
    return round(MARGIN + index * span / (count - 1))


col_x = [grid_pos(i, COLS, WIDTH - 2 * MARGIN - DOT) for i in range(COLS)]
row_y = [grid_pos(i, ROWS, HEIGHT - 2 * MARGIN - DOT) for i in range(ROWS)]
dot_radius = (DOT - 1) / 2

for letter in "XGA":
    level_pixels = [[[False] * WIDTH for _ in range(HEIGHT)] for _ in range(LEVELS)]
    for row, pattern in enumerate(glyphs[letter]):
        for column, dot in enumerate(pattern):
            if dot != "1":
                continue
            base_x = col_x[column]
            base_y = row_y[row]
            for offset_y in range(DOT):
                for offset_x in range(DOT):
                    nx = (offset_x - dot_radius) / dot_radius
                    ny = (offset_y - dot_radius) / dot_radius
                    r2 = nx * nx + ny * ny
                    if r2 >= 1:
                        continue
                    nz = sqrt(1 - r2)
                    light = max(0.0, -0.42 * nx - 0.58 * ny + 0.69 * nz)
                    for level in range(LEVELS):
                        if light >= LEVEL_LIGHT_THRESHOLDS[level]:
                            level_pixels[level][base_y + offset_y][base_x + offset_x] = True
    for level in range(LEVELS):
        pixels = level_pixels[level]
        mask = [sum(1 << bit for bit in range(8) if pixels[y][x + bit])
                for y in range(HEIGHT) for x in range(0, WIDTH, 8)]
        art.append(f"    ; {letter if letter != ' ' else 'space'} level {level}")
        for offset in range(0, len(mask), 16):
            art.append("    db " + ",".join(map(str, mask[offset:offset + 16])))

# Bottom scroller: each glyph row's contiguous "on" run becomes one line
# segment (dx0,dx1,dy), reusing the same dot-font row patterns at a much
# smaller cell size. Coordinates are relative to the scroll text's start;
# xdemo_scene.inc adds the live scroll offset and the screen baseline.
SCROLL_CELL_W = 4
SCROLL_CELL_H = 4
SCROLL_PITCH = 24
for directive, text in (("%ifdef XDEMO2", "Retro Erik - 2026"),
                        ("%else", "RETRO ERIK 2026")):
    art.append(directive)
    scroll_segments = []
    for index, letter in enumerate(text):
        box_x = index * SCROLL_PITCH
        for row, pattern in enumerate(glyphs[letter]):
            column = 0
            while column < 5:
                if pattern[column] != "1":
                    column += 1
                    continue
                start = column
                while column < 5 and pattern[column] == "1":
                    column += 1
                x0 = box_x + start * SCROLL_CELL_W
                x1 = box_x + column * SCROLL_CELL_W - 1
                scroll_segments.append((x0, x1, row * SCROLL_CELL_H))
    if directive == "%ifdef XDEMO2":
        pixels = [[False] * (len(text) * SCROLL_PITCH)
                  for _ in range(6 * SCROLL_CELL_H + 1)]
        for x0, x1, y in scroll_segments:
            for column in range(x0, x1 + 1):
                pixels[y][column] = True
        mask = [sum(1 << bit for bit in range(8)
                    if pixels[row][column + bit])
                for row in range(len(pixels))
                for column in range(0, len(pixels[row]), 8)]
        art.append("xdemo2_scroll_mask:")
        for offset in range(0, len(mask), 16):
            art.append("    db " + ",".join(map(str, mask[offset:offset + 16])))
    art.append("xdemo_scroll_segments:")
    if directive == "%else":
        for x0, x1, y in scroll_segments:
            art.append(f"    dw {x0},{x1},{y}")
    art.append("xdemo_scroll_segments_end:")
    print(text, "segments:", len(scroll_segments),
          "text width:", len(text) * SCROLL_PITCH)
art.append("%endif")

Path(__file__).with_name("xdemo_art.inc").write_text("\n".join(art) + "\n", encoding="ascii")