"""Reorder the existing 26092 RFQ without rebuilding its protected Excel form."""

from __future__ import annotations

import copy
import hashlib
import math
import re
import sys
import zipfile
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import openpyxl
from lxml import etree
from openpyxl.utils.datetime import to_excel


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
SOURCE = Path(
    r"Z:\B2_EXTERNAL\BACK UP PROJECT WORKS\5. งานแบบdrawing"
    r"\6. ใบขอราคา\2569"
    r"\BU2-DE-26092 - MRT PURPLE LINE 4 STATION BELOW GROUND_20261006-1621.xlsm"
)
NOW = datetime.now(timezone.utc).astimezone(timezone(timedelta(hours=7)))
ISSUE_DATE = NOW.date()
DUE_DATE = ISSUE_DATE + timedelta(days=14)
REVISION = "BU2-DE-26092REV01"
OUTPUT = ROOT / "outputs" / f"rfq_26092_rev01_{NOW:%Y%m%d}" / (
    f"{REVISION} - MRT PURPLE LINE 4 STATION (PP17 - PP20)_{NOW:%Y%m%d-%H%M}.xlsm"
)

S = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
P = "http://schemas.openxmlformats.org/package/2006/relationships"
EP = "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
VT = "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
COLORS = (
    "SW255TH",
    "S5206TH",
    "NS-1S-E0114",
    "NS-1S-P0070",
    "SD-9103",
)
STATION = {
    "SW255TH": "PP17",
    "S5206TH": "PP17",
    "NS-1S-E0114": "PP18",
    "NS-1S-P0070": "PP19",
    "SD-9103": "PP20",
}


def xml_bytes(root: etree._Element) -> bytes:
    return etree.tostring(root, encoding="UTF-8", xml_declaration=True, standalone=True)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def cell_map(root: etree._Element) -> dict[str, etree._Element]:
    return {
        c.get("r"): c
        for row in root.find(f"{{{S}}}sheetData")
        for c in row
        if c.tag == f"{{{S}}}c"
    }


def clear(cell: etree._Element) -> None:
    cell.attrib.pop("t", None)
    for child in list(cell):
        if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
            cell.remove(child)


def put_text(cell: etree._Element, value: str) -> None:
    clear(cell)
    cell.set("t", "inlineStr")
    element = etree.SubElement(cell, f"{{{S}}}is")
    etree.SubElement(element, f"{{{S}}}t").text = value


def put_number(cell: etree._Element, value: int) -> None:
    clear(cell)
    etree.SubElement(cell, f"{{{S}}}v").text = str(value)


def copy_value(source: etree._Element, target: etree._Element) -> None:
    clear(target)
    if "t" in source.attrib:
        target.set("t", source.get("t"))
    for child in source:
        if child.tag in (f"{{{S}}}f", f"{{{S}}}v", f"{{{S}}}is"):
            target.append(copy.deepcopy(child))


def read_items(
    book: openpyxl.Workbook, *, sort_by_length: bool = False, exclude_tzd: bool = False
) -> list[dict]:
    items = []
    for page in range(1, 11):
        sheet = book[str(page)]
        for row in range(7, 27):
            number = sheet[f"A{row}"].value
            if number is None:
                continue
            if not isinstance(number, int):
                raise ValueError(f"Unexpected item number at {page}!A{row}: {number}")
            color = sheet[f"S{row}"].value or sheet[f"P{row}"].value
            if color not in COLORS:
                raise ValueError(f"Unexpected finish at {page}!{row}: {color}")
            code = sheet[f"B{row}"].value or ""
            if exclude_tzd and "/ACOUS-TZD-" in code.upper():
                continue
            dimensions = re.search(r"/ (\d{3})(\d+)HK-", code, re.IGNORECASE)
            if not dimensions:
                raise ValueError(f"Cannot read width and length for item {number}: {code}")
            length = int(dimensions.group(2))
            var = re.search(r"/ACOUS-VAR(?:-(\d+))?/", code, re.IGNORECASE)
            var_width = None
            if var:
                var_width = int(var.group(1)) if var.group(1) else 300
                if not 0 < var_width < 1000:
                    raise ValueError(f"Unexpected VAR width for item {number}: {var_width}")
                if exclude_tzd:
                    code = (
                        code[:dimensions.start(1)]
                        + f"{var_width:03d}"
                        + code[dimensions.end(1):]
                    )
            width = sheet[f"K{row}"].value
            if width is None:
                width = int(dimensions.group(1))
            if var_width is not None:
                width = var_width
            note = sheet[f"Z{row}"].value or ""
            station = STATION[color]
            if sort_by_length:
                note = station
            elif not re.search(rf"(?<!\w){station}(?!\w)", note):
                note = f"{note}; {station}" if note else station
            items.append({
                "old_number": number,
                "page": page,
                "row": row,
                "color": color,
                "width": float(width),
                "length": length,
                "var_width": var_width,
                "code": code,
                "note": note,
            })
    expected_count = 170 if exclude_tzd else 176
    if len(items) != expected_count:
        raise ValueError(f"Expected {expected_count} items, found {len(items)}")
    if len({item["old_number"] for item in items}) != len(items):
        raise ValueError("Existing item numbers contain duplicates")
    if sort_by_length:
        items.sort(key=lambda item: (COLORS.index(item["color"]), item["length"], item["old_number"]))
    else:
        items.sort(key=lambda item: (COLORS.index(item["color"]), item["width"], item["old_number"]))
    return items


