"""Clone the original XLSM package so every RFQ sheet retains native form controls.

This builder edits OOXML package parts directly because spreadsheet libraries do not
round-trip the protected Excel Form Controls in the supplied macro-enabled template.
The original template and source CSV are read only.
"""

from __future__ import annotations

import copy
import csv
import math
import re
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from lxml import etree
from openpyxl.utils.datetime import to_excel


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
TEMPLATE = ROOT / "BU2-DE-26091_โครงการ MRT PURPLE LINE 4 STATION ABOVE GROUND.xlsm"
SOURCE = Path(
    r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan"
    r"\PP-LINE_CL-PART\HOOK ON DOWNLIGHT SMOKE\HK MEP"
    r"\300HK ORDER FROM CHINA REV.2-LOT 2 FOR SMOKE LIGHT_REV04.csv"
)
OUT_DIR = ROOT / "outputs" / "rfq_native_controls_20261006"
NOW_BANGKOK = datetime.now(timezone.utc).astimezone(timezone(timedelta(hours=7)))
OUT = OUT_DIR / (
    "BU2-DE-26092 - MRT PURPLE LINE 4 STATION ABOVE GROUND_"
    f"{NOW_BANGKOK:%Y%m%d-%H%M}.xlsm"
)

S = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
P = "http://schemas.openxmlformats.org/package/2006/relationships"
C = "http://schemas.openxmlformats.org/package/2006/content-types"
EP = "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
VT = "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
WBT = "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"
DRT = "application/vnd.openxmlformats-officedocument.drawing+xml"
CPT = "application/vnd.ms-excel.controlproperties+xml"
WREL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"


def xml_bytes(root: etree._Element) -> bytes:
    return etree.tostring(root, encoding="UTF-8", xml_declaration=True, standalone=True)


def dimensions(code: str) -> tuple[int | None, int | None]:
    m = re.match(r"^(\d{3})(\d+)HK-.*?/ACOUS-(STD|VAR(?:-(\d+))?)/", code)
    if not m:
        return None, None
    first_width, length, kind, override = m.groups()
    return int(override) if kind.startswith("VAR-") else int(first_width), int(length)


def adjusted_code(source_code: str) -> str:
    m = re.match(r"^300(\d+)HK-", source_code)
    if m is None:
        raise ValueError(f"Unknown length prefix: {source_code}")
    return source_code.replace("/PF-S/", "/NON-PF-S/", 1) if int(m.group(1)) < 900 else source_code


def update_cells(root: etree._Element, records: list[dict[str, str]], page: int, pages: int) -> None:
    rows = {
        int(row.get("r")): row
        for row in root.find(f"{{{S}}}sheetData")
        if row.tag == f"{{{S}}}row"
    }
    cells = {
        cell.get("r"): cell
        for row in rows.values()
        for cell in row
        if cell.tag == f"{{{S}}}c"
    }

    def cell_at(address: str) -> etree._Element:
        if address not in cells:
            raise ValueError(f"Template is missing cell {address}")
        return cells[address]

    def clear(address: str) -> None:
        cell = cell_at(address)
        cell.attrib.pop("t", None)
        for child in list(cell):
            if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
                cell.remove(child)

    def set_text(address: str, value: str) -> None:
        clear(address)
        cell = cell_at(address)
        cell.set("t", "inlineStr")
        inline = etree.SubElement(cell, f"{{{S}}}is")
        etree.SubElement(inline, f"{{{S}}}t").text = value

    def set_number(address: str, value: int | float) -> None:
        clear(address)
        etree.SubElement(cell_at(address), f"{{{S}}}v").text = str(value)

    def set_formula(address: str, formula: str) -> None:
        clear(address)
        etree.SubElement(cell_at(address), f"{{{S}}}f").text = formula
        etree.SubElement(cell_at(address), f"{{{S}}}v")

    # Remove the previous RFQ's items from both sections, without changing styles.
    for row in list(range(7, 28)) + list(range(31, 42)):
        for col in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            clear(f"{col}{row}")
        set_formula(f"F{row}", f'IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,3,FALSE))')
        set_formula(f"G{row}", f'IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,2,FALSE))')

    set_text("Z1", "BU2-DE-26092")
    set_number("V3", 20)
    set_number("W3", 10)
    set_number("X3", 69)
    set_number("C44", int(to_excel(datetime(2026, 10, 6))))
    clear("H44")
    set_text("Z45", f"{page}/{pages}")

    for local_index, rec in enumerate(records):
        row = 7 + local_index
        item_number = (page - 1) * 20 + local_index + 1
        code = adjusted_code(rec["TTL_PJ_PART-CODE"].strip())
        finish = rec["TTL_PJ_FINISH_1"].strip()
        width, length = dimensions(code)
        notes = [f"DWG {rec['TTL_PJ_SHEET_NO'].strip()}"]

        set_number(f"A{row}", item_number)
        set_text(f"B{row}", f"{rec['TTL_PJ_PART-NAME'].strip()} / {code}")
        set_number(f"I{row}", 1.2)
        set_text(f"V{row}", "1 ด้าน")
        if width is None:
            notes.append("ขนาด?")
        else:
            set_number(f"K{row}", width)
            set_number(f"M{row}", length)

        if finish == "Fameline SD-9103 PC":
            set_text(f"P{row}", "SD-9103")
            set_number(f"E{row}", 3)
        elif finish in ("NS-1S-P0070", "NS-1S-E0114"):
            set_text(f"S{row}", finish)
            set_text(f"T{row}", "PE  or PC")
            set_text(f"U{row}", "Cornel")
            set_number(f"E{row}", 3)
        elif finish in ("S5206TH", "SW255TH"):
            set_text(f"S{row}", finish)
            set_text(f"T{row}", "PE  or PC")
            set_text(f"U{row}", "Akzo Nobel")
            set_number(f"E{row}", 3)
        elif finish == "xxx":
            notes.append("สี xxx?")
        else:
            raise ValueError(f"Unknown finish on item {item_number}: {finish}")
        set_text(f"Z{row}", "; ".join(notes))


