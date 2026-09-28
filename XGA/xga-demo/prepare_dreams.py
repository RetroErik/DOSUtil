"""Make an indexed XGA image from the user's original Dreams BMP.

DREAMS.DAT is 768 RGB palette bytes followed by 960*640 palette indices.
Keep this conversion deterministic so the DOS build can be reproduced.
"""
from pathlib import Path
import shutil
import subprocess
import zlib
from PIL import Image

here = Path(__file__).resolve().parent
source = here / "assets" / "Dreams.bmp"
preview = here / "assets" / "Dreams-XGA-preview.png"
target = here / "bin" / "DREAMS.DAT"
magick = Path(r"D:\ImageMagick-7.1.2-13-portable-Q16-x64\magick.exe")
if not magick.exists():
    found = shutil.which("magick")
    if not found:
        raise FileNotFoundError("ImageMagick magick.exe was not found")
    magick = Path(found)

assert Image.open(source).size == (1536, 1024)
subprocess.run([
    str(magick), str(source), "-alpha", "off", "-filter", "Lanczos",
    "-resize", "960x640!", "+dither", "-colors", "256", "-depth", "8",
    "-type", "Palette", f"PNG8:{preview}",
], check=True)
indexed = Image.open(preview)
assert indexed.mode == "P" and indexed.size == (960, 640)
palette = bytes(indexed.getpalette()[:768]).ljust(768, b"\x00")
pixels = indexed.tobytes()
assert len(palette) == 768 and len(pixels) == 960 * 640
target.write_bytes(palette + pixels)
brightest = max(range(256), key=lambda i: sum(palette[3*i:3*i+3]))
(here / "dreams_asset.inc").write_text(
    f"; Generated from Dreams.bmp by prepare_dreams.py\n"
    f"IMAGE_CRC equ 0x{zlib.crc32(pixels):08x}\n"
    f"PROGRESS_COLOR equ {brightest}\n"
    f"IMAGE_FIRST equ {pixels[0]}\n"
    f"IMAGE_MIDDLE equ {pixels[len(pixels)//2]}\n"
    f"IMAGE_LAST equ {pixels[-1]}\n",
    encoding="ascii",
)
print(f"{source.name} -> {preview.name}, {target.name} ({target.stat().st_size} bytes)")
