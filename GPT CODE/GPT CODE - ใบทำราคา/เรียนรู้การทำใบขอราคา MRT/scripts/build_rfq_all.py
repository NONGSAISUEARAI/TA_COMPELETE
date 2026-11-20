"""Populate a macro-preserving copy of the RFQ template from the supplied CSV."""

from __future__ import annotations

import copy
import csv
import math
import re
from datetime import datetime
from pathlib import Path

from openpyxl import load_workbook
from openpyxl.cell.cell import MergedCell


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
TEMPLATE = ROOT / "BU2-DE-26091_โครงการ MRT PURPLE LINE 4 STATION ABOVE GROUND.xlsm"
SOURCE = Path(
    r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan"
    r"\PP-LINE_CL-PART\HOOK ON DOWNLIGHT SMOKE\HK MEP"
    r"\300HK ORDER FROM CHINA REV.2-LOT 2 FOR SMOKE LIGHT_REV04.csv"
)
OUT = ROOT / "outputs" / "rfq_10_sheets_20261006" / "BU2-DE-26092_HK_MEP_186รายการ_10ชีต_NON-PF-S.xlsm"
ITEMS_PER_PAGE = 20


def dimensions(code: str) -> tuple[int | None, int | None]:
    match = re.match(r"^(\d{3})(\d+)HK-.*?/ACOUS-(STD|VAR(?:-(\d+))?)/", code)
    if not match:
        return None, None
    prefix_width, length, kind, override_width = match.groups()
    width = int(override_width) if kind.startswith("VAR-") else int(prefix_width)
    return width, int(length)


def set_item(ws, row: int, item_number: int, record: dict[str, str]) -> bool:
    code = record["TTL_PJ_PART-CODE"].strip()
    length_match = re.match(r"^300(\d+)HK-", code)
    if length_match is None:
        raise ValueError(f"Cannot read part-code length at item {item_number}: {code}")
    if int(length_match.group(1)) < 900:
        code = code.replace("/PF-S/", "/NON-PF-S/", 1)
    finish = record["TTL_PJ_FINISH_1"].strip()
    width, length = dimensions(code)
    notes = [f"DWG {record['TTL_PJ_SHEET_NO'].strip()}"]

    ws[f"A{row}"] = item_number
    ws[f"B{row}"] = f"{record['TTL_PJ_PART-NAME'].strip()} / {code}"
    ws[f"E{row}"] = 3  # 1100 H14, one-side paint, known color code
    ws[f"F{row}"] = f'=IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,3,FALSE))'
    ws[f"G{row}"] = f'=IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,2,FALSE))'
    ws[f"I{row}"] = 1.2
    ws[f"V{row}"] = "1 ด้าน"
    if width is not None:
        ws[f"K{row}"] = width
        ws[f"M{row}"] = length
    else:
        notes.append("ขนาด?")

    if finish == "Fameline SD-9103 PC":
        ws[f"P{row}"] = "SD-9103"
    elif finish in ("NS-1S-P0070", "NS-1S-E0114"):
        ws[f"S{row}"] = finish
        ws[f"T{row}"] = "PE  or PC"
        ws[f"U{row}"] = "Cornel"
    elif finish in ("S5206TH", "SW255TH"):
        ws[f"S{row}"] = finish
        ws[f"T{row}"] = "PE  or PC"
        ws[f"U{row}"] = "Akzo Nobel"
    elif finish == "xxx":
        ws[f"E{row}"] = None  # Cannot determine painted-stock code without a real color.
        notes.append("สี xxx?")
    else:
        raise ValueError(f"Unmapped finish at item {item_number}: {finish}")

    ws[f"Z{row}"] = "; ".join(notes)
    return width is None


def clear_template_items(ws) -> None:
    for first, last in ((7, 27), (31, 41)):
        for row in range(first, last + 1):
            for col in range(1, 27):
                cell = ws.cell(row, col)
                if not isinstance(cell, MergedCell):
                    cell.value = None
            ws[f"F{row}"] = f'=IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,3,FALSE))'
            ws[f"G{row}"] = f'=IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,2,FALSE))'


def main() -> None:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    if len(records) != 186:
        raise ValueError(f"Expected 186 source rows; got {len(records)}")

    book = load_workbook(TEMPLATE, keep_vba=True)
    template_ws = book["1"]
    page_count = math.ceil(len(records) / ITEMS_PER_PAGE)
    sheets = [template_ws]
    for page in range(1, page_count):
        new_ws = book.copy_worksheet(template_ws)
        new_ws.title = str(page + 1)
        # openpyxl copies cells/merges but not native validations or page settings.
        new_ws.data_validations = copy.deepcopy(template_ws.data_validations)
        new_ws.page_setup = copy.copy(template_ws.page_setup)
        new_ws.page_margins = copy.copy(template_ws.page_margins)
        new_ws.print_options = copy.copy(template_ws.print_options)
        new_ws.sheet_properties.pageSetUpPr = copy.copy(template_ws.sheet_properties.pageSetUpPr)
        sheets.append(new_ws)

    uncertain_dimensions = 0
    for page in range(page_count):
        ws = sheets[page]
        clear_template_items(ws)
        ws["Z1"] = "BU2-DE-26092"
        ws["V3"] = "20"
        ws["W3"] = "10"
        ws["X3"] = 69
        ws["C44"] = datetime(2026, 10, 6)
        ws["H44"] = None
        ws["Z45"] = f"{page + 1}/{page_count}"
        ws.print_area = "A1:Z45"
        ws.page_setup.fitToWidth = 1
        ws.page_setup.fitToHeight = 1
        ws.sheet_properties.pageSetUpPr.fitToPage = True
        for local_index in range(ITEMS_PER_PAGE):
            row = 7 + local_index
            item_index = page * ITEMS_PER_PAGE + local_index
            if item_index < len(records):
                uncertain_dimensions += set_item(ws, row, item_index + 1, records[item_index])

    book.calculation.fullCalcOnLoad = True
    OUT.parent.mkdir(parents=True, exist_ok=True)
    book.save(OUT)
    print("OUTPUT_SAVED=1")
    print(f"ROWS={len(records)} PAGES={page_count} TZD_DIMENSIONS_PENDING={uncertain_dimensions}")


if __name__ == "__main__":
    main()