def shift_shape_ids(data: bytes, page: int) -> bytes:
    if page == 1:
        return data
    replacements = {str(i).encode(): str(i + (page - 1) * 1000).encode() for i in range(29697, 29706)}
    return re.sub(rb"(?<!\d)(?:2969[7-9]|2970[0-5])(?!\d)", lambda m: replacements[m.group()], data)


def worksheet_rels(source: bytes, page: int) -> bytes:
    root = etree.fromstring(source)
    for rel in root:
        target = rel.get("Target", "")
        if "ctrlProp" in target:
            old = int(re.search(r"ctrlProp(\d+)\.xml", target).group(1))
            rel.set("Target", f"../ctrlProps/ctrlProp{(page - 1) * 9 + old}.xml")
        elif "vmlDrawing" in target:
            rel.set("Target", f"../drawings/vmlDrawing{page}.vml")
        elif "drawing" in target:
            rel.set("Target", f"../drawings/drawing{page}.xml")
        elif "printerSettings" in target:
            rel.set("Target", f"../printerSettings/printerSettings{page}.bin")
    return xml_bytes(root)


def workbook_parts(z: zipfile.ZipFile, pages: int) -> dict[str, bytes]:
    wb = etree.fromstring(z.read("xl/workbook.xml"))
    sheets = wb.find(f"{{{S}}}sheets")
    source_sheet = sheets[0]
    for page in range(2, pages + 1):
        item = copy.deepcopy(source_sheet)
        item.set("name", str(page))
        item.set("sheetId", str(32 + page))
        item.set(f"{{{R}}}id", f"rId{page + 5}")
        sheets.append(item)
    defined = wb.find(f"{{{S}}}definedNames")
    if defined is not None:
        local_names = [n for n in defined if n.get("localSheetId") == "0"]
        for page in range(2, pages + 1):
            for original in local_names:
                new = copy.deepcopy(original)
                new.set("localSheetId", str(page - 1))
                if new.text:
                    new.text = new.text.replace("'1'!", f"'{page}'!")
                defined.append(new)
    calc = wb.find(f"{{{S}}}calcPr")
    if calc is not None:
        calc.set("fullCalcOnLoad", "1")
        calc.set("forceFullCalc", "1")

    rels = etree.fromstring(z.read("xl/_rels/workbook.xml.rels"))
    for node in list(rels):
        if node.get("Type", "").endswith("/calcChain"):
            rels.remove(node)
    for page in range(2, pages + 1):
        etree.SubElement(rels, f"{{{P}}}Relationship", {
            "Id": f"rId{page + 5}", "Type": WREL,
            "Target": f"worksheets/sheet{page}.xml",
        })

    types = etree.fromstring(z.read("[Content_Types].xml"))
    for node in list(types):
        if node.get("PartName") == "/xl/calcChain.xml":
            types.remove(node)
    for page in range(2, pages + 1):
        etree.SubElement(types, f"{{{C}}}Override", {
            "PartName": f"/xl/worksheets/sheet{page}.xml", "ContentType": WBT,
        })
        etree.SubElement(types, f"{{{C}}}Override", {
            "PartName": f"/xl/drawings/drawing{page}.xml", "ContentType": DRT,
        })
        for control in range(1, 10):
            index = (page - 1) * 9 + control
            etree.SubElement(types, f"{{{C}}}Override", {
                "PartName": f"/xl/ctrlProps/ctrlProp{index}.xml", "ContentType": CPT,
            })

    app = etree.fromstring(z.read("docProps/app.xml"))
    pair_vector = app.find(f"{{{EP}}}HeadingPairs/{{{VT}}}vector")
    if pair_vector is not None:
        entries = pair_vector.findall(f"{{{VT}}}variant")
        if len(entries) >= 4:
            entries[1].find(f"{{{VT}}}i4").text = str(pages)
            entries[3].find(f"{{{VT}}}i4").text = str(pages)
    title_vector = app.find(f"{{{EP}}}TitlesOfParts/{{{VT}}}vector")
    if title_vector is not None:
        for child in list(title_vector):
            title_vector.remove(child)
        for page in range(1, pages + 1):
            etree.SubElement(title_vector, f"{{{VT}}}lpstr").text = str(page)
        for page in range(1, pages + 1):
            etree.SubElement(title_vector, f"{{{VT}}}lpstr").text = f"'{page}'!Print_Area"
        title_vector.set("size", str(pages * 2))

    return {
        "xl/workbook.xml": xml_bytes(wb),
        "xl/_rels/workbook.xml.rels": xml_bytes(rels),
        "[Content_Types].xml": xml_bytes(types),
        "docProps/app.xml": xml_bytes(app),
    }


