"""Build BU2-DE-26094 from the aluminium-tray CSV with native XLSM controls.

The source does not identify the RFQ JO, the standard-color coating column,
or an order quantity. Those are explicit inputs rather than inferred values.
"""

from __future__ import annotations

import argparse
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
    r"\PP-LINE_CL-PART\ALUMINIUM TRAY\Aluminium Tray งานแก้"
    r"\ALUMINIUM TRAY งานแก้.csv"
)
OUT_DIR = ROOT / "outputs" / "rfq_26094"
BANGKOK = timezone(timedelta(hours=7))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jo", required=True)
    parser.add_argument("--color-column", choices=("N", "O", "P"))
    parser.add_argument("--quantity", type=int)
    args = parser.parse_args()
    if args.quantity is not None and args.quantity <= 0:
        raise ValueError("Quantity must be positive")

    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    if len(records) != 1:
        raise ValueError(f"Expected one source item; found {len(records)}")
    item = records[0]
    expected = {
        "TTL_PJ_PART-CODE": "PJ25-031-AL-TRAY-02-LT-STD-L=130mm.",
        "TTL_PJ_PART-NAME": "AL.2.0mm.(thk.)SOLID-SHEET 50x130mm.",
        "TTL_PJ_MATTERIAL": "ALUMINIUM",
        "TTL_PJ_SPEC": "1100 H14",
        "TTL_PJ_THK": "2.0 mm.",
        "TTL_PJ_FINISH_1": "SD-9111",
        "TTL_PJ_FINISH_2": "ONE SIDE PAINT",
    }
    for key, value in expected.items():
        if item[key].strip() != value:
            raise ValueError(f"Source changed at {key}: {item[key]!r}")

    now = datetime.now(BANGKOK)
    due = now.date() + timedelta(days=14)
    name = item["TTL_PJ_NAME_"].strip()
    out = OUT_DIR / f"BU2-DE-26094 - {name}_{now:%Y%m%d-%H%M}.xlsm"

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
            cell = cells[address]
            cell.set("t", "inlineStr")
            node = etree.SubElement(cell, f"{{{S}}}is")
            etree.SubElement(node, f"{{{S}}}t").text = value

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

        put_text("Z1", "BU2-DE-26094")
        put_text("Z2", args.jo)
        put_text("C2", name)
        put_number("V3", due.day)
        put_number("W3", due.month)
        put_number("X3", (due.year + 543) % 100)
        put_number("C44", int(to_excel(datetime.combine(now.date(), datetime.min.time()))))
        clear("H44")
        put_text("Z45", "1/1")

        put_number("A7", 1)
        put_text("B7", f"{item['TTL_PJ_PART-NAME'].strip()} / {item['TTL_PJ_PART-CODE'].strip()}")
        put_number("E7", 3)
        put_number("I7", 2)
        put_number("K7", 50)
        put_number("M7", 130)
        if args.color_column is not None:
            put_text(f"{args.color_column}7", "SD-9111")
        put_text("V7", "1 ด้าน")
        if args.quantity is not None:
            put_number("W7", args.quantity)

        changes["xl/worksheets/sheet1.xml"] = xml_bytes(root)
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(out, "w") as target:
            for info in source.infolist():
                if info.filename == "xl/calcChain.xml":
                    continue
                target.writestr(copy.copy(info), changes.pop(info.filename, source.read(info.filename)))
            if changes:
                raise ValueError(f"Unwritten package changes: {list(changes)}")

    print(f"OUTPUT={out}")
    print("ITEMS=1 SHEETS=1 PDF_CREATED=0")
    print(f"COLOR_COLUMN={args.color_column or 'PENDING'} QUANTITY={args.quantity or 'PENDING'}")


if __name__ == "__main__":
    main()
