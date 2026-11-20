"""Build a two-page review copy of the supplied RFQ template.

The source XLSM and CSV are read only. The output is an XLSX review draft;
the original macro workbook remains untouched.
"""

from __future__ import annotations

import copy
import csv
import re
from pathlib import Path

from openpyxl import load_workbook
from openpyxl.formula.translate import Translator
from openpyxl.worksheet.cell_range import CellRange


ROOT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา")
TEMPLATE = ROOT / "BU2-DE-26091_โครงการ MRT PURPLE LINE 4 STATION ABOVE GROUND.xlsm"
SOURCE = Path(
    r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan"
    r"\PP-LINE_CL-PART\HOOK ON DOWNLIGHT SMOKE\HK MEP"
    r"\300HK ORDER FROM CHINA REV.2-LOT 2 FOR SMOKE LIGHT_REV04.csv"
)
OUT_DIR = ROOT / "outputs" / "rfq_preview_2pages_20261006"
OUTPUT = OUT_DIR / "RFQ_HK_MEP_ตัวอย่าง_2หน้า_40รายการ.xlsx"
PAGE_OFFSET = 89  # first page rows 1:45, second page rows 90:134


def read_source() -> list[dict[str, str]]:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) < 40:
        raise ValueError(f"Expected at least 40 CSV records, found {len(rows)}")
    return rows[:40]


def size_from_code(code: str) -> tuple[int, int]:
    match = re.match(r"^(\d{3})(\d+)HK-.*?/ACOUS-(STD|VAR(?:-(\d+))?)/", code)
    if not match:
        raise ValueError(f"Cannot interpret dimensions in part code: {code}")
    initial_width, length, variant, override_width = match.groups()
    width = int(override_width) if variant.startswith("VAR-") else int(initial_width)
    return width, int(length)


def copy_page_in_same_sheet(ws) -> None:
    original_merges = [
        copy.copy(merge)
        for merge in ws.merged_cells.ranges
        if merge.min_row >= 1 and merge.max_row <= 45 and merge.max_col <= 26
    ]
    for row in ws.iter_rows(min_row=1, max_row=45, min_col=1, max_col=26):
        for source_cell in row:
            target = ws.cell(source_cell.row + PAGE_OFFSET, source_cell.column)
            if source_cell.value is not None:
                if source_cell.data_type == "f":
                    target.value = Translator(source_cell.value, origin=source_cell.coordinate).translate_formula(target.coordinate)
                else:
                    target.value = source_cell.value
            target._style = copy.copy(source_cell._style)
            target.alignment = copy.copy(source_cell.alignment)
            target.protection = copy.copy(source_cell.protection)
            if source_cell.number_format:
                target.number_format = source_cell.number_format
        source_height = ws.row_dimensions[row[0].row].height
        if source_height is not None:
            ws.row_dimensions[row[0].row + PAGE_OFFSET].height = source_height
    for merge in original_merges:
        shifted = CellRange(
            min_col=merge.min_col,
            max_col=merge.max_col,
            min_row=merge.min_row + PAGE_OFFSET,
            max_row=merge.max_row + PAGE_OFFSET,
        )
        ws.merge_cells(str(shifted))


def clear_old_items(ws, offset: int) -> None:
    for start, end in ((7, 27), (31, 41)):
        for row in range(start + offset, end + offset + 1):
            for col in range(2, 27):
                cell = ws.cell(row, col)
                if cell.__class__.__name__ != "MergedCell":
                    cell.value = None
            ws.cell(row, 1).value = None
            ws.cell(row, 6).value = f'=IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,3,FALSE))'
            ws.cell(row, 7).value = f'=IF(E{row}="","",VLOOKUP(E{row},$AE$50:$AG$86,2,FALSE))'


def clear_old_headers(ws, offset: int, page_number: int) -> None:
    for address in ("Z1", "Z2", "V3", "W3", "X3", "C43", "C44", "H43", "H44"):
        original = ws[address]
        ws.cell(original.row + offset, original.column).value = None
    ws.cell(2 + offset, 3).value = "MRT PURPLE LINE 4STATION (PP17 - PP20)"
    ws.cell(3 + offset, 3).value = "CKST"
    ws.cell(45 + offset, 26).value = f"{page_number}/2"


def populate(ws, rows: list[dict[str, str]]) -> None:
    for index, record in enumerate(rows):
        offset = 0 if index < 20 else PAGE_OFFSET
        local_index = index if index < 20 else index - 20
        row = 7 + offset + local_index
        code = record["TTL_PJ_PART-CODE"].strip()
        width, length = size_from_code(code)
        finish = record["TTL_PJ_FINISH_1"].strip()
        sheet_no = record["TTL_PJ_SHEET_NO"].strip()

        ws.cell(row, 1).value = index + 1
        ws.cell(row, 2).value = f'{record["TTL_PJ_PART-NAME"].strip()} / {code}'
        ws.cell(row, 9).value = 1.2
        ws.cell(row, 10).value = "1100 H14"
        ws.cell(row, 11).value = width
        ws.cell(row, 13).value = length
        ws.cell(row, 11).number_format = "#,##0"
        ws.cell(row, 13).number_format = "#,##0"
        if finish.startswith("NS-"):
            ws.cell(row, 19).value = finish
            note = f"DWG {sheet_no.zfill(3)}"
        elif finish.startswith("Fameline ") and finish.endswith(" PC"):
            ws.cell(row, 20).value = "PC"
            ws.cell(row, 21).value = "Fameline"
            note = finish.removeprefix("Fameline ").removesuffix(" PC")
        else:
            note = finish
        ws.cell(row, 22).value = "1 ด้าน"
        ws.cell(row, 26).value = note


def main() -> None:
    rows = read_source()
    wb = load_workbook(TEMPLATE, keep_vba=False)
    ws = wb.active
    copy_page_in_same_sheet(ws)
    clear_old_items(ws, 0)
    clear_old_items(ws, PAGE_OFFSET)
    clear_old_headers(ws, 0, 1)
    clear_old_headers(ws, PAGE_OFFSET, 2)
    populate(ws, rows)

    for row in range(46, 90):
        ws.row_dimensions[row].hidden = True
    ws.print_area = ["A1:Z45", "A90:Z134"]
    ws.page_setup.orientation = "landscape"
    ws.page_setup.paperSize = ws.PAPERSIZE_A4
    ws.page_setup.fitToWidth = 1
    ws.page_setup.fitToHeight = 1
    ws.sheet_properties.pageSetUpPr.fitToPage = True
    ws.sheet_view.showGridLines = False
    wb.calculation.fullCalcOnLoad = True
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    wb.save(OUTPUT)
    print(OUTPUT)
    print(f"First: {rows[0]['TTL_PJ_PART-CODE']}; last: {rows[-1]['TTL_PJ_PART-CODE']}")
    print("Pages: 1/2, 2/2; 20 records per page; source template unchanged")


if __name__ == "__main__":
    main()
