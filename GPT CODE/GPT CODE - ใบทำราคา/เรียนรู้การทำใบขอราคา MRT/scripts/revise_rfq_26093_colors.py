"""Revise 26093 colors and PP17 quantity while preserving its native XLSM parts."""

from __future__ import annotations

import copy
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from lxml import etree
from openpyxl import load_workbook

from build_rfq_native_controls import S, xml_bytes


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
SOURCE = Path(
    r"Z:\B2_EXTERNAL\BACK UP PROJECT WORKS\5. งานแบบdrawing"
    r"\6. ใบขอราคา\2569"
    r"\BU2-DE-26093 - MRT PURPLE LINE 4STATION (PP17 - PP20)_20261009-0938.xlsm"
)
NOW = datetime.now(timezone.utc).astimezone(timezone(timedelta(hours=7)))
OUT_DIR = ROOT / "outputs" / f"rfq_26093_color_revision_{NOW:%Y%m%d}"
OUT = OUT_DIR / (
    "BU2-DE-26093 - MRT PURPLE LINE 4STATION (PP17 - PP20)_"
    f"{NOW:%Y%m%d-%H%M}.xlsm"
)

COLORS = {
    7: "PA-1M-U0139",  # PP17
    8: "PA-1S-G0309",  # PP18
    9: "PA-1S-E0116",  # PP19
    10: "PA-2S-W0803",  # PP20
}


def clear(cell: etree._Element) -> None:
    cell.attrib.pop("t", None)
    for child in list(cell):
        if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
            cell.remove(child)


def set_text(cell: etree._Element, value: str) -> None:
    clear(cell)
    cell.set("t", "inlineStr")
    inline = etree.SubElement(cell, f"{{{S}}}is")
    etree.SubElement(inline, f"{{{S}}}t").text = value


def set_number(cell: etree._Element, value: int) -> None:
    clear(cell)
    etree.SubElement(cell, f"{{{S}}}v").text = str(value)


def main() -> None:
    book = load_workbook(SOURCE, read_only=True, data_only=False)
    sheet = book.worksheets[0]
    expected = {
        "Z1": "BU2-DE-26093",
        "S7": "NS-1S-P0070",
        "S8": "SA-05611",
        "S9": "NS-1S-E0114",
        "P10": "SD-9103",
    }
    for address, value in expected.items():
        if sheet[address].value != value:
            raise ValueError(f"Source changed at {address}; stop and inspect current workbook")
    if sheet["W7"].value is not None:
        raise ValueError("PP17 quantity already filled; stop rather than overwrite")
    book.close()

    with zipfile.ZipFile(SOURCE, "r") as source:
        name = "xl/worksheets/sheet1.xml"
        root = etree.fromstring(source.read(name))
        data = root.find(f"{{{S}}}sheetData")
        if data is None:
            raise ValueError("Missing sheetData")
        cells = {
            cell.get("r"): cell
            for row in data
            for cell in row
            if cell.tag == f"{{{S}}}c"
        }
        for row, color in COLORS.items():
            set_text(cells[f"S{row}"], color)
            set_text(cells[f"U{row}"], "Cornel")
        clear(cells["P10"])  # PP20 is no longer standard SD-9103.
        set_number(cells["W7"], 415)

        OUT_DIR.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(OUT, "w") as target:
            for info in source.infolist():
                payload = xml_bytes(root) if info.filename == name else source.read(info.filename)
                target.writestr(copy.copy(info), payload)

    print("OUTPUT_SAVED=1")
    print("COLORS=4 PP17_QUANTITY=415 PDF_CREATED=0")


if __name__ == "__main__":
    main()
