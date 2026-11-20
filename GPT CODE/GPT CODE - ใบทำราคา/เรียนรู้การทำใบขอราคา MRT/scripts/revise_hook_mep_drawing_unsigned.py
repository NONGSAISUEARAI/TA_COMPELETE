"""Create an unsigned revised copy of the 170-page hook-on-panel drawing.

Only the MATERIAL value and the leading width of ACOUS-VAR-xxx part codes are
changed. The signed source PDF is read-only and is never overwritten.
"""

from __future__ import annotations

import re
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import DecodedStreamObject, NameObject


SOURCE = Path(r"C:\Users\tawan.t\Downloads\PJ25-031-HK-MEP-PART-001-170.pdf")
OUT_DIR = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา\outputs\hook_mep_drawing_unsigned")
OUTPUT = OUT_DIR / "PJ25-031-HK-MEP-PART-001-170_ALUMINIUM_VAR-WIDTH_UNSIGNED.pdf"
TEMP = OUT_DIR / "PJ25-031-HK-MEP-PART-001-170_ALUMINIUM_VAR-WIDTH_UNSIGNED.part.pdf"

OLD_MATERIAL = bytes.fromhex(
    "0024004f00580011004b00520052004e00030052005100030033004400510048004f"
)
VAR_PATTERN = re.compile(r"(\d{3})(\d+)HK-A/PF-S/ACOUS-\s*VAR-(\d+)/")


def font_codes(page) -> dict[str, int]:
    candidates = [
        value.get_object()
        for value in page["/Resources"]["/Font"].values()
        if "Swiss721BT-Bold" in str(value.get_object().get("/BaseFont"))
    ]
    if len(candidates) != 1:
        raise ValueError("Expected exactly one Swiss721BT-Bold font on every page")
    cmap = candidates[0]["/ToUnicode"].get_object().get_data()
    mapping: dict[str, int] = {}
    for first_hex, last_hex, base_hex in re.findall(
        rb"<([0-9A-Fa-f]{4})><([0-9A-Fa-f]{4})><([0-9A-Fa-f]{4})>", cmap
    ):
        first = int(first_hex, 16)
        last = int(last_hex, 16)
        base = int(base_hex, 16)
        for code in range(first, last + 1):
            mapping[chr(base + code - first)] = code
    return mapping


def encode(text: str, codes: dict[str, int]) -> bytes:
    missing = set(text) - set(codes)
    if missing:
        raise ValueError(f"Font lacks glyphs needed for {text!r}: {sorted(missing)}")
    return b"".join(codes[char].to_bytes(2, "big") for char in text)


def revised_stream(page, number: int) -> tuple[bytes, tuple[str, str] | None]:
    data = page.get_contents().get_data()
    if data.count(OLD_MATERIAL) != 2:
        raise ValueError(f"Page {number}: expected part name and material exactly twice")
    codes = font_codes(page)
    if encode("Alu.hook on Panel", codes) != OLD_MATERIAL:
        raise ValueError(f"Page {number}: source material font mapping differs")

    # First instance is PART NAME; second instance is MATERIAL.
    first = data.index(OLD_MATERIAL)
    second = data.index(OLD_MATERIAL, first + len(OLD_MATERIAL))
    if data[first + len(OLD_MATERIAL) : first + len(OLD_MATERIAL) + 3] != b")Tj":
        raise ValueError(f"Page {number}: first instance is not PART NAME")
    if data[second + len(OLD_MATERIAL) : second + len(OLD_MATERIAL) + 2] != b")'":
        raise ValueError(f"Page {number}: second instance is not MATERIAL")
    updated = data[:second] + encode("ALUMINIUM", codes) + data[second + len(OLD_MATERIAL) :]

    text = page.extract_text() or ""
    matches = list(VAR_PATTERN.finditer(text))
    if len(matches) > 1:
        raise ValueError(f"Page {number}: multiple VAR part codes")
    changed_code = None
    if matches:
        width, length, override = matches[0].groups()
        if width != override:
            old_line = f"{width}{length}HK-A/PF-S/ACOUS-"
            new_line = f"{override}{length}HK-A/PF-S/ACOUS-"
            # CID 0x0029 (the letter F) is escaped as ``\)`` inside the PDF
            # literal string, so match the unique prefix only through ``/P``.
            old_bytes = encode(f"{width}{length}HK-A/P", codes)
            new_bytes = encode(f"{override}{length}HK-A/P", codes)
            if updated.count(old_bytes) != 1:
                raise ValueError(f"Page {number}: part-code prefix is not unique")
            updated = updated.replace(old_bytes, new_bytes, 1)
            changed_code = (old_line, new_line)
    return updated, changed_code


