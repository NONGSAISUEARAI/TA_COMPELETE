"""Rebuild the macro workbook from parsed cells, formulas, and workbook objects."""

from __future__ import annotations

import warnings
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from openpyxl import load_workbook


OUTPUT_DIR = Path(__file__).resolve().parent
SOURCE = OUTPUT_DIR / "TOTAL_TRAY_REV03_backup_2026-11-20.xlsm"
CANDIDATE = OUTPUT_DIR / "TOTAL_TRAY_REV03_rebuilt_candidate.xlsm"
FINAL = OUTPUT_DIR / "TOTAL_TRAY_REV03_rebuilt.xlsm"


def replace_one(data: bytes, pattern: bytes, replacement: bytes) -> bytes:
    updated, count = re.subn(pattern, replacement, data, count=1)
    if count != 1:
        raise ValueError(f"Expected one XML replacement for {pattern!r}, got {count}")
    return updated


def restore_cell_metadata(original_sheet: bytes, rebuilt_sheet: bytes) -> bytes:
    metadata_by_address: dict[bytes, bytes] = {}
    for match in re.finditer(rb"<c\b[^>]*>", original_sheet):
        tag = match.group(0)
        cell = re.search(rb'\br="([^"]+)"', tag)
        metadata = re.search(rb'\bcm="([^"]+)"', tag)
        if cell and metadata:
            metadata_by_address[cell.group(1)] = metadata.group(1)

    restored = 0

    def add_metadata(match: re.Match[bytes]) -> bytes:
        nonlocal restored
        tag = match.group(0)
        cell = re.search(rb'\br="([^"]+)"', tag)
        if not cell or cell.group(1) not in metadata_by_address:
            return tag
        if tag.endswith(b"/>") or b" cm=" in tag:
            raise ValueError(f"Unexpected existing or empty metadata cell: {cell.group(1)!r}")
        restored += 1
        return tag[:-1] + b' cm="' + metadata_by_address[cell.group(1)] + b'">'

    result = re.sub(rb"<c\b[^>]*>", add_metadata, rebuilt_sheet)
    if restored != len(metadata_by_address):
        raise ValueError(f"Restored {restored} of {len(metadata_by_address)} dynamic cells")
    return result


def add_metadata_relationship(relationships: bytes) -> bytes:
    ids = [int(value) for value in re.findall(rb'\bId="rId(\d+)"', relationships)]
    next_id = max(ids, default=0) + 1
    relation = (
        f'<Relationship Id="rId{next_id}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sheetMetadata" '
        'Target="metadata.xml"/>'
    ).encode("ascii")
    return replace_one(relationships, rb"</Relationships>", relation + b"</Relationships>")


def add_metadata_content_type(content_types: bytes) -> bytes:
    override = (
        b'<Override PartName="/xl/metadata.xml" '
        b'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml"/>'
    )
    return replace_one(content_types, rb"</Types>", override + b"</Types>")


def main() -> None:
    if FINAL.exists():
        raise FileExistsError(FINAL)

    if not CANDIDATE.exists():
        with warnings.catch_warnings(record=True) as seen:
            warnings.simplefilter("always")
            workbook = load_workbook(
                SOURCE, keep_vba=True, keep_links=True, data_only=False
            )
            workbook.calculation.fullCalcOnLoad = True
            workbook.calculation.forceFullCalc = True
            workbook.save(CANDIDATE)
            workbook.close()
        for warning in seen:
            print("Warning:", warning.message)

    with ZipFile(SOURCE) as original_zip, ZipFile(CANDIDATE) as rebuilt_zip:
        patched: dict[str, bytes] = {}
        for index in range(1, 11):
            part = f"xl/worksheets/sheet{index}.xml"
            patched[part] = restore_cell_metadata(
                original_zip.read(part), rebuilt_zip.read(part)
            )
        patched["xl/_rels/workbook.xml.rels"] = add_metadata_relationship(
            rebuilt_zip.read("xl/_rels/workbook.xml.rels")
        )
        patched["[Content_Types].xml"] = add_metadata_content_type(
            rebuilt_zip.read("[Content_Types].xml")
        )

        with ZipFile(FINAL, "w") as final_zip:
            for part in rebuilt_zip.infolist():
                final_zip.writestr(
                    part, patched.get(part.filename, rebuilt_zip.read(part.filename))
                )
            final_zip.writestr(
                "xl/metadata.xml",
                original_zip.read("xl/metadata.xml"),
                compress_type=ZIP_DEFLATED,
            )

    with ZipFile(FINAL) as checked:
        if checked.testzip() is not None:
            raise ValueError("Rebuilt workbook failed ZIP integrity validation")
        dynamic_cells = sum(
            checked.read(f"xl/worksheets/sheet{index}.xml").count(b' cm="')
            for index in range(1, 11)
        )
        if dynamic_cells != 2689:
            raise ValueError(f"Expected 2689 dynamic cells, found {dynamic_cells}")
    print("Final:", FINAL)
    print("Dynamic array cells restored:", dynamic_cells)


if __name__ == "__main__":
    main()
