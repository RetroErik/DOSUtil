"""Pack the standalone fish into DEM7 BitBLT records and palette ramps."""

from pathlib import Path

from make_xga_fish import COLORS, HEIGHT, SIZES, WIDTH, balls


HERE = Path(__file__).resolve().parent
COLOR_NAMES = tuple(COLORS)
BALL_LIMIT = 300
SPRITE_SIZE = 36
MASK_BYTES = 8 * SPRITE_SIZE * ((SPRITE_SIZE + 7) // 8)
SPRITE_BYTES = len(COLOR_NAMES) * 8 * SPRITE_SIZE * SPRITE_SIZE
FLAG_BYTES = 3 * 16 * 16 + 16 * 16 // 8
assert FLAG_BYTES + MASK_BYTES + SPRITE_BYTES <= 65536
assert len(balls) == 294 and len(balls) <= BALL_LIMIT
assert len(SIZES) == 8 and len(COLOR_NAMES) == 5
assert sum(ball.color == "black" for ball in balls) == 1

with (HERE / "xga_morph_shapes.inc").open("w", encoding="ascii") as output:
    output.write("; One DEM7 fish; x:0..9 y:10..18 size:19..21 color:22..24 visible:25.\n")
    output.write("morph_shapes:\n")
    for ball in balls:
        assert ball.diameter in SIZES and ball.color in COLORS
        assert ball.diameter // 2 <= ball.x < WIDTH - ball.diameter // 2
        assert ball.diameter // 2 <= ball.y < HEIGHT - ball.diameter // 2
        packed = (ball.x | ball.y << 10
                  | SIZES.index(ball.diameter) << 19
                  | COLOR_NAMES.index(ball.color) << 22 | 1 << 25)
        output.write(f"    dd {packed}\n")

with (HERE / "xga_morph_palette.inc").open("w", encoding="ascii") as output:
    output.write("; DEM7: five sphere families x ten shades at palette 128..177.\n")
    for name in COLOR_NAMES:
        for shade in range(10):
            brightness = 0.22 + 0.74 * shade / 9
            highlight = 0.16 * max(0, shade - 8)
            channels = (min(255, round(channel * brightness * (1 - highlight)
                                       + 255 * highlight))
                        for channel in COLORS[name])
            output.write("    db " + ",".join(map(str, channels)) + "\n")

print(f"DEM7 fish: {len(balls)} balls, {len(SIZES)} sizes, "
      f"{len(COLOR_NAMES)} colors; VRAM bank 15: "
      f"{FLAG_BYTES + MASK_BYTES + SPRITE_BYTES}/65536 bytes")