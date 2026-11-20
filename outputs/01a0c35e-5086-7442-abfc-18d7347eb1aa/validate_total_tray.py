"""Compare the rebuilt workbook with the source and inspect OOXML features."""

from __future__ import annotations

from pathlib import Path
import re
from zipfile import ZipFile

from openpyxl import load_workbook


OUTPUT_DIR = Path(__file__).resolve().parent
SOURCE = OUTPUT_DIR / "TOTAL_TRAY_REV03_backup_2026-11-20.xlsm"
CANDIDATE = OUTPUT_DIR / "TOTAL_TRAY_REV03_rebuilt.xlsm"


def comparable(value: object) -> object:
    if hasattr(value, "text") and hasattr(value, "ref"):
        return (type(value).__name__, value.text, value.ref)
    return value


def main() -> None:
    source = load_workbook(SOURCE, keep_vba=True, keep_links=True)
    candidate = load_workbook(CANDIDATE, keep_vba=True, keep_links=True)
    print("sheet_names_equal", source.sheetnames == candidate.sheetnames)
    print("defined_names", len(source.defined_names), len(candidate.defined_names))
    names_changed = [
        name
        for name in source.defined_names
        if name not in candidate.defined_names
        or source.defined_names[name].attr_text
        != candidate.defined_names[name].attr_text
    ]
    print("defined_names_changed", names_changed[:10], "count", len(names_changed))
    print("workbook_code_name", source.code_name, candidate.code_name)

    value_mismatches = []
    style_mismatches = []
    comment_mismatches = []
    for old_sheet, new_sheet in zip(source.worksheets, candidate.worksheets):
        print(
            "sheet_properties",
            old_sheet.title,
            "code_names",
            old_sheet.sheet_properties.codeName,
            new_sheet.sheet_properties.codeName,
            "print_area",
            str(old_sheet.print_area),
            str(new_sheet.print_area),
            "page_orientation",
            old_sheet.page_setup.orientation,
            new_sheet.page_setup.orientation,
            "freeze_panes",
            str(old_sheet.freeze_panes),
            str(new_sheet.freeze_panes),
        )
        coordinates = set(old_sheet._cells) | set(new_sheet._cells)
        for coordinate in coordinates:
            old = old_sheet._cells.get(coordinate)
            new = new_sheet._cells.get(coordinate)
            old_value = comparable(old.value) if old else None
            new_value = comparable(new.value) if new else None
            if old_value != new_value:
                value_mismatches.append((old_sheet.title, coordinate, old_value, new_value))
            if (old._style if old else None) != (new._style if new else None):
                style_mismatches.append((old_sheet.title, coordinate))
            old_comment = (old.comment.text, old.comment.author) if old and old.comment else None
            new_comment = (new.comment.text, new.comment.author) if new and new.comment else None
            if old_comment != new_comment:
                comment_mismatches.append((old_sheet.title, coordinate))
        print(
            "sheet",
            old_sheet.title,
            "dimensions",
            (old_sheet.max_row, old_sheet.max_column),
            (new_sheet.max_row, new_sheet.max_column),
            "conditional_formatting",
            len(old_sheet.conditional_formatting),
            len(new_sheet.conditional_formatting),
        )
    print("value_mismatches", len(value_mismatches), value_mismatches[:5])
    substantive = []
    for item in value_mismatches:
        old_value, new_value = item[2], item[3]
        if old_value in (None, "") and new_value in (None, ""):
            continue
        if isinstance(old_value, (int, float)) and isinstance(new_value, (int, float)):
            if abs(old_value - new_value) <= 1e-12 * max(1, abs(old_value)):
                continue
        substantive.append(item)
    print("substantive_value_mismatches", len(substantive), substantive[:5])
    print("style_mismatches", len(style_mismatches), style_mismatches[:5])
    print("comment_mismatches", len(comment_mismatches), comment_mismatches[:5])
    source.close()
    candidate.close()

    with ZipFile(SOURCE) as old_zip, ZipFile(CANDIDATE) as new_zip:
        old_names = set(old_zip.namelist())
        new_names = set(new_zip.namelist())
        print("removed_parts", sorted(old_names - new_names))
        print("added_parts", sorted(new_names - old_names))
        print("vba_same", old_zip.read("xl/vbaProject.bin") == new_zip.read("xl/vbaProject.bin"))
        print("zip_crc_error", new_zip.testzip())
        for label, archive in (("source", old_zip), ("candidate", new_zip)):
            sheet_xml = [
                part
                for part in archive.namelist()
                if part.startswith("xl/worksheets/sheet") and part.endswith(".xml")
            ]
            print(
                label,
                "metadata",
                "xl/metadata.xml" in archive.namelist(),
                "array_formulas",
                sum(archive.read(part).count(b't="array"') for part in sheet_xml),
                "cell_metadata",
                sum(archive.read(part).count(b' cm="') for part in sheet_xml),
            )
            print(
                label,
                "cell_metadata_ids",
                sorted({
                    value.decode("ascii")
                    for part in sheet_xml
                    for value in re.findall(rb'\bcm="([0-9]+)"', archive.read(part))
                }),
            )
        print("source_metadata_xml", old_zip.read("xl/metadata.xml").decode("utf-8"))


if __name__ == "__main__":
    main()
