from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ByteStringObject, ContentStream, DecodedStreamObject, NameObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_3003-H14_2.0mm.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_1250x2440_3003-H14_2.0mm.pdf'
OLD = '1200x2400mm.'
NEW = '1250x2440mm.'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
for index, page in enumerate(writer.pages):
    content = ContentStream(page.get_contents(), writer)
    count = 0
    for operands, operator in content.operations:
        if operator != b'Tj':
            continue
        decoded = ''.join(chr(ord(c) + 29) for c in str(operands[0]))
        if decoded == OLD:
            operands[0] = ByteStringObject(b''.join((ord(c) - 29).to_bytes(2, 'big') for c in NEW))
            count += 1
    assert count == 1, (index + 1, count)
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
        assert re.sub(r'\s+', '', original.replace(OLD, NEW)) == re.sub(r'\s+', '', edited)
        assert OLD not in edited and edited.count(NEW) == 1
        assert '3003 H14' in edited and '2.0 mm.' in edited and '± 3.0mm.' in edited
        print(f'Page {index + 1}: sheet size updated; all other text preserved')
print(OUTPUT)