def main() -> None:
    if OUTPUT.exists() or TEMP.exists():
        raise FileExistsError("Output already exists; inspect it before re-running")
    reader = PdfReader(SOURCE)
    if len(reader.pages) != 170:
        raise ValueError(f"Unexpected source page count: {len(reader.pages)}")
    fields = reader.get_fields() or {}
    if len(fields) != 170 or any(str(field.get("/FT")) != "/Sig" for field in fields.values()):
        raise ValueError("Source signature fields differ from the inspected 170-page file")
    if any(
        len(page.get("/Annots") or []) != 1
        or str((page.get("/Annots") or [])[0].get_object().get("/Subtype")) != "/Widget"
        for page in reader.pages
    ):
        raise ValueError("Source annotations differ from one signature widget per page")

    streams: list[bytes] = []
    changes: dict[int, tuple[str, str]] = {}
    var_pages = 0
    for number, page in enumerate(reader.pages, 1):
        text = page.extract_text() or ""
        if len(VAR_PATTERN.findall(text)) == 1:
            var_pages += 1
        stream, code_change = revised_stream(page, number)
        streams.append(stream)
        if code_change:
            changes[number] = code_change
    if var_pages != 16 or len(changes) != 11:
        raise ValueError(f"Unexpected VAR coverage: {var_pages} pages; {len(changes)} changes")

    writer = PdfWriter()
    writer.clone_document_from_reader(reader)
    for page, data in zip(writer.pages, streams, strict=True):
        replacement = DecodedStreamObject()
        replacement.set_data(data)
        page[NameObject("/Contents")] = writer._add_object(replacement.flate_encode())

    # The source has 170 signed widgets. This is a new, deliberately unsigned
    # revision: remove their visible appearances and canonical signature tree.
    writer.remove_annotations(subtypes="/Widget")
    writer.root_object.pop(NameObject("/AcroForm"), None)
    writer.root_object.pop(NameObject("/Perms"), None)
    writer.add_metadata({"/Subject": "Revised drawing - unsigned"})

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with TEMP.open("wb") as stream:
        writer.write(stream)

    result = PdfReader(TEMP)
    if len(result.pages) != 170 or result.get_fields():
        raise ValueError("Saved revision has wrong pages or still has form fields")
    for number, page in enumerate(result.pages, 1):
        if page.get("/Annots"):
            raise ValueError(f"Page {number}: annotation remains in unsigned copy")
        text = page.extract_text() or ""
        if text.count("ALUMINIUM") != 1 or text.count("Alu.hook on Panel") != 1:
            raise ValueError(f"Page {number}: MATERIAL replacement did not verify")
        if number in changes:
            old_line, new_line = changes[number]
            if new_line not in text or old_line in text:
                raise ValueError(f"Page {number}: VAR width replacement did not verify")
    TEMP.rename(OUTPUT)
    print(f"OUTPUT={OUTPUT.name}")
    print(f"PAGES=170 MATERIAL_CHANGES=170 VAR_PAGES=16 CODE_CHANGES={len(changes)}")
    print("CODE_CHANGE_PAGES=" + ",".join(map(str, changes)))
    print("SIGNATURE_FIELDS=0 SIGNATURE_WIDGETS=0")


if __name__ == "__main__":
    main()
