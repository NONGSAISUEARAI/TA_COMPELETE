import json
import re
from pathlib import Path

import numpy as np
from PIL import Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parent
PDF = Path(r"C:\Users\tawan.t\Downloads\12.pdf")
IMAGE_DIR = ROOT / "12_scan"


def ink_counts(path: Path):
    image = np.asarray(Image.open(path).convert("RGB"))
    red = image[:, :, 0].astype(int)
    green = image[:, :, 1].astype(int)
    blue = image[:, :, 2].astype(int)
    maximum = np.maximum.reduce([red, green, blue])
    minimum = np.minimum.reduce([red, green, blue])
    saturation = (maximum - minimum) / (maximum + 1)
    red_ink = (
        (saturation > 0.25)
        & (red > 85)
        & (red > green * 1.18)
        & (red > blue * 1.10)
    )
    blue_ink = (
        (saturation > 0.25)
        & (blue > 70)
        & (blue > red * 1.15)
        & (blue > green * 1.02)
    )
    return int(red_ink.sum()), int(blue_ink.sum())


reader = PdfReader(str(PDF))
records = []
for page_no, page in enumerate(reader.pages, 1):
    text = page.extract_text() or ""
    compact = re.sub(r"\s+", "", text)
    drawing_match = re.search(r"PJ25-031-HK-MEP-PART-(\d{3})", compact)
    code_match = re.search(r"(\d{6})HK", compact)
    drawing = int(drawing_match.group(1)) if drawing_match else None
    code = code_match.group(1) if code_match else None
    expected_dims = [int(code[:3]), int(code[3:])] if code else []
    number_tokens = [float(item) for item in re.findall(r"(?<![A-Za-z])\d+(?:\.\d+)?", text)]
    missing_dims = [value for value in expected_dims if float(value) not in number_tokens]
    image_path = IMAGE_DIR / f"page-{page_no:03d}.jpg"
    red_count, blue_count = ink_counts(image_path)
    records.append(
        {
            "pdf_page": page_no,
            "drawing": drawing,
            "part_code": code,
            "expected_dims": expected_dims,
            "missing_primary_dims": missing_dims,
            "red_pixels": red_count,
            "blue_pixels": blue_count,
            "paint_count": len(re.findall(r"Paint", text, flags=re.IGNORECASE)),
            "text": text,
        }
    )

(ROOT / "12_analysis.json").write_text(
    json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8"
)

print("pages", len(records))
print("drawing mismatches", [(r["pdf_page"], r["drawing"]) for r in records if r["drawing"] != r["pdf_page"]])
print("missing drawing/code", [(r["pdf_page"], r["drawing"], r["part_code"]) for r in records if not r["drawing"] or not r["part_code"]])
print("missing primary dims", [(r["drawing"], r["part_code"], r["missing_primary_dims"]) for r in records if r["missing_primary_dims"]])
print("colored ink", [(r["drawing"], r["red_pixels"], r["blue_pixels"]) for r in records if r["red_pixels"] > 20 or r["blue_pixels"] > 20])
print("paint count != 6", [(r["drawing"], r["paint_count"]) for r in records if r["paint_count"] != 6])
