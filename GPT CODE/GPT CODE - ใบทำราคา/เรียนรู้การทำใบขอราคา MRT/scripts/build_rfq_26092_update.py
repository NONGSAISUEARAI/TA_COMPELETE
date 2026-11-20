"""Append the SOLID C06 items to the existing 26092 RFQ without rewriting controls."""

from __future__ import annotations

import copy
import csv
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from lxml import etree
from openpyxl.utils.datetime import to_excel

from build_rfq_native_controls import S, xml_bytes


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
SOURCE = Path(
    r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan"
    r"\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PART.csv"
)
EXISTING = Path(
    r"Z:\B2_EXTERNAL\BACK UP PROJECT WORKS\5. งานแบบdrawing"
    r"\6. ใบขอราคา\2569"
    r"\BU2-DE-26092 - MRT PURPLE LINE 4 STATION BELOW GROUND_20261006-1621.xlsm"
)
NOW = datetime.now(timezone.utc).astimezone(timezone(timedelta(hours=7)))
ISSUE_DATE = NOW.date()
DUE_DATE = ISSUE_DATE + timedelta(days=14)
STEM = f"BU2-DE-26092 - MRT PURPLE LINE 4 STATION (PP17 - PP20)_{NOW:%Y%m%d-%H%M}"
OUT_DIR = ROOT / "outputs" / f"rfq_26092_update_{NOW:%Y%m%d}"
OUT = OUT_DIR / f"{STEM}.xlsm"


def cell_map(root: etree._Element) -> dict[str, etree._Element]:
    sheet_data = root.find(f"{{{S}}}sheetData")
    if sheet_data is None:
        raise ValueError("Worksheet has no sheetData")
    return {
        cell.get("r"): cell
        for row in sheet_data
        for cell in row
        if cell.tag == f"{{{S}}}c"
    }


def clear(cell: etree._Element) -> None:
    cell.attrib.pop("t", None)
    for child in list(cell):
        if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
            cell.remove(child)


def put_text(cells: dict[str, etree._Element], address: str, value: str) -> None:
    cell = cells[address]
    clear(cell)
    cell.set("t", "inlineStr")
    inline = etree.SubElement(cell, f"{{{S}}}is")
    etree.SubElement(inline, f"{{{S}}}t").text = value


def put_number(cells: dict[str, etree._Element], address: str, value: int | float) -> None:
    cell = cells[address]
    clear(cell)
    etree.SubElement(cell, f"{{{S}}}v").text = str(value)


def update_header(cells: dict[str, etree._Element]) -> None:
    put_number(cells, "V3", DUE_DATE.day)
    put_number(cells, "W3", DUE_DATE.month)
    put_number(cells, "X3", (DUE_DATE.year + 543) % 100)
    put_number(cells, "C44", int(to_excel(datetime.combine(ISSUE_DATE, datetime.min.time()))))


def append_items(cells: dict[str, etree._Element], records: list[dict[str, str]]) -> None:
    for index, record in enumerate(records):
        row = 13 + index
        for col in "ABCEIJKMPSTUVWZ":
            if cells[f"{col}{row}"].find(f"{{{S}}}v") is not None or cells[f"{col}{row}"].find(f"{{{S}}}is") is not None:
                raise ValueError(f"Target row {row} is not blank at {col}")

        finish = record["TTL_PJ_FINISH_1"].strip()
        part_name = record["TTL_PJ_PART-NAME"].strip()
        part_code = record["TTL_PJ_PART-CODE"].strip()
        drawing = record["TTL_PJ_SHEET_NO"].strip()
        note = f"DWG {drawing}; THK?"

        put_number(cells, f"A{row}", 187 + index)
        put_text(cells, f"B{row}", f"{part_name} / {part_code}")
        put_number(cells, f"E{row}", 3)
        # The CSV says 1.2 mm in THK, but its part name says 2.0 mm. Leave I blank.
        put_number(cells, f"K{row}", 1200)
        put_number(cells, f"M{row}", 2400)
        put_text(cells, f"V{row}", "1 ด้าน")

        if finish == "NS-1S-P0070":
            put_text(cells, f"S{row}", "NS-1S-P0070")
            put_text(cells, f"T{row}", "PE  or PC")
            put_text(cells, f"U{row}", "Cornel")
        elif finish == "NS-1S-E0114 (CORNEL)":
            put_text(cells, f"S{row}", "NS-1S-E0114")
            put_text(cells, f"T{row}", "PE  or PC")
            put_text(cells, f"U{row}", "Cornel")
        elif finish == "SA-05611 (THAI PAINT)":
            put_text(cells, f"S{row}", "SA-05611")
            put_text(cells, f"U{row}", "Thai Paint")
            note = f"DWG {drawing}; THK/T?"
        elif finish == "SD-9103":
            put_text(cells, f"P{row}", "SD-9103")
        else:
            raise ValueError(f"Unmapped finish: {finish}")
        put_text(cells, f"Z{row}", note)


def main() -> None:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    if len(records) != 4:
        raise ValueError(f"Expected 4 source items, got {len(records)}")
    for record in records:
        if record["TTL_PJ_SPEC"].strip() != "1100 H14":
            raise ValueError("Unexpected alloy/spec")
        if record["TTL_PJ_FINISH_2"].strip() != "ONE SIDE PAINT":
            raise ValueError("Unexpected paint-side condition")
        if "1200x2400mm" not in record["TTL_PJ_PART-NAME"].replace(" ", ""):
            raise ValueError("Dimensions differ from the expected source")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(EXISTING, "r") as source:
        modified: dict[str, bytes] = {}
        for page in range(1, 11):
            name = f"xl/worksheets/sheet{page}.xml"
            root = etree.fromstring(source.read(name))
            cells = cell_map(root)
            update_header(cells)
            if page == 10:
                append_items(cells, records)
            modified[name] = xml_bytes(root)
        with zipfile.ZipFile(OUT, "w") as result:
            for info in source.infolist():
                result.writestr(copy.copy(info), modified.get(info.filename, source.read(info.filename)))
    print(f"OUTPUT={OUT}")
    print("SHEETS=10 ITEMS=190")
    print(f"ISSUE_DATE={ISSUE_DATE.isoformat()} DUE_DATE={DUE_DATE.isoformat()}")


if __name__ == "__main__":
    main()
