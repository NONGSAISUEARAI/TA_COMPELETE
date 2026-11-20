"""Build a clean workbook from saved cell values and visible formatting."""

from __future__ import annotations

from copy import copy
from pathlib import Path
from zipfile import ZipFile

from openpyxl import Workbook, load_workbook
from openpyxl.cell.cell import MergedCell


OUTPUT_DIR = Path(__file__).resolve().parent
SOURCE = OUTPUT_DIR / "TOTAL_TRAY_REV03_backup_2026-11-20.xlsm"
TARGET = OUTPUT_DIR / "TOTAL_TRAY_REV03_data_recovered.xlsx"


def main() -> None:
    if TARGET.exists():
        raise FileExistsError(TARGET)

    old = load_workbook(SOURCE, data_only=True, read_only=False)
    new = Workbook()
    new.remove(new.active)
    style_cache = {}
    source_counts = {}

    for old_sheet in old.worksheets:
        new_sheet = new.create_sheet(old_sheet.title)
        new_sheet.sheet_properties = copy(old_sheet.sheet_properties)
        new_sheet.sheet_format = copy(old_sheet.sheet_format)
        new_sheet.sheet_view.showGridLines = old_sheet.sheet_view.showGridLines
        new_sheet.sheet_view.zoomScale = old_sheet.sheet_view.zoomScale
        new_sheet.freeze_panes = old_sheet.freeze_panes
        new_sheet.sheet_state = old_sheet.sheet_state
        new_sheet.page_margins = copy(old_sheet.page_margins)
        new_sheet.page_setup = copy(old_sheet.page_setup)
        new_sheet.print_options = copy(old_sheet.print_options)
        new_sheet.oddHeader = copy(old_sheet.oddHeader)
        new_sheet.oddFooter = copy(old_sheet.oddFooter)
        new_sheet.evenHeader = copy(old_sheet.evenHeader)
        new_sheet.evenFooter = copy(old_sheet.evenFooter)
        if old_sheet.print_area:
            new_sheet.print_area = old_sheet.print_area
        new_sheet.auto_filter = copy(old_sheet.auto_filter)

        for key, dimension in old_sheet.row_dimensions.items():
            new_sheet.row_dimensions[key] = copy(dimension)
            new_sheet.row_dimensions[key].parent = new_sheet
        for key, dimension in old_sheet.column_dimensions.items():
            new_sheet.column_dimensions[key] = copy(dimension)
            new_sheet.column_dimensions[key].parent = new_sheet

        nonempty = 0
        for (row, column), old_cell in old_sheet._cells.items():
            if isinstance(old_cell, MergedCell):
                continue
            new_cell = new_sheet.cell(row=row, column=column)
            if old_cell.value is not None:
                new_cell.value = old_cell.value
                if old_cell.value != "":
                    nonempty += 1
            if old_cell.has_style:
                style_key = (old_cell.style_id, old_cell.font.charset)
                if style_key not in style_cache:
                    new_cell.font = copy(old_cell.font)
                    new_cell.fill = copy(old_cell.fill)
                    new_cell.border = copy(old_cell.border)
                    new_cell.alignment = copy(old_cell.alignment)
                    new_cell.number_format = old_cell.number_format
                    new_cell.protection = copy(old_cell.protection)
                    style_cache[style_key] = copy(new_cell._style)
                else:
                    new_cell._style = copy(style_cache[style_key])
            if old_cell.comment is not None:
                new_cell.comment = copy(old_cell.comment)
            if old_cell.hyperlink is not None:
                new_cell.hyperlink = copy(old_cell.hyperlink)

        for merged_range in old_sheet.merged_cells.ranges:
            new_sheet.merge_cells(str(merged_range))

        source_counts[old_sheet.title] = nonempty
        print(old_sheet.title, "saved values", nonempty)

    new.save(TARGET)
    old.close()
    new.close()

    checked = load_workbook(TARGET, data_only=True, read_only=False)
    if list(checked.sheetnames) != list(source_counts):
        raise ValueError("Sheet names or order changed")
    for sheet in checked.worksheets:
        count = sum(cell.value not in (None, "") for cell in sheet._cells.values())
        if count != source_counts[sheet.title]:
            raise ValueError(f"Value count changed on {sheet.title}: {count}")
    checked.close()
    with ZipFile(TARGET) as archive:
        if archive.testzip() is not None:
            raise ValueError("Recovered workbook failed ZIP validation")
    print("Output:", TARGET)


if __name__ == "__main__":
    main()
