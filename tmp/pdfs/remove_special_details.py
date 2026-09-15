from pathlib import Path
import subprocess
from collections import Counter

import pdfplumber
from PIL import Image, ImageDraw


ROOT = Path(r"C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE")
PYTHON_BIN = Path(r"C:\Users\tawan.t\.cache\codex-runtimes\codex-primary-runtime\dependencies\python")
PDFTOPPM = PYTHON_BIN / "Library" / "bin" / "pdftoppm.exe"
if not PDFTOPPM.exists():
    PDFTOPPM = Path("pdftoppm")

JOBS = [
    (
        Path(r"C:\Users\tawan.t\Downloads\BU2-DE-26080_โครงการ MRT PURPLE LINE 4 STATION C02(1).pdf"),
        ROOT / "output" / "pdf" / "BU2-DE-26080_โครงการ MRT PURPLE LINE 4 STATION C02_เหลือรายการ1เท่านั้น.pdf",
        ROOT / "tmp" / "pdfs" / "edited_c02",
    ),
    (
        Path(r"C:\Users\tawan.t\Downloads\BU2-DE-26081_โครงการ MRT PURPLE LINE 4 STATION C03(1).pdf"),
        ROOT / "output" / "pdf" / "BU2-DE-26081_โครงการ MRT PURPLE LINE 4 STATION C03_เหลือรายการ1เท่านั้น.pdf",
        ROOT / "tmp" / "pdfs" / "edited_c03",
    ),
]


def edit_pdf(source: Path, output: Path, work: Path) -> int:
    work.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    prefix = work / "page"

    subprocess.run(
        [str(PDFTOPPM), "-png", "-r", "300", "-f", "1", "-singlefile", str(source), str(prefix)],
        check=True,
    )

    png = prefix.with_suffix(".png")
    image = Image.open(png).convert("RGB")
    draw = ImageDraw.Draw(image)

    with pdfplumber.open(source) as pdf:
        page = pdf.pages[0]
        sx = image.width / float(page.width)
        sy = image.height / float(page.height)
        targets = [
            word
            for word in page.extract_words()
            if float(word["top"]) >= 121.0
            and float(word["bottom"]) <= 321.0
            and float(word["x0"]) > 20.0
        ]

    # Clear every cell interior in rows 2-21. Filling complete cell interiors also
    # removes leader lines and symbols that the PDF text extractor cannot identify.
    x_edges_pt = [
        7.5, 21.7, 177.9, 186.9, 247.7, 270.35, 322.0, 347.27,
        372.47, 397.6, 423.73, 449.77, 475.81, 501.85, 537.4,
        579.73, 619.48, 650.7, 673.4, 691.7, 710.1, 738.8, 784.5,
    ]
    inset_pt = 0.45
    table_rows = [
        [122.0 + 9.96 * i for i in range(21)],   # Top table: rows 2-21
        [351.85 + 9.96 * i for i in range(12)], # Bottom table: rows 1-11
    ]
    for y_edges_pt in table_rows:
      for row in range(len(y_edges_pt) - 1):
       for col in range(1, len(x_edges_pt) - 1):
            left = x_edges_pt[col]
            right = x_edges_pt[col + 1]
            top = y_edges_pt[row]
            bottom = y_edges_pt[row + 1]
            x0 = int((left + inset_pt) * sx)
            y0 = int((top + inset_pt) * sy)
            x1 = int((right - inset_pt) * sx)
            y1 = int((bottom - inset_pt) * sy)
            samples = [
                image.getpixel((x, y))
                for x in range(x0 + 2, max(x0 + 3, x1 - 1), 3)
                for y in range(y0 + 2, max(y0 + 3, y1 - 1), 3)
            ]
            light_samples = [color for color in samples if sum(color) > 600]
            fill_color = Counter(light_samples or samples).most_common(1)[0][0]
            draw.rectangle((x0, y0, x1, y1), fill=fill_color)

    image.save(output, "PDF", resolution=300.0, quality=95)
    image.save(work / "final-page-1.png", "PNG")
    return len(targets)


if __name__ == "__main__":
    for source_path, output_path, work_path in JOBS:
        count = edit_pdf(source_path, output_path, work_path)
        print(f"job complete: removed {count} text fragments")