def main() -> None:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    if len(records) != 186:
        raise ValueError(f"Expected 186 source records, got {len(records)}")
    pages = math.ceil(len(records) / 20)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(TEMPLATE, "r") as original:
        modified = workbook_parts(original, pages)
        original_sheet = original.read("xl/worksheets/sheet1.xml")
        original_rels = original.read("xl/worksheets/_rels/sheet1.xml.rels")
        original_drawing = original.read("xl/drawings/drawing1.xml")
        original_drawing_rels = original.read("xl/drawings/_rels/drawing1.xml.rels")
        original_vml = original.read("xl/drawings/vmlDrawing1.vml")
        original_printer = original.read("xl/printerSettings/printerSettings1.bin")

        with zipfile.ZipFile(OUT, "w") as result:
            for info in original.infolist():
                if info.filename == "xl/calcChain.xml":
                    continue
                if info.filename in ("xl/worksheets/sheet1.xml", "xl/worksheets/_rels/sheet1.xml.rels", "xl/drawings/drawing1.xml", "xl/drawings/vmlDrawing1.vml"):
                    continue
                result.writestr(copy.copy(info), modified.pop(info.filename, original.read(info.filename)))

            for page in range(1, pages + 1):
                sheet = etree.fromstring(original_sheet)
                if page > 1:
                    sheet.find(f"{{{S}}}sheetPr").set("codeName", f"Sheet{page}")
                update_cells(sheet, records[(page - 1) * 20:page * 20], page, pages)
                result.writestr(
                    f"xl/worksheets/sheet{page}.xml",
                    shift_shape_ids(xml_bytes(sheet), page),
                    compress_type=zipfile.ZIP_DEFLATED,
                )
                result.writestr(
                    f"xl/worksheets/_rels/sheet{page}.xml.rels",
                    worksheet_rels(original_rels, page),
                    compress_type=zipfile.ZIP_DEFLATED,
                )
                result.writestr(
                    f"xl/drawings/drawing{page}.xml",
                    shift_shape_ids(original_drawing, page),
                    compress_type=zipfile.ZIP_DEFLATED,
                )
                result.writestr(
                    f"xl/drawings/vmlDrawing{page}.vml",
                    shift_shape_ids(original_vml, page),
                    compress_type=zipfile.ZIP_DEFLATED,
                )
                if page > 1:
                    result.writestr(
                        f"xl/drawings/_rels/drawing{page}.xml.rels",
                        original_drawing_rels,
                        compress_type=zipfile.ZIP_DEFLATED,
                    )
                    result.writestr(
                        f"xl/printerSettings/printerSettings{page}.bin",
                        original_printer,
                        compress_type=zipfile.ZIP_DEFLATED,
                    )
                    for control in range(1, 10):
                        index = (page - 1) * 9 + control
                        result.writestr(
                            f"xl/ctrlProps/ctrlProp{index}.xml",
                            original.read(f"xl/ctrlProps/ctrlProp{control}.xml"),
                            compress_type=zipfile.ZIP_DEFLATED,
                        )
            for name, data in modified.items():
                result.writestr(name, data, compress_type=zipfile.ZIP_DEFLATED)

    print("OUTPUT_SAVED=1")
    print(f"SHEETS={pages} ITEMS={len(records)}")


if __name__ == "__main__":
    main()
