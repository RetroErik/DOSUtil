"""Recover the original demo files from the known working FAT12 image."""

from pathlib import Path
import hashlib
import struct

demo = Path(__file__).resolve().parents[2]
image_path = demo / "bin/dreams_xga_20260926_200009.img"
image = image_path.read_bytes()
assert len(image) == 1_474_560 and image[510:512] == b"\x55\xaa"

bytes_per_sector = struct.unpack_from("<H", image, 11)[0]
sectors_per_cluster = image[13]
reserved = struct.unpack_from("<H", image, 14)[0]
fats = image[16]
root_entries = struct.unpack_from("<H", image, 17)[0]
sectors_per_fat = struct.unpack_from("<H", image, 22)[0]
assert (bytes_per_sector, sectors_per_cluster, reserved, fats,
        root_entries, sectors_per_fat) == (512, 1, 1, 2, 224, 9)

root_start = (reserved + fats * sectors_per_fat) * bytes_per_sector
data_start = root_start + root_entries * 32
fat_start = reserved * bytes_per_sector


def next_cluster(cluster):
    offset = fat_start + cluster * 3 // 2
    pair = struct.unpack_from("<H", image, offset)[0]
    return (pair >> 4 if cluster & 1 else pair) & 0xfff


def recover(name):
    entries = range(root_start, root_start + root_entries * 32, 32)
    entry = next(pos for pos in entries if image[pos:pos + 11] == name)
    size = struct.unpack_from("<I", image, entry + 28)[0]
    cluster = struct.unpack_from("<H", image, entry + 26)[0]
    chunks = []
    seen = set()
    while 2 <= cluster < 0xff8:
        assert cluster not in seen
        seen.add(cluster)
        offset = data_start + (cluster - 2) * bytes_per_sector
        chunks.append(image[offset:offset + bytes_per_sector])
        cluster = next_cluster(cluster)
    payload = b"".join(chunks)[:size]
    assert len(payload) == size
    return payload


files = {
    b"CONFIG  SYS": "CONFIG.SYS",
    b"AUTOEXECBAT": "AUTOEXEC.BAT",
    b"BUILD   TXT": "BUILD.TXT",
    b"DREAMS  COM": "DREAMS.COM",
    b"DBLIT   COM": "DBLIT.COM",
    b"DCPU    COM": "DCPU.COM",
    b"DREAMS  DAT": "DREAMS.DAT",
}
out_dir = demo / "bin/restored_200009"
out_dir.mkdir(exist_ok=True)
for fat_name, filename in files.items():
    payload = recover(fat_name)
    (out_dir / filename).write_bytes(payload)
    if filename.endswith((".COM", ".DAT")):
        (demo / "bin" / filename).write_bytes(payload)
    print(filename, len(payload), hashlib.sha256(payload).hexdigest())
