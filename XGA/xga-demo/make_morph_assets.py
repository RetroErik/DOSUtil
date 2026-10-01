"""Generate compact point shapes and color ramps for XBALLS mode 7.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
"""
from argparse import ArgumentParser
from math import cos, hypot, pi, sin, sqrt
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE / "assets"
COUNT = 352
NAMES = ("TREE", "GIRAFFE", "BIRD", "FISH", "DRAGON")
VISIBLE_COUNTS = (320, 304, 352, 296, 336)

# Twelve color families with ten shades each fit the remaining palette.
RGB = ((151, 91, 49), (105, 235, 148), (249, 212, 82),
       (255, 150, 57), (250, 75, 90), (72, 227, 240),
    (70, 126, 235), (8, 16, 28), (247, 231, 174),
    (32, 166, 118), (12, 86, 232), (113, 190, 255))


def ellipse(cx, cy, rx, ry, count, color, size, start=0, stop=2 * pi):
    return [(round(cx + rx * cos(start + (stop - start) * i / count)),
             round(cy + ry * sin(start + (stop - start) * i / count)),
             size if isinstance(size, int) else size[i % len(size)], color)
            for i in range(count)]


def filled_ellipse(cx, cy, rx, ry, count, color, size):
    return [(round(cx + rx * sqrt((i + 0.5) / count) * cos(i * 2.399963)),
             round(cy + ry * sqrt((i + 0.5) / count) * sin(i * 2.399963)),
             size if isinstance(size, int) else size[i % len(size)], color)
            for i in range(count)]


def triangle(a, b, c, count, color, size):
    result = []
    for i in range(count):
        radius = sqrt((i + 0.5) / count)
        angle = (i * 0.618034) % 1
        x = (1 - radius) * a[0] + radius * ((1 - angle) * b[0] + angle * c[0])
        y = (1 - radius) * a[1] + radius * ((1 - angle) * b[1] + angle * c[1])
        result.append((round(x), round(y),
                       size if isinstance(size, int) else size[i % len(size)], color))
    return result


def path(points, count, color, size):
    lengths = [hypot(x1 - x0, y1 - y0)
               for (x0, y0), (x1, y1) in zip(points, points[1:])]
    total = sum(lengths)
    result = []
    for i in range(count):
        distance = total * i / max(1, count - 1)
        for segment, length in enumerate(lengths):
            if distance <= length or segment == len(lengths) - 1:
                x0, y0 = points[segment]
                x1, y1 = points[segment + 1]
                t = min(1, distance / length) if length else 0
                result.append((round(x0 + (x1 - x0) * t),
                               round(y0 + (y1 - y0) * t),
                               size if isinstance(size, int)
                               else size[i % len(size)], color))
                break
            distance -= length
    return result


def thick_path(points, width, count, color, size):
    center = path(points, count, color, size)
    result = []
    for index, (x, y, ball_size, ball_color) in enumerate(center):
        before = center[max(index - 2, 0)]
        after = center[min(index + 2, count - 1)]
        delta_x, delta_y = after[0] - before[0], after[1] - before[1]
        length = hypot(delta_x, delta_y) or 1
        offset = width * (2 * ((index * 0.618034) % 1) - 1)
        result.append((round(x - offset * delta_y / length),
                       round(y + offset * delta_x / length), ball_size, ball_color))
    return result


shapes = []

tree = []
tree += filled_ellipse(233, 185, 73, 68, 42, 9, (1, 2))
tree += filled_ellipse(319, 134, 88, 68, 56, 1, (1, 2))
tree += filled_ellipse(406, 186, 73, 68, 42, 9, (1, 2))
tree += filled_ellipse(267, 225, 63, 37, 20, 9, 2)
tree += filled_ellipse(371, 225, 63, 37, 20, 9, 2)
tree += ellipse(232, 178, 66, 62, 12, 1, 1, pi, 2 * pi)
tree += ellipse(319, 131, 80, 61, 10, 1, 1, pi, 2 * pi)
tree += ellipse(407, 178, 67, 63, 12, 1, 1, pi, 2 * pi)
tree += filled_ellipse(320, 221, 60, 23, 12, 9, 1)
tree += thick_path([(320, 411), (318, 319), (320, 213)], 24, 34, 0, (1, 2))
tree += thick_path([(316, 293), (275, 244), (228, 206)], 11, 12, 0, 1)
tree += thick_path([(324, 291), (369, 244), (412, 205)], 11, 12, 0, 1)
tree += thick_path([(276, 246), (246, 173)], 6, 8, 0, 1)
tree += thick_path([(367, 244), (391, 174)], 6, 8, 0, 1)
tree += thick_path([(315, 391), (270, 415)], 12, 4, 0, 1)
tree += thick_path([(326, 392), (372, 415)], 12, 4, 0, 1)
tree += path([(207, 423), (429, 423)], 12, 1, 1)
shapes.append(tree)

