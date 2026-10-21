from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps


root = Path(__file__).resolve().parent
scan_dir = root / "merged10_scan"
out_dir = root / "merged10_contacts"
out_dir.mkdir(exist_ok=True)


def ink_masks(image):
    array = np.asarray(image.convert("RGB"))
    red = array[:, :, 0].astype(int)
    green = array[:, :, 1].astype(int)
    blue = array[:, :, 2].astype(int)
    maximum = np.maximum.reduce([red, green, blue])
    minimum = np.minimum.reduce([red, green, blue])
    saturation = (maximum - minimum) / (maximum + 1)
    red_ink = (
        (saturation > 0.25)
        & (red > 80)
        & (red > green * 1.18)
        & (red > blue * 1.10)
    )
    blue_ink = (
        (saturation > 0.25)
        & (blue > 65)
        & (blue > red * 1.14)
        & (blue > green * 1.01)
    )
    red_ink[:280, :] = False
    blue_ink[:280, :] = False
    return red_ink, blue_ink


thumb_w, thumb_h = 420, 297
label_h = 24
cols, rows = 3, 3
paths = sorted(scan_dir.glob("page-*.png"))

for start in range(0, len(paths), cols * rows):
    batch = paths[start : start + cols * rows]
    first = int(batch[0].stem.split("-")[-1])
    last = int(batch[-1].stem.split("-")[-1])
    output_path = out_dir / f"pages-{first:03d}-{last:03d}.jpg"
    if output_path.exists():
        continue
    sheet = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + label_h)), "white")
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(batch):
        image = Image.open(path).convert("RGB")
        red_ink, blue_ink = ink_masks(image)

        gray = ImageOps.grayscale(image).convert("RGB")
        gray = Image.blend(Image.new("RGB", gray.size, "white"), gray, 0.50)
        red_mask = Image.fromarray(red_ink.astype("uint8") * 255).filter(ImageFilter.MaxFilter(5))
        blue_mask = Image.fromarray(blue_ink.astype("uint8") * 255).filter(ImageFilter.MaxFilter(5))
        gray.paste((255, 0, 0), mask=red_mask)
        gray.paste((0, 70, 255), mask=blue_mask)

        upright = gray.transpose(Image.Transpose.ROTATE_90)
        upright.thumbnail((thumb_w, thumb_h))
        cell_x = (index % cols) * thumb_w
        cell_y = (index // cols) * (thumb_h + label_h)
        x = cell_x + (thumb_w - upright.width) // 2
        y = cell_y + label_h
        sheet.paste(upright, (x, y))
        page_no = int(path.stem.split("-")[-1])
        draw.rectangle((cell_x, cell_y, cell_x + thumb_w, cell_y + label_h), fill="white")
        draw.text((cell_x + 8, cell_y + 4), f"PDF PAGE {page_no}", fill="black")
    sheet.save(output_path, quality=94)
