"""Change only the printed JO in all nine pages of the 26092REV01 RFQ PDF."""

from __future__ import annotations

from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import DecodedStreamObject, NameObject


SOURCE = Path(
    r"Z:\B2_EXTERNAL\BACK UP PROJECT WORKS\5. งานแบบdrawing"
    r"\6. ใบขอราคา\2569"
    r"\BU2-DE-26092REV01_โครงการ MRT PURPLE LINE 4 STATION BELOW GROUND.pdf"
)
OUT_DIR = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา\outputs\jo_26092rev01")
OUTPUT = OUT_DIR / (
    "BU2-DE-26092REV01_โครงการ MRT PURPLE LINE 4 STATION BELOW GROUND"
    "_JO-PJ25-031.pdf"
)

# The PDF has CID-encoded text. Replace its one precisely identified TJ string
# on each page, preserving font, kerning, placement, and all other page content.
OLD = (
    b"[<0033>-0.146484<002D>-0.636719<0015>-6.000000<0019>-0.501953"
    b"<0010>8.000000<0013>-0.501953<0013>-6.000000<001B>-0.501953] TJ"
)
NEW = (
    b"[<0033>-0.146484<002D>-0.636719<0015>-6.000000<0018>-0.501953"
    b"<0010>8.000000<0013>-0.501953<0016>-6.000000<0014>-0.501953] TJ"
)


def main() -> None:
    reader = PdfReader(SOURCE)
    if len(reader.pages) != 9 or reader.get_fields():
        raise ValueError("Unexpected source PDF structure")
    if any((page.extract_text() or "").count("PJ26-008") != 1 for page in reader.pages):
        raise ValueError("The old JO is not present exactly once on every page")

    writer = PdfWriter()
    writer.clone_document_from_reader(reader)
    for number, page in enumerate(writer.pages, 1):
        data = page.get_contents().get_data()
        if data.count(OLD) != 1:
            raise ValueError(f"Page {number}: JO content pattern changed")
        replacement = DecodedStreamObject()
        replacement.set_data(data.replace(OLD, NEW, 1))
        page[NameObject("/Contents")] = writer._add_object(replacement.flate_encode())

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("wb") as stream:
        writer.write(stream)
    print(f"OUTPUT={OUTPUT}")
    print("PAGES=9 JO_REPLACEMENTS=9")


if __name__ == "__main__":
    main()
