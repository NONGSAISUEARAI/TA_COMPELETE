from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ByteStringObject, ContentStream, DecodedStreamObject, NameObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_REMARK-3.0mm.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_REMARK-3.0mm_PART-CODE-UPDATED.pdf'
NEW_CODE = 'PJ25-031-PANEL-01'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
page = writer.pages[0]
content = ContentStream(page.get_contents(), writer)
first = second = 0
for operands, operator in content.operations:
    if operator != b'Tj':
        continue
    decoded = ''.join(chr(ord(character) + 29) for character in str(operands[0]))
    if decoded == 'PJ25-031-PP17-':
        operands[0] = ByteStringObject(b''.join((ord(c) - 29).to_bytes(2, 'big') for c in NEW_CODE))
        first += 1
    elif decoded == 'PANEL-STD01':
        operands[0] = ByteStringObject(b'')
        second += 1
assert (first, second) == (1, 1), (first, second)
replacement_stream = DecodedStreamObject()
replacement_stream.set_data(content.get_data())
page[NameObject('/Contents')] = writer._add_object(replacement_stream.flate_encode())
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(reader.pages) == len(result.pages) == 4
for index, (a, b) in enumerate(zip(reader.pages, result.pages)):
    assert list(a.mediabox) == list(b.mediabox) and a.rotation == b.rotation
    if index:
        assert a.get_contents().get_data() == b.get_contents().get_data()

with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    original, edited = before.pages[0].extract_text(), after.pages[0].extract_text()
    expected = re.sub(r'PJ25-031-PP17-\s+PANEL-STD01', NEW_CODE, original)
    assert re.sub(r'\s+', '', expected) == re.sub(r'\s+', '', edited)
    assert 'PJ25-031-PP17-' not in edited and NEW_CODE in edited
    assert '± 3.0mm.' in edited
print('Page 1: specified Part Code replaced; ± 3.0mm. remark retained. Pages 2-4 unchanged.')
print(OUTPUT)
