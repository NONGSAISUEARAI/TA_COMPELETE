"""Repair the D2 formula's Excel dynamic-array metadata without rewriting the workbook."""

from __future__ import annotations

import io
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from openpyxl import load_workbook


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "Item_Category_FG_On_Hand_Example.xlsx"
TARGET = HERE / "Item_Category_FG_On_Hand_Spill.xlsx"
SHEET_XML = "xl/worksheets/sheet2.xml"
REL_XML = "xl/_rels/workbook.xml.rels"
TYPE_XML = "[Content_Types].xml"
META_XML = "xl/metadata.xml"

METADATA = b'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<metadata xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:xda="http://schemas.microsoft.com/office/spreadsheetml/2017/dynamicarray"><metadataTypes count="1"><metadataType name="XLDAPR" minSupportedVersion="120000" copy="1" pasteAll="1" pasteValues="1" merge="1" splitFirst="1" rowColShift="1" clearFormats="1" clearComments="1" assign="1" coerce="1" cellMeta="1"/></metadataTypes><futureMetadata name="XLDAPR" count="1"><bk><extLst><ext uri="{bdbb8cdc-fa1e-496e-a857-3c3f30c029c3}"><xda:dynamicArrayProperties fDynamic="1" fCollapsed="0"/></ext></extLst></bk></futureMetadata><cellMetadata count="1"><bk><rc t="1" v="0"/></bk></cellMetadata></metadata>'''


def replace_one(data: bytes, pattern: bytes, replacement: bytes) -> bytes:
    result, count = re.subn(pattern, replacement, data, flags=re.DOTALL)
    if count != 1:
        raise ValueError(f"Expected one replacement for {pattern!r}, found {count}")
    return result


def repair_cell(sheet_data: bytes) -> bytes:
    match = re.search(rb'<c\b[^>]*\br="D2"[^>]*>.*?</c>', sheet_data, re.DOTALL)
    if not match:
        raise ValueError("Cell D2 was not found in Total On Hand")
    old = match.group(0)
    if b"_xlfn._xlws.FILTER" not in old or b"TRANSPOSE" not in old:
        raise ValueError("D2 does not contain the expected horizontal filter formula")
    new = re.sub(rb'\s+t="[^"]*"', b"", old, count=1)
    new = replace_one(new, rb'<c\b([^>]*)>', rb'<c\1 cm="1">')
    new = replace_one(new, rb'<f(?:\s[^>]*)?>', b'<f t="array" ref="D2">')
    new = replace_one(new, rb'<v>.*?</v>', b'<v>0</v>')
    return sheet_data[: match.start()] + new + sheet_data[match.end() :]


def add_metadata_relationship(rel_data: bytes) -> bytes:
    ids = [int(value) for value in re.findall(rb'\bId="rId(\d+)"', rel_data)]
    next_id = max(ids, default=0) + 1
    relation = (
        f'<Relationship Id="rId{next_id}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sheetMetadata" '
        'Target="metadata.xml"/>'
    ).encode("ascii")
    return replace_one(rel_data, rb'</Relationships>', relation + b'</Relationships>')


def add_metadata_content_type(type_data: bytes) -> bytes:
    override = (
        b'<Override PartName="/xl/metadata.xml" '
        b'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml"/>'
    )
    return replace_one(type_data, rb'</Types>', override + b'</Types>')


def main() -> None:
    source_workbook = load_workbook(SOURCE, read_only=True, data_only=False)
    sheet = source_workbook["Total On Hand"]
    if sheet["A2"].value != "FG30503":
        raise ValueError("A2 has changed; inspect the current workbook before repairing")
    expected = sorted(
        {
            str(cell[0])
            for cell in sheet.iter_rows(min_row=2, min_col=3, max_col=3, values_only=True)
            if cell[0] is not None and str(cell[0]).startswith(sheet["A2"].value)
        }
    )
    source_workbook.close()

    with ZipFile(SOURCE) as source_zip:
        if META_XML in source_zip.namelist():
            raise ValueError("The source already contains cell metadata; stop to avoid replacing it")
        modified = {
            SHEET_XML: repair_cell(source_zip.read(SHEET_XML)),
            REL_XML: add_metadata_relationship(source_zip.read(REL_XML)),
            TYPE_XML: add_metadata_content_type(source_zip.read(TYPE_XML)),
        }
        with ZipFile(TARGET, "w") as target_zip:
            for member in source_zip.infolist():
                target_zip.writestr(member, modified.get(member.filename, source_zip.read(member.filename)))
            target_zip.writestr(META_XML, METADATA, compress_type=ZIP_DEFLATED)

    with ZipFile(TARGET) as checked_zip:
        if checked_zip.testzip() is not None:
            raise ValueError("The repaired workbook ZIP did not pass integrity checks")
        cell_match = re.search(rb'<c\b[^>]*\br="D2"[^>]*>.*?</c>', checked_zip.read(SHEET_XML), re.DOTALL)
        if not cell_match or b'cm="1"' not in cell_match.group(0) or b'<f t="array" ref="D2">' not in cell_match.group(0):
            raise ValueError("The repaired D2 dynamic formula is incomplete")
        for key in (META_XML, REL_XML, TYPE_XML):
            if not checked_zip.read(key):
                raise ValueError(f"Missing required workbook part: {key}")

    checked_workbook = load_workbook(TARGET, read_only=True, data_only=False)
    checked_sheet = checked_workbook["Total On Hand"]
    if [checked_sheet[f"C{row}"].value for row in range(2, 6)] != [
        "FG30503", "FG305032", "FG305032135", "FG30503124214"
    ]:
        raise ValueError("The source values were not preserved")
    checked_workbook.close()
    print(f"Output: {TARGET}")
    print(f"Expected spill items ({len(expected)}): {expected}")


if __name__ == "__main__":
    main()
