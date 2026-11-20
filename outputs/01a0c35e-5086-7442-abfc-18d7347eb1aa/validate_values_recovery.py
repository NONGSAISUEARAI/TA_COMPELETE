"""Check the clean values workbook against cached values in the backup."""

from pathlib import Path
from copy import copy

from openpyxl import load_workbook


OUTPUT_DIR = Path(__file__).resolve().parent
SOURCE = OUTPUT_DIR / "TOTAL_TRAY_REV03_backup_2026-11-20.xlsm"
TARGET = OUTPUT_DIR / "TOTAL_TRAY_REV03_data_recovered.xlsx"


def same_value(old: object, new: object) -> bool:
    if old in (None, "") and new in (None, ""):
        return True
    if isinstance(old, (int, float)) and isinstance(new, (int, float)):
        return abs(old - new) <= 1e-12 * max(1, abs(old))
    return old == new


def main() -> None:
    original = load_workbook(SOURCE, data_only=True)
    recovered = load_workbook(TARGET, data_only=True)
    if original.sheetnames != recovered.sheetnames:
        raise ValueError("Sheet list differs")
    mismatches = []
    style_mismatches = []
    comment_mismatches = []
    for old_sheet, new_sheet in zip(original.worksheets, recovered.worksheets):
        coordinates = set(old_sheet._cells) | set(new_sheet._cells)
        for coordinate in coordinates:
            old = old_sheet._cells.get(coordinate)
            new = new_sheet._cells.get(coordinate)
            if not same_value(old.value if old else None, new.value if new else None):
                mismatches.append((old_sheet.title, coordinate, old.value if old else None, new.value if new else None))
            if old and new:
                style_equal = (
                    copy(old.font) == copy(new.font)
                    and copy(old.fill) == copy(new.fill)
                    and copy(old.border) == copy(new.border)
                    and copy(old.alignment) == copy(new.alignment)
                    and old.number_format == new.number_format
                    and copy(old.protection) == copy(new.protection)
                )
            else:
                style_equal = not (old and old.has_style) and not (new and new.has_style)
            if not style_equal:
                style_mismatches.append((old_sheet.title, coordinate))
            old_comment = (old.comment.text, old.comment.author) if old and old.comment else None
            new_comment = (new.comment.text, new.comment.author) if new and new.comment else None
            if old_comment != new_comment:
                comment_mismatches.append((old_sheet.title, coordinate))
    original.close()
    recovered.close()
    print("value_mismatches", len(mismatches), mismatches[:5])
    print("style_mismatches", len(style_mismatches), style_mismatches[:5])
    print("comment_mismatches", len(comment_mismatches), comment_mismatches[:5])


if __name__ == "__main__":
    main()
