import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image
from pypdf import PdfReader


def natural_page_key(path: Path):
    match = re.search(r"-(\d+)\.jpe?g$", path.name, re.IGNORECASE)
    return int(match.group(1)) if match else path.name


def main():
    if len(sys.argv) not in (3, 4):
        raise SystemExit(
            "usage: reduce_pdf_quality_in_place.py <root> <pdftoppm> [start_index]"
        )

    root = Path(sys.argv[1])
    pdftoppm = Path(sys.argv[2]).resolve()
    pdfs = sorted(root.rglob("*.pdf"), key=lambda p: str(p).lower())
    start_index = int(sys.argv[3]) if len(sys.argv) == 4 else 1
    results = []

    for index, source in enumerate(pdfs, start=1):
        if index < start_index:
            continue
        if root not in source.parents:
            raise RuntimeError(f"out-of-scope file: {source}")

        before_size = source.stat().st_size
        before_pages = len(PdfReader(str(source)).pages)

        with tempfile.TemporaryDirectory(prefix="codex_pdf50_") as temp_dir:
            temp = Path(temp_dir)
            image_prefix = temp / "page"
            subprocess.run(
                [
                    str(pdftoppm),
                    "-jpeg",
                    "-r",
                    "150",
                    "-jpegopt",
                    "quality=65,progressive=y,optimize=y",
                    str(source),
                    str(image_prefix),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )

            image_paths = sorted(temp.glob("page-*.jpg"), key=natural_page_key)
            if len(image_paths) != before_pages:
                raise RuntimeError(
                    f"rendered page count mismatch for {source}: "
                    f"expected {before_pages}, got {len(image_paths)}"
                )

            images = []
            try:
                for image_path in image_paths:
                    image = Image.open(image_path)
                    image.load()
                    if image.mode != "RGB":
                        image = image.convert("RGB")
                    images.append(image)

                output = temp / "reduced.pdf"
                images[0].save(
                    output,
                    "PDF",
                    save_all=True,
                    append_images=images[1:],
                    resolution=150.0,
                    quality=65,
                    optimize=True,
                )
            finally:
                for image in images:
                    image.close()

            after_pages = len(PdfReader(str(output)).pages)
            if after_pages != before_pages:
                raise RuntimeError(
                    f"output page count mismatch for {source}: "
                    f"expected {before_pages}, got {after_pages}"
                )
            if output.stat().st_size == 0:
                raise RuntimeError(f"empty output for {source}")

            after_size = output.stat().st_size
            os.replace(output, source)

        row = {
            "index": index,
            "total": len(pdfs),
            "file": str(source),
            "pages": before_pages,
            "before_bytes": before_size,
            "after_bytes": after_size,
        }
        results.append(row)
        print(json.dumps(row, ensure_ascii=False), flush=True)

    summary = {
        "processed": len(results),
        "before_bytes": sum(row["before_bytes"] for row in results),
        "after_bytes": sum(row["after_bytes"] for row in results),
    }
    print("SUMMARY " + json.dumps(summary, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
