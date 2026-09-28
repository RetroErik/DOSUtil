"""Copy the VM's DOS 6.22 boot disk and add the three XGA COM builds.

The original disk is never edited.
"""
from pathlib import Path
import argparse
import struct

parser = argparse.ArgumentParser()
parser.add_argument("--program", choices=("PANORAMA", "PANBLT", "TESTMODE", "TESTBLT"), default="PANORAMA")
parser.add_argument("--output", default="xga_dos622.img")
args = parser.parse_args()
here = Path(__file__).resolve().parent
source = Path(r"D:\86Box-Windows-64-b8200\Dos622-1 With PalmZip.img")
target = here / "bin" / args.output
disk = bytearray(source.read_bytes())
bps = struct.unpack_from("<H", disk, 11)[0]
spc = disk[13]
reserved = struct.unpack_from("<H", disk, 14)[0]
nfats = disk[16]
roots = struct.unpack_from("<H", disk, 17)[0]
spf = struct.unpack_from("<H", disk, 22)[0]
assert (len(disk), bps, spc, reserved, nfats, roots, spf) == (
    737280, 512, 2, 1, 2, 112, 3
)
fat0 = reserved * bps
root0 = (reserved + nfats * spf) * bps
data0 = root0 + roots * 32
cluster_bytes = spc * bps
max_cluster = 2 + (len(disk) - data0) // cluster_bytes


def fat_get(cluster):
    off = fat0 + cluster * 3 // 2
    word = disk[off] | disk[off + 1] << 8
    return (word >> 4 if cluster & 1 else word) & 0xFFF


def fat_set(cluster, value):
    for fat in range(nfats):
        off = (reserved + fat * spf) * bps + cluster * 3 // 2
        word = disk[off] | disk[off + 1] << 8
        if cluster & 1:
            word = (word & 0x000F) | (value << 4)
        else:
            word = (word & 0xF000) | value
        struct.pack_into("<H", disk, off, word)


def add(name, data):
    assert len(name) == 11
    entries = [root0 + i * 32 for i in range(roots)]
    assert not any(disk[p:p + 11] == name for p in entries)
    entry = next(p for p in entries if disk[p] in (0, 0xE5))
    need = (len(data) + cluster_bytes - 1) // cluster_bytes
    clusters = [c for c in range(2, max_cluster) if fat_get(c) == 0][:need]
    assert len(clusters) == need
    for i, c in enumerate(clusters):
        fat_set(c, clusters[i + 1] if i + 1 < need else 0xFFF)
        chunk = data[i * cluster_bytes:(i + 1) * cluster_bytes]
        off = data0 + (c - 2) * cluster_bytes
        disk[off:off + len(chunk)] = chunk
    disk[entry:entry + 11] = name
    disk[entry + 11] = 0x20
    struct.pack_into("<H", disk, entry + 26, clusters[0])
    struct.pack_into("<I", disk, entry + 28, len(data))
    print(name.decode(), len(data), "bytes", len(clusters), "clusters")


for dos_name, path in (
    (b"TESTMODECOM", "test_xga_mode.COM"),
    (b"TESTBLT COM", "test_xga_blit.COM"),
    (b"PANORAMACOM", "xga_panorama.COM"),
    (b"PANBLT  COM", "xga_panblt.COM"),
):
    add(dos_name, (here / "bin" / path).read_bytes())

# The source is the DOS 6.22 setup floppy. Replace its small AUTOEXEC.BAT in
# this copy so it boots straight into the panorama instead of DOS Setup.
entry = next(
    root0 + i * 32 for i in range(roots)
    if disk[root0 + i * 32:root0 + i * 32 + 11] == b"AUTOEXECBAT"
)
cluster = struct.unpack_from("<H", disk, entry + 26)[0]
assert fat_get(cluster) >= 0xFF8  # original AUTOEXEC fits one cluster
boot_script = ("@echo off\r\necho boot>AUTOBOOT.TXT\r\n" + args.program + "\r\n").encode("ascii")
offset = data0 + (cluster - 2) * cluster_bytes
disk[offset:offset + cluster_bytes] = boot_script.ljust(cluster_bytes, b"\x00")
struct.pack_into("<I", disk, entry + 28, len(boot_script))

target.write_bytes(disk)
print(target)
