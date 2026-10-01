"""Precompute quads whose XGA area outline has an odd scanline boundary.

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parent
PHASES = 512
QUADS_PER_PHASE = 128
BYTES_PER_PHASE = QUADS_PER_PHASE // 8
MAX_AREA_ROW_ERROR = 4


def values(filename, label, count):
    lines = (ROOT / filename).read_text(encoding="utf-8").splitlines()
    start = next(i for i, line in enumerate(lines) if line.strip() == label + ":") + 1
    result = []
    for line in lines[start:]:
        line = line.split(";", 1)[0].strip()
        if line.startswith(("dw ", "db ")):
            result.extend(int(value) for value in line[3:].split(","))
        if len(result) >= count:
            return result[:count]
    raise ValueError(f"{filename}: {label} has fewer than {count} values")


SINE = values("xga_balls_sine.inc", "sine_table", 256)


def signed_word(value):
    return (value + 0x8000) % 0x10000 - 0x8000


def project(vertices, phase):
    sy = SINE[phase & 255]
    cy = SINE[(phase + 64) & 255]
    sx = SINE[((phase >> 1) + 32) & 255]
    cx = SINE[((phase >> 1) + 96) & 255]
    result = []
    for x, y, z in zip(*[iter(vertices)] * 3):
        screen_x = (signed_word(x * cy) >> 7) - (signed_word(z * sy) >> 7)
        rotated_z = (signed_word(x * sy) >> 7) + (signed_word(z * cy) >> 7)
        screen_y = (signed_word(y * cx) >> 7) - (signed_word(rotated_z * sx) >> 7)
        result.append((screen_x, -screen_y))
    return result


def visible(points):
    x0, y0 = points[0]
    x1, y1 = points[1]
    x2, y2 = points[2]
    x3, y3 = points[3]
    cross1 = signed_word((x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0))
    cross2 = signed_word((x2 - x0) * (y3 - y0) - (y2 - y0) * (x3 - x0))
    if (cross1 ^ cross2) < 0 or signed_word(cross1 + cross2) <= 4:
        return False
    width = max(x for x, _ in points) - min(x for x, _ in points)
    height = max(y for _, y in points) - min(y for _, y in points)
    return 1 < width < 128 and 1 < height < 128


def xga_boundary_pixels(start, end):
    """Model XGA's area-boundary Bresenham output in 86Box vid_xga.c."""
    x, y = start
    dx = end[0] - x
    dy = end[1] - y
    sign_x = -1 if dx < 0 else 1
    sign_y = -1 if dy < 0 else 1
    y_major = abs(dy) > abs(dx)
    major = max(abs(dx), abs(dy))
    minor = min(abs(dx), abs(dy))
    error = signed_word(2 * minor - major)
    k1 = 2 * minor
    k2 = 2 * (minor - major)
    for step in range(major + 1):
        remaining = major - step
        endpoint_ok = step > 0 if sign_y < 0 else remaining > 0
        if y_major:
            draw = endpoint_ok
        else:
            draw = endpoint_ok and (error >= 0 if sign_x < 0 else error < k1 + k2)
        if draw:
            yield x, y
        if step == major:
            break
        if y_major:
            y += sign_y
            if error >= 0:
                error = signed_word(error + k2)
                x += sign_x
            else:
                error = signed_word(error + k1)
        else:
            x += sign_x
            if error >= 0:
                error = signed_word(error + k2)
                y += sign_y
            else:
                error = signed_word(error + k1)


def unsafe_outline(points):
    outline = set()
    for start, end in zip(points, points[1:] + points[:1]):
        if start == end:
            continue
        for pixel in xga_boundary_pixels(start, end):
            if pixel in outline:
                outline.remove(pixel)
            else:
                outline.add(pixel)
    row_parity = {}
    for _, y in outline:
        row_parity[y] = row_parity.get(y, 0) ^ 1
    if any(row_parity.values()):
        return True

    min_x = min(x for x, _ in points)
    max_x = max(x for x, _ in points)
    min_y = min(y for _, y in points)
    max_y = max(y for _, y in points)
    left = [128] * (max_y - min_y)
    right = [0] * (max_y - min_y)
    for (x0, y0), (x1, y1) in zip(points, points[1:] + points[:1]):
        if y0 == y1:
            continue
        if y0 > y1:
            x0, x1 = x1, x0
            y0, y1 = y1, y0
        fixed_x = (x0 - min_x) << 16
        numerator = (x1 - x0) << 16
        slope = (abs(numerator) // (y1 - y0)) * (-1 if numerator < 0 else 1)
        for y in range(y0, y1):
            x = max(0, min(max_x - min_x, fixed_x >> 16))
            index = y - min_y
            left[index] = min(left[index], x)
            right[index] = max(right[index], x)
            fixed_x += slope

    # 86Box toggles the area state before writing the current pixel. Thus
    # each boundary pair fills [left, right), and an odd row would run out
    # to the end of the fill box.
    by_row = {}
    for x, y in outline:
        by_row.setdefault(y, []).append(x)
    for y in range(min_y, max_y + 1):
        bits = sorted(by_row.get(y, []))
        actual = set()
        for first, last in zip(bits[::2], bits[1::2]):
            actual.update(range(first, last))
        index = y - min_y
        expected = (set(range(min_x + left[index], min_x + right[index] + 1))
                    if index < len(left) and left[index] <= right[index] else set())
        if len(actual ^ expected) > MAX_AREA_ROW_ERROR:
            return True
    return False


def make_table(mesh_file, vertex_label, quad_label, quad_count, vertex_count=128):
    vertices = values(mesh_file, vertex_label, vertex_count * 3)
    quads = values(mesh_file, quad_label, quad_count * 5)
    table = bytearray(PHASES * BYTES_PER_PHASE)
    unsafe_count = 0
    for phase in range(PHASES):
        screen = project(vertices, phase)
        for index in range(quad_count):
            a, b, c, d, _ = quads[index * 5:index * 5 + 5]
            points = [screen[i] for i in (a, b, c, d)]
            if visible(points) and unsafe_outline(points):
                table[phase * BYTES_PER_PHASE + index // 8] |= 1 << (index & 7)
                unsafe_count += 1
    return table, unsafe_count


def main():
    torus, torus_unsafe = make_table(
        "xga_torus_mesh.inc", "torus_vertices", "torus_quads", 128
    )
    boing, boing_unsafe = make_table(
        "xga_boing_mesh.inc", "boing_vertices", "boing_quads", 112
    )
    crystal, crystal_unsafe = make_table(
        "xga_crystal_mesh.inc", "crystal_vertices", "crystal_quads", 100, 120
    )
    output = ROOT / "xga_area_safety.inc"
    lines = [
        "; XGA area-fill fallback bits: 512 rotation phases, 16 bytes per phase.",
        "; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code",
    ]
    for label, table in (("torus_area_unsafe", torus),
                         ("boing_area_unsafe", boing),
                         ("crystal_area_unsafe", crystal)):
        lines.append(label + ":")
        for offset in range(0, len(table), 16):
            lines.append("    db " + ",".join(f"0x{value:02x}" for value in table[offset:offset + 16]))
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{output.name}: torus {torus_unsafe}, boing {boing_unsafe}, "
          f"crystal {crystal_unsafe} unsafe facets across 512 phases")


if __name__ == "__main__":
    main()
