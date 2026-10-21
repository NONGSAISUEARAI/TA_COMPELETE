from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "12_scan"
OUTPUT = ROOT / "12_contacts"
OUTPUT.mkdir(exist_ok=True)

DRAWINGS = [
    1, 2, 7, 9, 10, *range(14, 20), 22, *range(29, 32), 35, 42, 44,
    48, 49, 51, 56, 58, 61, 62, 65, 66, 88, *range(106, 110), 114,
    117, 129, 131, 133, 134, 135, 136, 139, 143, 144, 145,
    *range(167, 171),
]

font = ImageFont.truetype("arial.ttf", 34)
crop_box = (650, 220, 3070, 1530)
tile_size = (1500, 812)

for group_index in range(0, len(DRAWINGS), 3):
    numbers = DRAWINGS[group_index: group_index + 3]
    sheet = Image.new("RGB", (tile_size[0], tile_size[1] * len(numbers)), "white")
    for row, number in enumerate(numbers):
        image = Image.open(SOURCE / f"page-{number:03d}.jpg").convert("RGB")
        crop = image.crop(crop_box)
        crop.thumbnail((tile_size[0], tile_size[1] - 42), Image.Resampling.LANCZOS)
        tile = Image.new("RGB", tile_size, "white")
        tile.paste(crop, ((tile_size[0] - crop.width) // 2, 42))
        draw = ImageDraw.Draw(tile)
        draw.text((10, 3), f"PART-{number:03d}", fill="red", font=font)
        sheet.paste(tile, (0, row * tile_size[1]))
    first, last = numbers[0], numbers[-1]
    sheet.save(OUTPUT / f"parts-{first:03d}-{last:03d}.jpg", quality=92)

print(f"created {(len(DRAWINGS) + 2) // 3} contact sheets")
