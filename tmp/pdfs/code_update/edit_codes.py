from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ContentStream, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PANEL-PART-001-004_1250x2440_FILM-NOTE.pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'FL-PJ-25031-ALU-PANEL-PART-001-004_1250x2440_FILM-NOTE.pdf'
OLD = 'FL-PJ-26-031'
NEW = 'FL-PJ-25031'
ENCODED_OLD = ''.join(chr(ord(c) - 29) for c in OLD)

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header

for index, page in enumerate(writer.pages):
    content = ContentStream(page.get_contents(), writer)
    updated = []
    active_font = None
    replacements = 0
    for operands, operator in content.operations:
        if operator == b'Tf':
            active_font = list(operands)
        if operator == b'Tj' and len(operands) == 1 and ENCODED_OLD in str(operands[0]):
            # These drafting strings encode glyph IDs with a constant offset.
            # Their subset fonts omit 5; Helvetica Bold supplies it at the
            # existing baseline and size. Restore each page's original font.
            decoded = ''.join(chr(ord(c) + 29) for c in str(operands[0]))
            assert decoded.startswith(OLD)
            updated.extend([
                ([NameObject('/F2'), active_font[1]], b'Tf'),
                ([TextStringObject(decoded.replace(OLD, NEW))], b'Tj'),
                (active_font, b'Tf'),
            ])
            replacements += 1
        else:
            updated.append((operands, operator))
    assert replacements == 3, (index + 1, replacements)
    content.operations = updated
    page[NameObject('/Contents')] = writer._add_object(content)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as stream:
    writer.write(stream)

result = PdfReader(OUTPUT)
assert len(result.pages) == len(reader.pages) == 4
assert set(result.get_fields() or {}) == set(reader.get_fields() or {})
for original, edited in zip(reader.pages, result.pages):
    assert original.rotation == edited.rotation
    assert list(original.mediabox) == list(edited.mediabox)
    for a, b in zip(original.get('/Annots', []), edited.get('/Annots', [])):
        a, b = a.get_object(), b.get_object()
        assert a.get('/T') == b.get('/T') and list(a['/Rect']) == list(b['/Rect'])
        assert a['/AP']['/N'].get_object().get_data() == b['/AP']['/N'].get_object().get_data()

with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    for i, (a, b) in enumerate(zip(before.pages, after.pages)):
        original, edited = a.extract_text(), b.extract_text()
        assert OLD not in edited and edited.count(NEW) == 3
        assert re.sub(r'\s+', '', original.replace(OLD, NEW)) == re.sub(r'\s+', '', edited)
        print(f'Page {i + 1}: all 3 codes updated; remaining text, page geometry and signature appearance preserved')
print(OUTPUT)
