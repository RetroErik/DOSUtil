"""Create a bootable 1.44 MB DOS 6.22 Dreams demo disk.

Clone the user's DOS 6.22 image, retain its boot files, remove its setup
utilities in the clone, and add the XGA programs plus the indexed artwork.
The source image is never modified.
"""
from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
import struct

parser = ArgumentParser()
parser.add_argument("--program", choices=("DREAMS", "DBLIT", "DCPU"),
                    default="DREAMS")
parser.add_argument("--output", help="output filename (default: build timestamp)")
args = parser.parse_args()
build_time = datetime.now().astimezone()
if args.output is None:
    args.output = f"dreams_xga_{build_time:%Y%m%d_%H%M%S}.img"
fat_date = ((build_time.year - 1980) << 9) | (build_time.month << 5) | build_time.day
fat_time = (build_time.hour << 11) | (build_time.minute << 5) | (build_time.second // 2)

here = Path(__file__).resolve().parent
source = Path(r"D:\86Box-Windows-64-b8200\Dos622-1.img")
target = here / "bin" / args.output
disk = bytearray(source.read_bytes())

bps = struct.unpack_from("<H", disk, 11)[0]
spc = disk[13]
reserved = struct.unpack_from("<H", disk, 14)[0]
nfats = disk[16]
roots = struct.unpack_from("<H", disk, 17)[0]
spf = struct.unpack_from("<H", disk, 22)[0]
assert (len(disk), bps, spc, reserved, nfats, roots, spf) == (
    1474560, 512, 1, 1, 2, 224, 9
)
assert disk[510:512] == b"\x55\xaa"
root0 = (reserved + nfats * spf) * bps
data0 = root0 + roots * 32
cluster_bytes = spc * bps
max_cluster = 2 + (len(disk) - data0) // cluster_bytes


def fat_get(cluster):
    off = reserved * bps + cluster * 3 // 2
    word = disk[off] | disk[off + 1] << 8
    return (word >> 4 if cluster & 1 else word) & 0xfff


def fat_set(cluster, value):
    for fat in range(nfats):
        off = (reserved + fat * spf) * bps + cluster * 3 // 2
        word = disk[off] | disk[off + 1] << 8
        if cluster & 1:
            word = (word & 0x000f) | (value << 4)
        else:
            word = (word & 0xf000) | value
        struct.pack_into("<H", disk, off, word)


def root_slots():
    return range(root0, root0 + roots * 32, 32)


keep = {b"IO      SYS", b"MSDOS   SYS", b"COMMAND COM"}
original = bytes(disk)
for entry in root_slots():
    name = bytes(disk[entry:entry + 11])
    if disk[entry] in (0, 0xe5) or name in keep or disk[entry + 11] & 0x08:
        continue
    cluster = struct.unpack_from("<H", disk, entry + 26)[0]
    seen = set()
    while 2 <= cluster < max_cluster:
        assert cluster not in seen, name
        seen.add(cluster)
        following = fat_get(cluster)
        fat_set(cluster, 0)
        if following >= 0xff8:
            break
        cluster = following
    disk[entry] = 0xe5


inserted = {}


def add(name, payload):
    assert len(name) == 11 and payload
    assert not any(disk[p:p + 11] == name for p in root_slots())
    entry = next(p for p in root_slots() if disk[p] in (0, 0xe5))
    needed = (len(payload) + cluster_bytes - 1) // cluster_bytes
    clusters = [c for c in range(2, max_cluster) if fat_get(c) == 0][:needed]
    assert len(clusters) == needed, (name, needed, len(clusters))
    for i, cluster in enumerate(clusters):
        fat_set(cluster, clusters[i + 1] if i + 1 < needed else 0xfff)
        chunk = payload[i * cluster_bytes:(i + 1) * cluster_bytes]
        off = data0 + (cluster - 2) * cluster_bytes
        disk[off:off + len(chunk)] = chunk
    disk[entry:entry + 32] = b"\x00" * 32
    disk[entry:entry + 11] = name
    disk[entry + 11] = 0x20
    disk[entry + 13] = ((build_time.second % 2) * 100
                        + build_time.microsecond // 10000)
    struct.pack_into("<H", disk, entry + 14, fat_time)  # created
    struct.pack_into("<H", disk, entry + 16, fat_date)
    struct.pack_into("<H", disk, entry + 18, fat_date)  # last accessed
    struct.pack_into("<H", disk, entry + 22, fat_time)  # DOS DIR uses these
    struct.pack_into("<H", disk, entry + 24, fat_date)
    struct.pack_into("<H", disk, entry + 26, clusters[0])
    struct.pack_into("<I", disk, entry + 28, len(payload))
    inserted[name] = payload
    print(name.decode("ascii"), len(payload), "bytes")


add(b"CONFIG  SYS", b"FILES=20\r\nBUFFERS=10\r\n")
add(b"AUTOEXECBAT", ("@echo off\r\n" + args.program + "\r\n").encode("ascii"))
add(b"BUILD   TXT", (
    f"Dreams XGA build: {build_time:%Y-%m-%d %H:%M:%S %z}\r\n"
    f"Autoexec program: {args.program}.COM\r\n"
).encode("ascii"))
for name, path in (
    (b"DREAMS  COM", "DREAMS.COM"),
    (b"DBLIT   COM", "DBLIT.COM"),
    (b"DCPU    COM", "DCPU.COM"),
    (b"DREAMS  DAT", "DREAMS.DAT"),
):
    add(name, (here / "bin" / path).read_bytes())

assert all(disk[reserved * bps + i] == disk[(reserved + spf) * bps + i]
           for i in range(spf * bps))


def read_file(image, name):
    entry = next(p for p in root_slots() if image[p:p + 11] == name)
    size = struct.unpack_from("<I", image, entry + 28)[0]
    cluster = struct.unpack_from("<H", image, entry + 26)[0]
    chunks = []
    seen = set()
    while 2 <= cluster < max_cluster:
        assert cluster not in seen, name
        seen.add(cluster)
        off = data0 + (cluster - 2) * cluster_bytes
        chunks.append(image[off:off + cluster_bytes])
        fat_off = reserved * bps + cluster * 3 // 2
        word = image[fat_off] | image[fat_off + 1] << 8
        following = (word >> 4 if cluster & 1 else word) & 0xfff
        if following >= 0xff8:
            break
        cluster = following
    return b"".join(chunks)[:size]


for name in keep:
    assert read_file(disk, name) == read_file(original, name), name
for name, payload in inserted.items():
    assert read_file(disk, name) == payload, name
    entry = next(p for p in root_slots() if disk[p:p + 11] == name)
    assert struct.unpack_from("<HH", disk, entry + 22) == (fat_time, fat_date)

target.write_bytes(disk)
print(f"Build time: {build_time:%Y-%m-%d %H:%M:%S %z}")
print(target)