giraffe = []
giraffe += filled_ellipse(280, 269, 107, 56, 72, 2, (1, 2))
giraffe += filled_ellipse(282, 241, 85, 28, 16, 3, 1)
giraffe += filled_ellipse(283, 291, 70, 21, 14, 8, 1)
giraffe += thick_path([(352, 266), (378, 184), (407, 107)], 21, 48, 2, (1, 2))
giraffe += thick_path([(366, 206), (384, 151), (402, 113)], 9, 12, 3, 1)
giraffe += filled_ellipse(436, 111, 39, 24, 24, 2, (1, 2))
giraffe += filled_ellipse(468, 129, 21, 14, 8, 8, 1)
for start, foot in ((209, 202), (256, 248), (330, 329), (368, 378)):
    giraffe += thick_path([(start, 291), (foot, 355), (foot, 409)],
                          12, 14, 2, (1, 2))
for foot in (202, 248, 329, 378):
    giraffe += filled_ellipse(foot, 411, 11, 6, 3, 0, 1)
for x, y in ((225, 245), (262, 276), (301, 241), (331, 276),
             (362, 238), (380, 195)):
    giraffe += filled_ellipse(x, y, 15, 12, 4, 0, 1)
giraffe += thick_path([(417, 93), (412, 64)], 5, 4, 0, 0)
giraffe += thick_path([(438, 92), (445, 65)], 5, 4, 0, 0)
giraffe += triangle((418, 103), (396, 83), (411, 117), 2, 2, 1)
giraffe += triangle((448, 100), (462, 82), (454, 116), 2, 2, 1)
giraffe += thick_path([(177, 263), (155, 287)], 6, 2, 0, 1)
giraffe += filled_ellipse(151, 294, 9, 9, 2, 0, 1)
giraffe += [(450, 104, 0, 0), (449, 101, 0, 8)]
shapes.append(giraffe)

bird = []
bird += triangle((351, 263), (145, 93), (213, 224), 95, 6, (1, 2))
bird += triangle((274, 199), (153, 94), (188, 152), 15, 11, 1)
bird += triangle((391, 262), (505, 92), (470, 203), 82, 11, (1, 2))
bird += triangle((373, 260), (466, 150), (459, 211), 15, 6, 1)
bird += triangle((317, 294), (151, 314), (186, 398), 28, 6, (1, 2))
bird += filled_ellipse(387, 289, 82, 47, 68, 6, (1, 2))
bird += filled_ellipse(415, 308, 50, 25, 16, 5, 1)
bird += filled_ellipse(468, 259, 30, 25, 21, 11, (1, 2))
bird += triangle((493, 258), (536, 270), (493, 282), 10, 3, (0, 1))
bird += [(479, 250, 0, 0), (477, 248, 0, 8)]
shapes.append(bird)

fish = []
fish += thick_path([(257, 240), (212, 223), (172, 194), (140, 159)],
                   22, 24, 10, (2, 1, 2, 3, 2, 1, 2, 2))
fish += filled_ellipse(143, 165, 24, 19, 4, 10, (2, 1, 2, 1))
fish += thick_path([(257, 246), (211, 265), (172, 293), (138, 322)],
                   22, 24, 11, (2, 1, 3, 3, 2, 1, 2, 2))
fish += filled_ellipse(143, 316, 24, 19, 4, 11, (2, 1, 2, 1))
fish += filled_ellipse(312, 174, 55, 29, 20, 10,
                       (2, 1, 3, 2, 2, 1, 3, 2, 0, 2))
fish += triangle((321, 284), (339, 330), (381, 289), 9, 11,
                 (3, 2, 1, 2, 3, 2, 1, 2, 0))
body = []
body += filled_ellipse(353, 243, 109, 77, 62, 10,
                       (3, 3, 2, 3, 2, 3, 1, 3, 3, 2))
