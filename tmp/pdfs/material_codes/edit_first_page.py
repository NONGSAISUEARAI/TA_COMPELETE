from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, ByteStringObject, ContentStream, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\BU2-DE-26093 - MRT PURPLE LINE 4STATION (PP17 - PP_261009_115634.pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'BU2-DE-26093_FIRST-PAGE_PART-CODE_FL-PJ25-031.pdf'
OLD = 'FL-PJ-26-031'
NEW = 'FL-PJ25-031'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
page = writer.pages[0]
stream = ContentStream(page.get_contents(), writer)
count = 0

for operands, operator in stream.operations:
    if operator != b'TJ':
        continue
    values = operands[0]
    indices = [i for i, v in enumerate(values) if isinstance(v, TextStringObject)]
    encoded = ''.join(str(values[i]) for i in indices)
    decoded = ''.join(chr(ord(c) + 29) for c in encoded)
    if OLD not in decoded:
        continue
    assert all(len(str(values[i])) == 1 for i in indices)
    start = decoded.index(OLD)
    # Keep the embedded font and all original kerning. Delete the hyphen after
    # PJ, and change the digit 6 to the digit 5, which the font already contains.
    delete_at = indices[start + 5]
    next_glyph = indices[start + 6]
    change_at = indices[start + 7]
    updated = []
    for i, value in enumerate(values):
        if delete_at <= i < next_glyph:
            continue
        updated.append(ByteStringObject(b'\x00\x18') if i == change_at else value)
    operands[0] = ArrayObject(updated)
    count += 1

assert count == 4, count
page[NameObject('/Contents')] = writer._add_object(stream)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(reader.pages) == len(result.pages) == 5
for i, (original, edited) in enumerate(zip(reader.pages, result.pages)):
    assert list(original.mediabox) == list(edited.mediabox)
    assert original.rotation == edited.rotation
    if i > 0:
        assert original.get_contents().get_data() == edited.get_contents().get_data()

with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    original = before.pages[0].extract_text()
    edited = after.pages[0].extract_text()
    assert OLD not in edited and edited.count(NEW) == 4
    assert re.sub(r'\s+', '', original.replace(OLD, NEW)) == re.sub(r'\s+', '', edited)
    assert 'PJ26-008' in edited
print('First page: 4 part codes changed; JO unchanged. Pages 2-5 content preserved exactly.')
print(OUTPUT)
