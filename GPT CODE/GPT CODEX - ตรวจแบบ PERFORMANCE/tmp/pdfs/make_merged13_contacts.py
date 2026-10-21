from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "merged13_scan"
OUTPUT = ROOT / "merged13_contacts"
OUTPUT.mkdir(exist_ok=True)

font = ImageFont.truetype("arial.ttf", 28)
tile_w, tile_h = 600, 445

for first in range(1, 171, 10):
    numbers = list(range(first, min(first + 10, 171)))
    sheet = Image.new("RGB", (tile_w * 5, tile_h * 2), "white")
    for index, number in enumerate(numbers):
        image = Image.open(SOURCE / f"page-{number:03d}.jpg").convert("RGB")
        image.thumbnail((tile_w, tile_h - 28), Image.Resampling.LANCZOS)
        tile = Image.new("RGB", (tile_w, tile_h), "white")
        tile.paste(image, ((tile_w - image.width) // 2, 28))
        draw = ImageDraw.Draw(tile)
        draw.text((8, 0), f"PART-{number:03d}", fill="red", font=font)
        sheet.paste(tile, ((index % 5) * tile_w, (index // 5) * tile_h))
    sheet.save(OUTPUT / f"parts-{numbers[0]:03d}-{numbers[-1]:03d}.jpg", quality=90)

print(len(list(OUTPUT.glob("*.jpg"))))