body += filled_ellipse(370, 252, 86, 47, 29, 6, (3, 3, 2, 3, 2))
body += filled_ellipse(337, 204, 91, 39, 25, 10, (3, 2, 3, 1, 3))
body += filled_ellipse(394, 233, 65, 50, 30, 11, (3, 3, 2, 3, 3, 1))
body += filled_ellipse(352, 280, 86, 30, 20, 11, (3, 2, 3, 2, 2))
body += filled_ellipse(440, 243, 53, 53, 27, 11, (3, 2, 3, 2, 1))
body += filled_ellipse(468, 250, 24, 27, 10, 11, (3, 2, 3, 2, 1))
assert len(body) == 203
fish += body
fish += filled_ellipse(397, 273, 14, 15, 5, 6, (3, 2, 1, 2, 0))
fish += [(459, 214, 2, 11), (459, 214, 1, 7), (456, 211, 0, 8)]
diameters = (8, 16, 24, 32)
sizes = [sum(size == index for _, _, size, _ in fish) for index in range(4)]
fish_left = min(x - diameters[size] // 2 for x, _, size, _ in fish)
fish_right = max(x + diameters[size] // 2 for x, _, size, _ in fish)
fish_top = min(y - diameters[size] // 2 for _, y, size, _ in fish)
fish_bottom = max(y + diameters[size] // 2 for _, y, size, _ in fish)
assert 360 <= fish_right - fish_left <= 420 and 200 <= fish_bottom - fish_top <= 240
assert 118 <= sizes[3] <= 148 and 89 <= sizes[2] <= 118, sizes
assert 44 <= sizes[1] <= 59 and sizes[0] < 15, sizes
print(f"FISH: {fish_right - fish_left}x{fish_bottom - fish_top}px, "
    f"size counts 8/16/24/32: {sizes}")
shapes.append(fish)

dragon = []
dragon += triangle((339, 253), (407, 90), (464, 217), 40, 4, (2, 3))
dragon += triangle((330, 247), (167, 111), (212, 251), 58, 4, (2, 3))
dragon += triangle((308, 230), (200, 147), (232, 226), 25, 3, 2)
dragon += filled_ellipse(306, 281, 99, 60, 66, 4, (2, 3, 2, 1))
dragon += filled_ellipse(326, 307, 66, 25, 16, 2, (1, 2))
dragon += thick_path([(360, 260), (402, 205), (444, 177)], 19, 40, 4, (1, 2))
dragon += filled_ellipse(466, 169, 37, 27, 24, 4, (1, 2))
dragon += triangle((480, 181), (523, 197), (501, 203), 10, 3, (0, 1))
dragon += thick_path([(257, 310), (242, 386)], 14, 10, 4, (1, 2))
dragon += thick_path([(354, 313), (379, 385)], 14, 10, 4, (1, 2))
dragon += thick_path([(218, 296), (156, 321), (136, 370),
                      (159, 391), (192, 361)],
                     15, 22, 4, (1, 2))
dragon += thick_path([(444, 150), (443, 119)], 5, 3, 2, 0)
dragon += thick_path([(470, 147), (483, 122)], 5, 3, 2, 0)
dragon += [(481, 159, 0, 0), (480, 157, 0, 8)]
dragon += [(245, 390, 0, 2), (251, 391, 0, 2),
           (378, 393, 0, 2), (386, 390, 0, 2)]
dragon += [(481, 205, 0, 2), (494, 209, 0, 2), (508, 208, 0, 2)]
shapes.append(dragon)

assert len(shapes) == len(VISIBLE_COUNTS)
for shape_index, shape in enumerate(shapes):
    count = VISIBLE_COUNTS[shape_index]
    assert len(shape) == count, (NAMES[shape_index], len(shape), count)
    for x, y, size, color in shape:
        assert 16 <= x <= 623 and 16 <= y <= 463, (NAMES[shape_index], x, y)
        assert size in range(4) and color in range(len(RGB))
    selected = [(*point, True) for point in shape]
    selected.extend((*selected[index * count // (COUNT - count)][:4], False)
                    for index in range(COUNT - count))
    shapes[shape_index] = selected

def point_cost(source, target):
    return ((source[0] - target[0]) ** 2 + (source[1] - target[1]) ** 2
            + 256 * (source[2] - target[2]) ** 2
            + 900 * (source[3] != target[3])
            + 1600 * (source[4] != target[4]))


for shape_index in range(1, len(shapes)):
    previous = shapes[shape_index - 1]
    available = set(range(COUNT))
    target = shapes[shape_index]
    source_order = sorted(range(COUNT), key=lambda source:
                          min(point_cost(previous[source], point)
                              for point in target), reverse=True)
    aligned = [None] * COUNT
    for source in source_order:
        index = min(available, key=lambda candidate:
                    point_cost(previous[source], target[candidate]))
        aligned[source] = target[index]
        available.remove(index)
    shapes[shape_index] = aligned

def loop_cost():
    return sum(point_cost(shape[index], shapes[(shape_index + 1) % len(shapes)][index])
               for shape_index, shape in enumerate(shapes)
               for index in range(COUNT))


greedy_cost = loop_cost()
for _ in range(2):
    for shape_index, shape in enumerate(shapes):
        previous = shapes[shape_index - 1]
        following = shapes[(shape_index + 1) % len(shapes)]
        for left in range(COUNT):
            for right in range(left + 1, COUNT):
                current = (point_cost(previous[left], shape[left])
                           + point_cost(shape[left], following[left])
                           + point_cost(previous[right], shape[right])
                           + point_cost(shape[right], following[right]))
                swapped = (point_cost(previous[left], shape[right])
                           + point_cost(shape[right], following[left])
                           + point_cost(previous[right], shape[left])
                           + point_cost(shape[left], following[right]))
                if swapped < current:
                    shape[left], shape[right] = shape[right], shape[left]
assert loop_cost() <= greedy_cost

fish_eye = [index for index, (x, y, _, color, visible) in enumerate(shapes[3])
            if visible and (x, y, shapes[3][index][2], color)
            in ((459, 214, 2, 11), (459, 214, 1, 7), (456, 211, 0, 8))]
assert len(fish_eye) == 3, fish_eye
fish_eye.sort(key=lambda index: -shapes[3][index][2])
eye_slots = set(fish_eye)
draw_order = [index for index in range(COUNT) if index not in eye_slots] + fish_eye
shapes = [[shape[index] for index in draw_order] for shape in shapes]

for shape_index, shape in enumerate(shapes):
    following = shapes[(shape_index + 1) % len(shapes)]
    for source, target in zip(shape, following):
        for fraction in range(0, 257, 2):
            x = (source[0] * (256 - fraction) + target[0] * fraction) // 256
            y = (source[1] * (256 - fraction) + target[1] * fraction) // 256
            assert 16 <= x <= 623 and 16 <= y <= 463

for shape_index, shape in enumerate(shapes):
    following = shapes[(shape_index + 1) % len(shapes)]
    lengths = [hypot(source[0] - target[0], source[1] - target[1])
               for source, target in zip(shape, following)]
    print(f"{NAMES[shape_index]} -> {NAMES[(shape_index + 1) % len(shapes)]}: "
          f"mean {sum(lengths) / COUNT:.1f}px, max {max(lengths):.1f}px")
print(f"Loop matching cost: {greedy_cost} -> {loop_cost()}")

parser = ArgumentParser(description=__doc__)
parser.add_argument("--preview-only", action="store_true",
                    help="render the preview without updating DEM7 include files")
parser.add_argument("--fish-preview", action="store_true",
                    help="render only the fish, with a white silhouette beside it")
inspection = parser.add_mutually_exclusive_group()
inspection.add_argument("--debug-target", choices=NAMES,
                        help="show indexed ball groups for this target and the next one")
inspection.add_argument("--step-targets", action="store_true",
                        help="pause on each finished target in the offline preview")
args = parser.parse_args()

def shade_rgb(color, shade):
    if color == 7:
        return 2 + shade, 3 + shade, 6 + 2 * shade
    value = shade / 9
    scale = 0.23 + 0.73 * value
    white = 0.70 * max(0.0, (value - 0.77) / 0.23)
    return tuple(min(255, round(channel * scale * (1 - white)
                                + 255 * white)) for channel in RGB[color])


if not args.preview_only and not args.fish_preview:
    with (HERE / "xga_morph_shapes.inc").open("w", encoding="ascii") as out:
        out.write(f"; Five figures, up to {COUNT} visible balls each; generated by make_morph_assets.py.\n")
        out.write("; Bits 0..9 x, 10..18 y, 19..20 size, 21..24 color, 25 visible.\n")
        out.write("morph_shapes:\n")
        for name, shape in zip(NAMES, shapes):
            out.write(f"; {name}\n")
            for x, y, size, color, visible in shape:
                assert 16 <= x < 624 and 16 <= y < 464 and 0 <= size < 4
                assert 0 <= color < 12
                value = x | (y << 10) | (size << 19) | (color << 21) | (int(visible) << 25)
                out.write(f"    dd {value}\n")

    with (HERE / "xga_morph_palette.inc").open("w", encoding="ascii") as out:
        out.write("; Palette entries 128..247: twelve 10-shade morph colors.\n")
        for color in range(len(RGB)):
            for shade in range(10):
                out.write("    db " + ",".join(map(str, shade_rgb(color, shade))) + "\n")

try:
    from PIL import Image, ImageDraw
except ImportError:
    if args.preview_only or args.fish_preview:
        parser.error("Pillow is required to generate a preview")
else:
    def draw_ball(draw, px, py, size, color):
        radius = (8, 16, 24, 32)[size] / 2
        draw.ellipse((px - radius, py - radius, px + radius, py + radius),
                     fill=shade_rgb(color, 1))
        draw.ellipse((px - radius + 1, py - radius + 1,
                  px + radius - 2, py + radius - 2),
                     fill=shade_rgb(color, 6))
        draw.ellipse((px - radius * .73, py - radius * .75,
                      px + radius * .35, py + radius * .28),
                     fill=shade_rgb(color, 8))
        draw.ellipse((px - radius * .63, py - radius * .65,
                      px - radius * .18, py - radius * .20),
                     fill=shade_rgb(color, 9))

    if args.fish_preview:
        preview = Image.new("RGB", (640, 480), (3, 8, 13))
        draw = ImageDraw.Draw(preview)
        silhouette = Image.new("L", preview.size)
        silhouette_draw = ImageDraw.Draw(silhouette)
        for x, y, size, color, visible in shapes[3]:
            if visible:
                draw_ball(draw, x, y, size, color)
                radius = diameters[size] // 2
                silhouette_draw.ellipse((x - radius, y - radius,
                                         x + radius, y + radius), fill=255)
        ImageDraw.floodfill(silhouette, (350, 240), 128)
        assert silhouette.getextrema()[1] < 255, "Disconnected fish balls"
        preview.crop((fish_left - 26, fish_top - 24,
                  fish_right + 26, fish_bottom + 24)).save(
            ASSETS / "xga_morph_fish_preview.png")
    else:
        preview = Image.new("RGB", (1280, 1440), (3, 8, 13))
        draw = ImageDraw.Draw(preview)
        for shape_index, (name, shape) in enumerate(zip(NAMES, shapes)):
            ox = shape_index % 2 * 640
            oy = shape_index // 2 * 480
            for x, y, size, color, visible in shape:
                if visible:
                    draw_ball(draw, ox + x, oy + y, size, color)
            draw.text((ox + 20, oy + 14), f"{name} / {VISIBLE_COUNTS[shape_index]} BALLS",
                      fill=(175, 199, 216))
        preview.save(ASSETS / "xga_morph_shapes_preview.png")

    def show_mapping(shape_index):
        debug = Image.new("RGB", (1280, 480), (3, 8, 13))
        debug_draw = ImageDraw.Draw(debug)
        for panel, target_index in enumerate((shape_index, (shape_index + 1) % len(shapes))):
            ox = panel * 640
            debug_draw.text((ox + 20, 14), NAMES[target_index], fill=(175, 199, 216))
            for index, (x, y, size, color, visible) in enumerate(shapes[target_index]):
                if visible:
                    draw_ball(debug_draw, ox + x, y, size, color)
            for index in range(0, COUNT, 16):
                x, y, _, _, visible = shapes[target_index][index]
                px = ox + x
                debug_draw.ellipse((px - 3, y - 3, px + 3, y + 3),
                                   fill=(255, 247, 151) if visible else (156, 162, 173))
                debug_draw.text((px + 5, y - 13), str(index), fill=(255, 247, 151),
                                stroke_width=1, stroke_fill=(0, 0, 0))
        debug.save(ASSETS / "xga_morph_mapping_debug.png")

    if args.debug_target:
        show_mapping(NAMES.index(args.debug_target))
    elif args.step_targets:
        for shape_index in range(len(shapes)):
            show_mapping(shape_index)
            input(f"{NAMES[shape_index]} complete; press Enter for the next target...")

print(f"Generated five morph shapes with {VISIBLE_COUNTS} visible balls and twelve colors")
