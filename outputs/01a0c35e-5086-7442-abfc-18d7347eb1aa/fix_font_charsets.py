"""Restore Thai font charset on recovered cells where it changed."""

from copy import copy
from pathlib import Path

from openpyxl import load_workbook


OUTPUT_DIR = Path(__file__).resolve().parent
SOURCE = OUTPUT_DIR / "TOTAL_TRAY_REV03_backup_2026-11-20.xlsm"
TARGET = OUTPUT_DIR / "TOTAL_TRAY_REV03_data_recovered.xlsx"
STAGING = OUTPUT_DIR / "TOTAL_TRAY_REV03_data_recovered_fontcheck.xlsx"


def main() -> None:
    if STAGING.exists():
        raise FileExistsError(STAGING)
    old = load_workbook(SOURCE, data_only=True)
    new = load_workbook(TARGET, data_only=True)
    changed = []
    for old_sheet, new_sheet in zip(old.worksheets, new.worksheets):
        for coordinate, old_cell in old_sheet._cells.items():
            new_cell = new_sheet._cells.get(coordinate)
            if new_cell and old_cell.font.charset != new_cell.font.charset:
                new_cell.font = copy(old_cell.font)
                changed.append((old_sheet.title, old_cell.coordinate, old_cell.font.charset))
    new.save(STAGING)
    old.close()
    new.close()

    checked = load_workbook(STAGING, data_only=True)
    failed = [
        item
        for item in changed
        if checked[item[0]][item[1]].font.charset != item[2]
    ]
    checked.close()
    print("Font charset cells corrected:", len(changed))
    print("Unresolved after save:", len(failed), failed[:5])
    if failed:
        return
    STAGING.replace(TARGET)
    print("Updated:", TARGET)


if __name__ == "__main__":
    main()