def revise_workbook(root: etree._Element) -> None:
    sheets = root.find(f"{{{S}}}sheets")
    tenth = next(sheet for sheet in sheets if sheet.get("name") == "10")
    if tenth.get(f"{{{R}}}id") != "rId10":
        raise ValueError("Unexpected sheet 10 relationship")
    sheets.remove(tenth)
    defined = root.find(f"{{{S}}}definedNames")
    if defined is not None:
        for name in list(defined):
            local = name.get("localSheetId")
            if local == "9":
                defined.remove(name)
            elif local is not None and int(local) > 9:
                name.set("localSheetId", str(int(local) - 1))
    calc = root.find(f"{{{S}}}calcPr")
    if calc is not None:
        calc.set("fullCalcOnLoad", "1")
        calc.set("forceFullCalc", "1")


def revise_app(root: etree._Element, expected_sheet_count: int) -> None:
    heading = root.find(f"{{{EP}}}HeadingPairs/{{{VT}}}vector")
    if heading is not None:
        variants = heading.findall(f"{{{VT}}}variant")
        for index, variant in enumerate(variants[:-1]):
            label = variant.find(f"{{{VT}}}lpstr")
            count = variants[index + 1].find(f"{{{VT}}}i4")
            if label is not None and count is not None and label.text == "Worksheets":
                count.text = str(expected_sheet_count)
    titles = root.find(f"{{{EP}}}TitlesOfParts/{{{VT}}}vector")
    if titles is not None:
        for element in list(titles):
            if element.text in ("10", "'10'!Print_Area"):
                titles.remove(element)
        titles.set("size", str(len(titles)))


def main(*, sort_by_length: bool = False, exclude_tzd: bool = False) -> None:
    source_hash = sha256(SOURCE)
    book = openpyxl.load_workbook(SOURCE, keep_vba=True)
    if book.sheetnames[:10] != [str(i) for i in range(1, 11)] or "Sheet1" not in book.sheetnames:
        raise ValueError(f"Unexpected source sheet structure: {book.sheetnames}")
    items = read_items(book, sort_by_length=sort_by_length, exclude_tzd=exclude_tzd)
    pages = math.ceil(len(items) / 20)
    if pages != 9:
        raise ValueError("Expected exactly nine revised RFQ pages")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(SOURCE, "r") as original:
        source_cells = {
            page: cell_map(etree.fromstring(original.read(f"xl/worksheets/sheet{page}.xml")))
            for page in range(1, 11)
        }
        for item in items:
            row = item["row"]
            cells = source_cells[item["page"]]
            item["payload"] = {
                col: copy.deepcopy(cells[f"{col}{row}"])
                for col in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                if col not in "FG"
            }

        modified = {}
        for page in range(1, pages + 1):
            part = f"xl/worksheets/sheet{page}.xml"
            sheet_root = etree.fromstring(original.read(part))
            cells = cell_map(sheet_root)
            for row in range(7, 27):
                for col in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
                    if col not in "FG":
                        clear(cells[f"{col}{row}"])
            for index, item in enumerate(items[(page - 1) * 20:page * 20]):
                row = index + 7
                for col, payload in item["payload"].items():
                    copy_value(payload, cells[f"{col}{row}"])
                put_number(cells[f"A{row}"], (page - 1) * 20 + index + 1)
                if item["var_width"] is not None:
                    put_number(cells[f"K{row}"], item["var_width"])
                    if exclude_tzd:
                        put_text(cells[f"B{row}"], item["code"])
                put_text(cells[f"Z{row}"], item["note"])
            put_text(cells["Z1"], REVISION)
            put_number(cells["V3"], DUE_DATE.day)
            put_number(cells["W3"], DUE_DATE.month)
            put_number(cells["X3"], (DUE_DATE.year + 543) % 100)
            put_number(cells["C44"], int(to_excel(datetime.combine(ISSUE_DATE, datetime.min.time()))))
            put_text(cells["Z45"], f"{page}/{pages}")
            modified[part] = xml_bytes(sheet_root)

        workbook_part = "xl/workbook.xml"
        workbook_root = etree.fromstring(original.read(workbook_part))
        revise_workbook(workbook_root)
        modified[workbook_part] = xml_bytes(workbook_root)

        rels_part = "xl/_rels/workbook.xml.rels"
        rels_root = etree.fromstring(original.read(rels_part))
        tenth_rel = next(rel for rel in rels_root if rel.get("Id") == "rId10")
        if tenth_rel.get("Target") != "worksheets/sheet10.xml":
            raise ValueError("Unexpected workbook sheet 10 target")
        rels_root.remove(tenth_rel)
        modified[rels_part] = xml_bytes(rels_root)

        aggregate_part = "xl/worksheets/sheet11.xml"
        aggregate_root = etree.fromstring(original.read(aggregate_part))
        matching = [
            formula for formula in aggregate_root.iter(f"{{{S}}}f")
            if formula.text and "copyallsheet_v3(A7:Z26,1,10,1)" in formula.text
        ]
        if len(matching) != 1:
            raise ValueError(f"Expected one aggregation formula, found {len(matching)}")
        matching[0].text = matching[0].text.replace(
            "copyallsheet_v3(A7:Z26,1,10,1)",
            "copyallsheet_v3(A7:Z26,1,9,1)",
        )
        modified[aggregate_part] = xml_bytes(aggregate_root)

        app_part = "docProps/app.xml"
        app_root = etree.fromstring(original.read(app_part))
        revise_app(app_root, len(book.sheetnames) - 1)
        modified[app_part] = xml_bytes(app_root)

        # Keep the unreferenced sheet-10 package parts. Removing them could delete
        # shared native controls; the workbook and its print areas expose only 1-9.
        with zipfile.ZipFile(OUTPUT, "w") as result:
            for info in original.infolist():
                result.writestr(copy.copy(info), modified.get(info.filename, original.read(info.filename)))

    if sha256(SOURCE) != source_hash:
        raise RuntimeError("Source workbook changed during revision")
    print(f"OUTPUT={OUTPUT}")
    print(f"SOURCE_SHA256={source_hash}")
    print(f"ISSUE_DATE={ISSUE_DATE.isoformat()} DUE_DATE={DUE_DATE.isoformat()}")
    print(f"ITEMS={len(items)} PAGES={pages} SORT={'LENGTH' if sort_by_length else 'WIDTH'}")
    print(f"TZD_REMOVED={6 if exclude_tzd else 0}")
    print(f"VAR_ITEMS={sum(item['var_width'] is not None for item in items)}")
    for color in COLORS:
        matching = [item for item in items if item["color"] == color]
        print(f"COLOR={color} COUNT={len(matching)} WIDTHS={sorted({item['width'] for item in matching})}")


