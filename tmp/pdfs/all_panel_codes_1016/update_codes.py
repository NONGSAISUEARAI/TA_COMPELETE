from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ByteStringObject, ContentStream, DecodedStreamObject, NameObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_PART-CODE-ALL-PAGES.pdf'
CODE = 'PJ25-031-PANEL-01'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
for index, page in enumerate(writer.pages):
    content = ContentStream(page.get_contents(), writer)
    first = second = existing = 0
    for operands, operator in content.operations:
        if operator != b'Tj':
            continue
        decoded = ''.join(chr(ord(c) + 29) for c in str(operands[0]))
        if re.fullmatch(r'PJ25-031-PP\d{2}-', decoded):
            operands[0] = ByteStringObject(b''.join((ord(c) - 29).to_bytes(2, 'big') for c in CODE))
            first += 1
        elif decoded == 'PANEL-STD01':
            operands[0] = ByteStringObject(b'')
            second += 1
        elif decoded == CODE:
            existing += 1
    assert (first, second, existing) in [(1, 1, 0), (0, 0, 1)], (index + 1, first, second, existing)
    if first:
        replacement = DecodedStreamObject()
        replacement.set_data(content.get_data())
        page[NameObject('/Contents')] = writer._add_object(replacement.flate_encode())

with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(reader.pages) == len(result.pages) == 4
for a, b in zip(reader.pages, result.pages):
    assert list(a.mediabox) == list(b.mediabox) and a.rotation == b.rotation
with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    for index, (a, b) in enumerate(zip(before.pages, after.pages)):
        original, edited = a.extract_text(), b.extract_text()
        expected = re.sub(r'PJ25-031-PP\d{2}-\s*PANEL-STD01', CODE, original)
        assert edited.count(CODE) == 1 and 'PANEL-STD01' not in edited
        assert re.sub(r'\s+', '', expected) == re.sub(r'\s+', '', edited)
        print(f'Page {index + 1}: {CODE}; all other text retained')
print(OUTPUT)
