"""Draw a flying XGA bird with the fish's five colors and eight ball sizes.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
"""

from collections import Counter
from pathlib import Path

from PIL import Image

from make_xga_fish import Ball, COLORS, HEIGHT, SIZES, WIDTH, ball_sprite


balls = []


def add(x, y, diameter, color):
    balls.append(Ball(round(x), round(y), diameter, color))


def inside_polygon(x, y, points):
    inside = False
    previous_x, previous_y = points[-1]
    for current_x, current_y in points:
        if (current_y > y) != (previous_y > y):
            crossing = ((previous_x - current_x) * (y - current_y) /
                        (previous_y - current_y) + current_x)
            if x < crossing:
                inside = not inside
        previous_x, previous_y = current_x, current_y
    return inside


def polygon(points, pitch, diameter, color):
    left = min(x for x, _ in points)
    right = max(x for x, _ in points)
    top = min(y for _, y in points)
    bottom = max(y for _, y in points)
    for row, y in enumerate(range(top, bottom + 1, pitch)):
        for column, x in enumerate(range(left + row % 2 * pitch // 2,
                                         right + 1, pitch)):
            if inside_polygon(x, y, points):
                add(x, y, diameter(x, y, row, column),
                    color(x, y, row, column))


def ellipse(cx, cy, rx, ry, pitch, diameter, color):
    for row, y in enumerate(range(cy - ry, cy + ry + 1, pitch)):
        for column, x in enumerate(range(cx - rx + row % 2 * pitch // 2,
                                         cx + rx + 1, pitch)):
            distance = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if distance <= 1:
                add(x, y, diameter(x, y, distance, row, column),
                    color(x, y, distance, row, column))


def path(points, count, diameter, color):
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        for index in range(count):
            fraction = index / count
            add(x0 + (x1 - x0) * fraction,
                y0 + (y1 - y0) * fraction, diameter, color)
    add(*points[-1], diameter, color)


# Three overlapping feathers make a fan with separate rounded tips.
polygon(((319, 328), (116, 331), (123, 356), (165, 378),
         (309, 357)), 21,
        lambda x, y, row, column: 16 if x < 150 else 20,
        lambda x, y, row, column: "aqua" if column % 5 == 0 else "blue")
polygon(((321, 337), (143, 356), (176, 405), (220, 420),
         (317, 358)), 21,
        lambda x, y, row, column: 16 if y > 398 else 20,
        lambda x, y, row, column: "aqua" if y > 385 or column % 4 == 0 else
        "navy")
polygon(((318, 348), (192, 390), (232, 437), (269, 426)), 21,
        lambda x, y, row, column: 16 if y > 417 else 20,
        lambda x, y, row, column: "aqua" if y > 415 else "blue")

# Three long feather tips shape the broad left wing.
polygon(((348, 292), (126, 258), (83, 199), (80, 86),
         (113, 92), (140, 181), (151, 47), (180, 64),
         (203, 159), (229, 97), (252, 112), (285, 208)), 22,
        lambda x, y, row, column: 16 if y < 96 or x < 102 else
        (28 if 170 < x < 300 and 170 < y < 255 else 24),
        lambda x, y, row, column: "aqua" if y < 102 or x < 116 or
        (row + column) % 7 == 0 else
        ("navy" if y > 175 and column % 3 else "blue"))
path(((92, 91), (101, 163), (152, 229)), 4, 20, "aqua")
path(((162, 56), (178, 130), (243, 226)), 4, 20, "aqua")
path(((238, 105), (261, 168), (309, 246)), 3, 16, "blue")

# The far wing rises to the right; its narrower base passes behind the head.
polygon(((337, 286), (419, 207), (491, 127), (577, 48),
         (595, 62), (552, 178), (514, 241), (390, 300)), 21,
        lambda x, y, row, column: 16 if x > 558 else
        (28 if 440 < x < 540 else 20),
        lambda x, y, row, column: "aqua" if x > 548 or
        (row + column) % 5 == 0 else
        ("navy" if row % 3 == 0 else "blue"))

# The oval torso has a dark back and a bright lower breast.
ellipse(367, 315, 117, 70, 23,
        lambda x, y, distance, row, column: 20 if distance > 0.78 else
        (36 if distance < 0.32 and (row + column) % 3 == 0 else
         32 if distance < 0.6 else 28),
        lambda x, y, distance, row, column: "aqua" if y > 331 or
        (y > 309 and column % 3 == 0) else
        ("navy" if y < 288 and column % 3 else "blue"))

# A small near-side wing folds over the body.
polygon(((322, 306), (382, 313), (329, 371), (289, 373)), 19,
        lambda x, y, row, column: 16 if y > 355 else 20,
        lambda x, y, row, column: "aqua" if column % 3 == 0 else "blue")

# Neck and head continue the belly's blue and aqua shading.
ellipse(463, 277, 47, 41, 17,
        lambda x, y, distance, row, column: 16 if distance > 0.78 else 24,
        lambda x, y, distance, row, column: "aqua" if y > 280 or
        column % 3 == 0 else "blue")

# The pointed beak and the two feet use the fish's gold balls.
polygon(((503, 278), (551, 286), (506, 298)), 9,
        lambda x, y, row, column: 8 if x > 533 else 12,
        lambda x, y, row, column: "gold")
for foot in (343, 389):
    path(((foot, 381), (foot + 6, 400), (foot - 4, 417)),
         2, 12, "gold")
    path(((foot - 4, 417), (foot - 16, 424)), 2, 8, "gold")
    path(((foot - 4, 417), (foot + 7, 427)), 2, 8, "gold")
    path(((foot - 4, 417), (foot - 2, 431)), 2, 8, "gold")

# One black sphere forms the eye. An aqua sphere behind it keeps its rim clear.
add(475, 266, 28, "aqua")
add(475, 266, 20, "black")


def main():
    sizes = Counter(ball.diameter for ball in balls)
    colors = Counter(ball.color for ball in balls)
    assert len(balls) <= 300, len(balls)
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

    output = Path(__file__).resolve().parent / "assets" / "xga_standalone_bird_preview.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    print(f"Bird: {len(balls)} balls, "
          f"sizes {dict(sorted(sizes.items()))}, "
          f"colors {dict(sorted(colors.items()))}")
    print(output)


if __name__ == "__main__":
    main()