def notes_only() -> None:
    """Make a new timestamped REV01, changing only item remarks to PPxx."""
    previous = (
        ROOT / "outputs" / "rfq_26092_rev01_20261014"
        / "BU2-DE-26092REV01 - MRT PURPLE LINE 4 STATION (PP17 - PP20)_20261014-1040.xlsm"
    )
    if not previous.is_file() or previous == OUTPUT:
        raise ValueError("The prior REV01 must exist and differ from the new output")
    book = openpyxl.load_workbook(previous, keep_vba=True)
    if book.sheetnames != [str(i) for i in range(1, 10)] + ["Sheet1"]:
        raise ValueError(f"Unexpected REV01 sheet structure: {book.sheetnames}")
    changes: dict[int, dict[int, str]] = {}
    for page in range(1, 10):
        sheet = book[str(page)]
        row_changes = {}
        for row in range(7, 27):
            number = sheet[f"A{row}"].value
            if number is None:
                continue
            if not isinstance(number, int):
                raise ValueError(f"Unexpected item number at {page}!A{row}")
            color = sheet[f"S{row}"].value or sheet[f"P{row}"].value
            if color not in STATION:
                raise ValueError(f"Unexpected finish for item {number}: {color}")
            expected = STATION[color]
            old_note = sheet[f"Z{row}"].value or ""
            if expected not in old_note:
                raise ValueError(f"Station mismatch for item {number}: {old_note}")
            row_changes[row] = expected
        changes[page] = row_changes
    if sum(len(rows) for rows in changes.values()) != 176:
        raise ValueError("Expected 176 notes to update")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(previous, "r") as original:
        modified = {}
        for page, rows in changes.items():
            part = f"xl/worksheets/sheet{page}.xml"
            root = etree.fromstring(original.read(part))
            cells = cell_map(root)
            for row, note in rows.items():
                put_text(cells[f"Z{row}"], note)
            modified[part] = xml_bytes(root)
        with zipfile.ZipFile(OUTPUT, "w") as result:
            for info in original.infolist():
                result.writestr(copy.copy(info), modified.get(info.filename, original.read(info.filename)))
    print(f"OUTPUT={OUTPUT}")
    print(f"SOURCE_SHA256={sha256(previous)}")
    print("NOTES_UPDATED=176")


if __name__ == "__main__":
    if sys.argv[1:] == ["--notes-only"]:
        notes_only()
    elif sys.argv[1:] == ["--rebuild-length-without-tzd"]:
        main(sort_by_length=True, exclude_tzd=True)
    elif sys.argv[1:] == ["--rebuild-length"]:
        main(sort_by_length=True)
    elif not sys.argv[1:]:
        main()
    else:
        raise SystemExit(
            "Usage: revise_rfq_26092_rev01.py "
            "[--notes-only|--rebuild-length|--rebuild-length-without-tzd]"
        )
