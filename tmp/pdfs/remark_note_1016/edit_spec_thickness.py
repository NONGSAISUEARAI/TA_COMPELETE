from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ByteStringObject, ContentStream, DecodedStreamObject, NameObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_REMARK-3.0mm_PART-CODE-UPDATED.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_3003-H14_2.0mm.pdf'
REPLACEMENTS = {'1100 H14': '3003 H14', '1.2 mm.': '2.0 mm.'}

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
for index, page in enumerate(writer.pages):
    content = ContentStream(page.get_contents(), writer)
    counts = dict.fromkeys(REPLACEMENTS, 0)
    for operands, operator in content.operations:
        if operator != b'Tj':
            continue
        decoded = ''.join(chr(ord(c) + 29) for c in str(operands[0]))
        if decoded in REPLACEMENTS:
            operands[0] = ByteStringObject(b''.join((ord(c) - 29).to_bytes(2, 'big') for c in REPLACEMENTS[decoded]))
            counts[decoded] += 1
    assert all(value == 1 for value in counts.values()), (index + 1, counts)
    replacement_stream = DecodedStreamObject()
    replacement_stream.set_data(content.get_data())
    page[NameObject('/Contents')] = writer._add_object(replacement_stream.flate_encode())
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(reader.pages) == len(result.pages) == 4
for a, b in zip(reader.pages, result.pages):
    assert list(a.mediabox) == list(b.mediabox) and a.rotation == b.rotation
    assert len(a.get('/Annots', [])) == len(b.get('/Annots', []))
with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    for index, (a, b) in enumerate(zip(before.pages, after.pages)):
        original, edited = a.extract_text(), b.extract_text()
        expected = original
        for old, new in REPLACEMENTS.items():
            expected = expected.replace(old, new)
        assert re.sub(r'\s+', '', expected) == re.sub(r'\s+', '', edited), index + 1
        assert '3003 H14' in edited and '2.0 mm.' in edited
        assert '1100 H14' not in edited and '1.2 mm.' not in edited
        assert '± 3.0mm.' in edited
        print(f'Page {index + 1}: SPEC 3003 H14; thickness 2.0 mm.; remaining text retained')
print(OUTPUT)
