"""Extract the 640x480x256 register sequence from the supplied XGAKIT.ASM.

The table is deliberately generated from the toolkit rather than transcribed:
each record contains I/O offset, indexed register (0 for direct I/O), value.
"""
from pathlib import Path
import re

here = Path(__file__).resolve().parent
toolkit = here.parent / "XGA Toolkit" / "XGAKIT.ASM"
text = toolkit.read_text(encoding="latin-1")
table = "xga_val\tdb" + text.split("xga_val\tdb", 1)[1].split("; end of the list", 1)[0]
records = []
for line in table.splitlines():
    values = re.findall(r"\b([0-9a-f]+)h\b", line, re.I)
    if len(values) != 9:
        continue
    nums = [int(v, 16) for v in values]
    if nums[0] == 0xFF:
        break
    if nums[0] == 0x0A:
        records.append((nums[0], nums[1], nums[4]))
    else:
        records.append((nums[0], 0, nums[4]))

assert len(records) > 45, len(records)
out = here / "xga_mode_640.inc"
out.write_text(
    "; Generated from XGA Toolkit/XGAKIT.ASM by build_mode_table.py.\n"
    "; Entries: I/O offset, register index (0 for direct), value.\n"
    + "mode_table:\n"
    + "\n".join(f"    db 0x{p:02x}, 0x{i:02x}, 0x{v:02x}" for p, i, v in records)
    + "\n    db 0xff, 0, 0\n",
    encoding="ascii",
)
print(f"{len(records)} XGA register writes -> {out.name}")
