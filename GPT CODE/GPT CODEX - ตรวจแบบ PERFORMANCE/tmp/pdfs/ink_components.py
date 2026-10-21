import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


root = Path(__file__).resolve().parent
scan_dir = root / "merged10_scan"
analysis = {item["pdf_page"]: item for item in json.loads((root / "merged10_analysis.json").read_text(encoding="utf-8"))}


def find_components(mask):
    points = set(map(tuple, np.argwhere(mask)))
    components = []
    while points:
        start = points.pop()
        queue = deque([start])
        ys, xs = [start[0]], [start[1]]
        while queue:
            y, x = queue.popleft()
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    if not dx and not dy:
                        continue
                    neighbour = (y + dy, x + dx)
                    if neighbour in points:
                        points.remove(neighbour)
                        queue.append(neighbour)
                        ys.append(neighbour[0])
                        xs.append(neighbour[1])
        if len(xs) >= 6:
            components.append(
                {
                    "pixels": len(xs),
                    "bbox_raw": [int(min(xs)), int(min(ys)), int(max(xs)), int(max(ys))],
                }
            )
    return sorted(components, key=lambda item: item["pixels"], reverse=True)


records = []
for path in sorted(scan_dir.glob("page-*.png")):
    page = int(path.stem.split("-")[-1])
    image = np.asarray(Image.open(path).convert("RGB"))
    red = image[:, :, 0].astype(int)
    green = image[:, :, 1].astype(int)
    blue = image[:, :, 2].astype(int)
    maximum = np.maximum.reduce([red, green, blue])
    minimum = np.minimum.reduce([red, green, blue])
    saturation = (maximum - minimum) / (maximum + 1)
    red_ink = (
        (saturation > 0.22)
        & (red > 75)
        & (red > green * 1.14)
        & (red > blue * 1.08)
    )
    blue_ink = (
        (saturation > 0.22)
        & (blue > 60)
        & (blue > red * 1.10)
        & (blue > green)
    )
    red_ink[:280, :] = False
    blue_ink[:280, :] = False
    components = find_components(red_ink) + find_components(blue_ink)
    records.append(
        {
            "pdf_page": page,
            "drawing": analysis[page]["drawing"],
            "components": sorted(components, key=lambda item: item["pixels"], reverse=True),
        }
    )

(root / "merged10_ink_components.json").write_text(
    json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8"
)
for record in records:
    if record["components"]:
        print(record["pdf_page"], record["drawing"], record["components"])
