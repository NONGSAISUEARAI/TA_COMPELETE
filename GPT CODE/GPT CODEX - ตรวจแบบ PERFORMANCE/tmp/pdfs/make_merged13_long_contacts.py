from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "merged13_scan"
OUTPUT = ROOT / "merged13_long_contacts"
OUTPUT.mkdir(exist_ok=True)

font = ImageFont.truetype("arial.ttf", 30)
tile_w, tile_h = 1400, 205
crop_box = (0, 1010, 2750, 1350)

for first in range(1, 171, 10):
    numbers = list(range(first, min(first + 10, 171)))
    sheet = Image.new("RGB", (tile_w * 2, tile_h * 5), "white")
    for index, number in enumerate(numbers):
        image = Image.open(SOURCE / f"page-{number:03d}.jpg").convert("RGB")
        crop = image.crop(crop_box)
        crop.thumbnail((tile_w, tile_h - 32), Image.Resampling.LANCZOS)
        tile = Image.new("RGB", (tile_w, tile_h), "white")
        tile.paste(crop, ((tile_w - crop.width) // 2, 32))
        ImageDraw.Draw(tile).text((8, 0), f"PART-{number:03d}", fill="red", font=font)
        sheet.paste(tile, ((index % 2) * tile_w, (index // 2) * tile_h))
    sheet.save(OUTPUT / f"parts-{numbers[0]:03d}-{numbers[-1]:03d}.jpg", quality=93)

print(len(list(OUTPUT.glob("*.jpg"))))
