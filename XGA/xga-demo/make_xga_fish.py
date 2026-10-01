"""Draw an XGA fish from 3D balls in eight sizes and five colors.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
"""

from collections import Counter
from dataclasses import dataclass
from math import sqrt
from pathlib import Path

from PIL import Image


WIDTH, HEIGHT = 640, 480
SIZES = (8, 12, 16, 20, 24, 28, 32, 36)
COLORS = {
    "navy": (14, 43, 145),
    "blue": (20, 100, 230),
    "aqua": (38, 198, 233),
    "gold": (255, 181, 48),
    "black": (3, 5, 12),
}


@dataclass(frozen=True)
class Ball:
    x: int
    y: int
    diameter: int
    color: str


balls = []


def add(x, y, diameter, color):
    balls.append(Ball(round(x), round(y), diameter, color))


def triangle(a, b, c, divisions, size, choose_color):
    """Pack balls on a triangular lattice, including all three edges."""
    for i in range(divisions + 1):
        for j in range(divisions + 1 - i):
            k = divisions - i - j
            x = (a[0] * i + b[0] * j + c[0] * k) / divisions
            y = (a[1] * i + b[1] * j + c[1] * k) / divisions
            add(x, y, size(i, j, k), choose_color(i, j, k))


# The forked tail and fins sit behind the body. Each lobe has a broad fan,
# with open water between its inner edges.
triangle((424, 241), (544, 132), (511, 221), 8,
         lambda i, j, k: 16 if j > 5 else 20,
         lambda i, j, k: "gold" if j > 6 else
         ("aqua" if (i + j) % 3 == 0 else "blue"))
triangle((424, 259), (511, 279), (544, 368), 8,
         lambda i, j, k: 16 if k > 5 else 20,
         lambda i, j, k: "gold" if k > 6 else
         ("aqua" if (i + k) % 3 == 0 else "blue"))
triangle((235, 197), (323, 103), (382, 199), 7,
         lambda i, j, k: 16 if j > 4 else 24,
         lambda i, j, k: "gold" if j > 5 else
         ("aqua" if (i + k) % 4 == 0 else "navy"))
triangle((276, 292), (325, 368), (389, 291), 7,
         lambda i, j, k: 16 if j > 5 else 20,
         lambda i, j, k: "aqua" if (i + j) % 4 == 0 else "navy")

# Dense staggered rows form a rounded, continuous body. The sizes decrease
# toward the outline so the individual spheres remain apparent.
for row, y in enumerate(range(175, 320, 18)):
    for column, x in enumerate(range(144 + (row % 2) * 11, 453, 22)):
        distance = ((x - 296) / 153) ** 2 + ((y - 247) / 75) ** 2
        if distance > 1:
            continue
        if distance > 0.83:
            diameter = 20
        elif distance > 0.62:
            diameter = 24
        elif (row + column) % 4 == 0:
            diameter = 36
        else:
            diameter = 28 if (row + column) % 3 == 0 else 32

        if x < 219:
            color = "aqua" if (row + column) % 4 else "blue"
        elif (row * 3 + column * 2) % 13 == 0:
            color = "gold"
        elif y < 211:
            color = "navy" if column % 3 else "blue"
        elif y > 281:
            color = "aqua" if column % 3 else "blue"
        else:
            color = "aqua" if (row + column) % 4 == 0 else "blue"
        add(x, y, diameter, color)

# A visible pectoral fin projects down and back from the near side.
triangle((264, 246), (347, 272), (304, 315), 6,
         lambda i, j, k: 16,
         lambda i, j, k: "gold" if (i + j) % 4 == 0 else "aqua")

# Round the snout and leave a small dark opening between the lips.
for x, y, size, color in (
    (153, 220, 16, "aqua"), (140, 231, 12, "blue"),
    (130, 242, 8, "gold"), (133, 262, 8, "gold"),
    (145, 275, 12, "blue"), (158, 287, 16, "aqua"),
):
    add(x, y, size, color)

# The eye is the only black sphere, set against a bright socket.
add(190, 221, 28, "gold")
add(190, 221, 20, "black")


def ball_sprite(diameter, color):
    sprite = Image.new("RGBA", (diameter, diameter))
    pixels = sprite.load()
    radius = diameter / 2
    base = COLORS[color]
    for y in range(diameter):
        for x in range(diameter):
            nx = (x + 0.5 - radius) / radius
            ny = (y + 0.5 - radius) / radius
            distance = nx * nx + ny * ny
            if distance >= 1:
                continue
            nz = sqrt(1 - distance)
            light = max(0.0, -0.43 * nx - 0.48 * ny + 0.77 * nz)
            shade = 0.2 + 0.76 * light
            highlight = light ** 34
            rim = min(1.0, (1 - distance) * 12)
            pixels[x, y] = (
                *(min(255, round((channel * shade +
                                   (255 - channel * shade) * 0.76 * highlight)
                                  * (0.57 + 0.43 * rim))) for channel in base),
                255,
            )
    return sprite


def main():
    sizes = Counter(ball.diameter for ball in balls)
    colors = Counter(ball.color for ball in balls)
    assert len(balls) <= 300
    assert set(sizes) == set(SIZES), sizes
    assert set(colors) == set(COLORS), colors
    assert colors["black"] == 1
    assert all(ball.diameter // 2 <= ball.x < WIDTH - ball.diameter // 2
               and ball.diameter // 2 <= ball.y < HEIGHT - ball.diameter // 2
               for ball in balls)

    image = Image.new("RGB", (WIDTH, HEIGHT), (3, 8, 21))
    cache = {}
    for ball in balls:
        key = ball.diameter, ball.color
        if key not in cache:
            cache[key] = ball_sprite(*key)
        image.paste(cache[key], (ball.x - ball.diameter // 2,
                                 ball.y - ball.diameter // 2), cache[key])

    output = Path(__file__).resolve().parent / "assets" / "xga_standalone_fish_preview.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    print(f"Fish: {len(balls)} balls, "
          f"sizes {dict(sorted(sizes.items()))}, "
          f"colors {dict(sorted(colors.items()))}")
    print(output)


if __name__ == "__main__":
    main()
