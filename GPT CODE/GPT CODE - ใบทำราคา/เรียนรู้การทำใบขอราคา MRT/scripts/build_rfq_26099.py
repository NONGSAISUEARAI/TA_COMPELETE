"""Build one-page BU2-DE-26099 from the C10 hook-on-panel part list.

Clone the original XLSM package to retain protected native form controls.
The CSV has no quantities, so W7:W11 intentionally remain blank.
"""

from __future__ import annotations

import copy
import csv
import re
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from lxml import etree
from openpyxl.utils.datetime import to_excel

from build_rfq_native_controls import S, TEMPLATE, workbook_parts, xml_bytes


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
SOURCE = Path(
    r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan"
    r"\PP-LINE_FL-PART\HOOK ON\HOOK ON FOR PATTERN SCREEN C10"
    r"\FL-PJ-26-031-HK-C10-PART.csv"
)
OUT_DIR = ROOT / "outputs" / "rfq_26099"
BANGKOK = timezone(timedelta(hours=7))


def main() -> None:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    if len(records) != 5:
        raise ValueError(f"Expected five C10 parts, got {len(records)}")
    if any(rec["TTL_PJ_NO"].strip() != "PJ25-031" for rec in records):
        raise ValueError("Unexpected JO")
    if any(rec["TTL_PJ_MATTERIAL"].strip() != "ALUMINIUM" for rec in records):
        raise ValueError("Unexpected material")
    if any(rec["TTL_PJ_SPEC"].strip() != "1100 H14" for rec in records):
        raise ValueError("Unexpected alloy")
    if any(rec["TTL_PJ_THK"].strip() != "1.2 mm." for rec in records):
        raise ValueError("Unexpected thickness")
    if any(rec["TTL_PJ_FINISH_1"].strip() != "Fameline SD-9103 PC" for rec in records):
        raise ValueError("Unexpected color")
    if any(rec["TTL_PJ_FINISH_2"].strip() != "ONE SIDE PAINT" for rec in records):
        raise ValueError("Unexpected coating sides")

    now = datetime.now(BANGKOK)
    due = now.date() + timedelta(days=14)
    project = "MRT PURPLE LINE 4 STATION (PP17 - PP20)"
    output = OUT_DIR / f"BU2-DE-26099 - {project}_{now:%Y%m%d-%H%M}.xlsm"
    if output.exists():
        raise FileExistsError(output)

    with zipfile.ZipFile(TEMPLATE, "r") as source:
        changes = workbook_parts(source, 1)
        root = etree.fromstring(source.read("xl/worksheets/sheet1.xml"))
        cells = {
            cell.get("r"): cell
            for row in root.find(f"{{{S}}}sheetData")
            for cell in row
            if cell.tag == f"{{{S}}}c"
        }

        def clear(address: str) -> None:
            cell = cells[address]
            cell.attrib.pop("t", None)
            for child in list(cell):
                if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
                    cell.remove(child)

        def put_text(address: str, value: str) -> None:
            clear(address)
            cells[address].set("t", "inlineStr")
            inline = etree.SubElement(cells[address], f"{{{S}}}is")
            etree.SubElement(inline, f"{{{S}}}t").text = value

        def put_number(address: str, value: int | float) -> None:
            clear(address)
            etree.SubElement(cells[address], f"{{{S}}}v").text = str(value)

        for row in list(range(7, 28)) + list(range(31, 42)):
            for column in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
                clear(f"{column}{row}")
            for column, result_index in (("F", 3), ("G", 2)):
                etree.SubElement(cells[f"{column}{row}"], f"{{{S}}}f").text = (
                    f'IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,{result_index},FALSE))'
                )
                etree.SubElement(cells[f"{column}{row}"], f"{{{S}}}v")

        put_text("Z1", "BU2-DE-26099")
        put_text("Z2", "PJ25-031")
        put_text("C2", project)
        put_text("C3", "CKST")
        put_number("V3", due.day)
        put_number("W3", due.month)
        put_number("X3", (due.year + 543) % 100)
        put_number("C44", int(to_excel(datetime.combine(now.date(), datetime.min.time()))))
        clear("H44")
        put_text("Z45", "1/1")

        for index, rec in enumerate(records, 1):
            row = index + 6
            code = rec["TTL_PJ_PART-CODE"].strip()
            match = re.fullmatch(r"(\d{3})(\d+)HK-A/PF-S/ACOUSSTD/C10", code)
            if not match:
                raise ValueError(f"Unexpected C10 code: {code}")
            width, length = map(int, match.groups())
            if length < 900:
                code = code.replace("/PF-S/", "/NON-PF-S/", 1)
            put_number(f"A{row}", index)
            put_text(f"B{row}", f"{rec['TTL_PJ_PART-NAME'].strip()} / {code}")
            put_number(f"E{row}", 3)
            put_number(f"I{row}", 1.2)
            put_number(f"K{row}", width)
            put_number(f"M{row}", length)
            put_text(f"P{row}", "SD-9103")
            put_text(f"V{row}", "1 ด้าน")
            put_text(f"X{row}", "ชิ้น")
            put_text(f"Z{row}", "PP20")

        changes["xl/worksheets/sheet1.xml"] = xml_bytes(root)
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output, "w") as target:
            for info in source.infolist():
                if info.filename == "xl/calcChain.xml":
                    continue
                target.writestr(copy.copy(info), changes.pop(info.filename, source.read(info.filename)))
            if changes:
                raise ValueError(f"Unwritten package changes: {list(changes)}")
    print(f"OUTPUT={output.name}")
    print("ITEMS=5 SHEETS=1 COLOR_COLUMN=P QUANTITY=BLANK")


if __name__ == "__main__":
    main()
