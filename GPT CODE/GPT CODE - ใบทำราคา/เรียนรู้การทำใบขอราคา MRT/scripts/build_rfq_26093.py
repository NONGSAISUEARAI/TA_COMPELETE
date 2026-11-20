"""Build BU2-DE-26093 from the SOLID C06 CSV, retaining native XLSM controls."""

from __future__ import annotations

import copy
import csv
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from lxml import etree
from openpyxl.utils.datetime import to_excel

from build_rfq_native_controls import S, TEMPLATE, workbook_parts, xml_bytes


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
SOURCE = Path(
    r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan"
    r"\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PART.csv"
)
NOW_BANGKOK = datetime.now(timezone.utc).astimezone(timezone(timedelta(hours=7)))
OUT_DIR = ROOT / "outputs" / f"rfq_26093_{NOW_BANGKOK:%Y%m%d}"
OUT = OUT_DIR / (
    "BU2-DE-26093 - MRT PURPLE LINE 4STATION (PP17 - PP20)_"
    f"{NOW_BANGKOK:%Y%m%d-%H%M}.xlsm"
)


def populate(root: etree._Element, records: list[dict[str, str]]) -> None:
    sheet_data = root.find(f"{{{S}}}sheetData")
    cells = {
        cell.get("r"): cell
        for row in sheet_data
        for cell in row
        if cell.tag == f"{{{S}}}c"
    }

    def get(address: str) -> etree._Element:
        if address not in cells:
            raise ValueError(f"Template cell missing: {address}")
        return cells[address]

    def clear(address: str) -> None:
        cell = get(address)
        cell.attrib.pop("t", None)
        for child in list(cell):
            if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
                cell.remove(child)

    def text(address: str, value: str) -> None:
        clear(address)
        cell = get(address)
        cell.set("t", "inlineStr")
        node = etree.SubElement(cell, f"{{{S}}}is")
        etree.SubElement(node, f"{{{S}}}t").text = value

    def number(address: str, value: int | float) -> None:
        clear(address)
        etree.SubElement(get(address), f"{{{S}}}v").text = str(value)

    def formula(address: str, value: str) -> None:
        clear(address)
        etree.SubElement(get(address), f"{{{S}}}f").text = value
        etree.SubElement(get(address), f"{{{S}}}v")

    for row in list(range(7, 28)) + list(range(31, 42)):
        for column in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            clear(f"{column}{row}")
        formula(f"F{row}", f'IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,3,FALSE))')
        formula(f"G{row}", f'IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,2,FALSE))')

    text("Z1", "BU2-DE-26093")
    text("Z2", "PJ26-008")  # JO from the existing RFQ for the same project.
    text("C2", records[0]["TTL_PJ_NAME_"].strip())
    issue_date = NOW_BANGKOK.date()
    due_date = issue_date + timedelta(days=14)
    number("V3", due_date.day)
    number("W3", due_date.month)
    number("X3", (due_date.year + 543) % 100)
    number("C44", int(to_excel(datetime.combine(issue_date, datetime.min.time()))))
    clear("H44")
    text("Z45", "1/1")

    for index, record in enumerate(records, 1):
        row = index + 6
        code = record["TTL_PJ_PART-CODE"].strip()
        finish = record["TTL_PJ_FINISH_1"].strip()
        name = record["TTL_PJ_PART-NAME"].strip()

        number(f"A{row}", index)
        text(f"B{row}", f"{name} / {code}")
        number(f"E{row}", 3)  # 1100 H14; one-side paint; color code present.
        number(f"K{row}", 1200)
        number(f"M{row}", 2400)
        text(f"V{row}", "1 ด้าน")
        note = f"DWG {record['TTL_PJ_SHEET_NO'].strip()}; THK?"

        if finish == "NS-1S-P0070":
            text(f"S{row}", "NS-1S-P0070")
            text(f"T{row}", "PE  or PC")
            text(f"U{row}", "Cornel")
        elif finish == "NS-1S-E0114 (CORNEL)":
            text(f"S{row}", "NS-1S-E0114")
            text(f"T{row}", "PE  or PC")
            text(f"U{row}", "Cornel")
        elif finish == "SA-05611 (THAI PAINT)":
            text(f"S{row}", "SA-05611")
            text(f"U{row}", "Thai Paint")
            note = f"DWG {record['TTL_PJ_SHEET_NO'].strip()}; THK/T?"
        elif finish == "SD-9103":
            text(f"P{row}", "SD-9103")
        else:
            raise ValueError(f"Unmapped finish at item {index}: {finish}")
        text(f"Z{row}", note)


def main() -> None:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    if len(records) != 4:
        raise ValueError(f"Expected 4 records, got {len(records)}")
    for record in records:
        if record["TTL_PJ_SPEC"].strip() != "1100 H14" or record["TTL_PJ_FINISH_2"].strip() != "ONE SIDE PAINT":
            raise ValueError("Material/finish rules no longer match the source")
        if "1200x2400mm" not in record["TTL_PJ_PART-NAME"].replace(" ", ""):
            raise ValueError("Part-name dimensions need review")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(TEMPLATE, "r") as source:
        modified = workbook_parts(source, 1)
        sheet = etree.fromstring(source.read("xl/worksheets/sheet1.xml"))
        populate(sheet, records)
        modified["xl/worksheets/sheet1.xml"] = xml_bytes(sheet)
        with zipfile.ZipFile(OUT, "w") as result:
            for info in source.infolist():
                if info.filename == "xl/calcChain.xml":
                    continue
                result.writestr(copy.copy(info), modified.pop(info.filename, source.read(info.filename)))
            if modified:
                raise ValueError(f"Modified parts not written: {list(modified)}")
    print("OUTPUT_SAVED=1")
    print("ITEMS=4 SHEETS=1")


if __name__ == "__main__":
    main()
