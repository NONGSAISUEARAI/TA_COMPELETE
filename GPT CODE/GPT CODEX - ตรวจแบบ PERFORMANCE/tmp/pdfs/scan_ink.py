from pathlib import Path

import numpy as np
from PIL import Image


scan_dir = Path(__file__).resolve().parent / "merged10_scan"

for path in sorted(scan_dir.glob("page-*.png")):
    image = np.asarray(Image.open(path).convert("RGB"))
    red = image[:, :, 0].astype(int)
    green = image[:, :, 1].astype(int)
    blue = image[:, :, 2].astype(int)
    maximum = np.maximum.reduce([red, green, blue])
    minimum = np.minimum.reduce([red, green, blue])
    saturation = (maximum - minimum) / (maximum + 1)

    red_ink = (
        (saturation > 0.30)
        & (red > 95)
        & (red > green * 1.25)
        & (red > blue * 1.15)
    )
    blue_ink = (
        (saturation > 0.30)
        & (blue > 75)
        & (blue > red * 1.20)
        & (blue > green * 1.03)
    )

    # Pages are stored 90 degrees counter-clockwise. The title block is the
    # top strip in the raster, so ignore it when looking for review circles.
    main_red = red_ink.copy()
    main_blue = blue_ink.copy()
    main_red[:280, :] = False
    main_blue[:280, :] = False
    red_count = int(main_red.sum())
    blue_count = int(main_blue.sum())
    if red_count > 20 or blue_count > 20:
        def bounds(mask):
            ys, xs = np.where(mask)
            if not len(xs):
                return None
            return [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]

        print(
            path.name,
            "red=", red_count,
            "blue=", blue_count,
            "red_bbox=", bounds(main_red),
            "blue_bbox=", bounds(main_blue),
        )
