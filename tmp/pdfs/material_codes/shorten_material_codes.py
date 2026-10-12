from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, ByteStringObject, ContentStream, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'BU2-DE-26093_FIRST-PAGE_PART-CODE_FL-PJ25-031_JO-PJ25-031.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'BU2-DE-26093_FIRST-PAGE_1250x2440_PJ25-031-C06-PANEL-01.pdf'
NEW_LINE = 'Alu.2.0mm.thk. Sheet 1250x2440mm. / PJ25-031-C06-PANEL-01'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
page = writer.pages[0]
content = ContentStream(page.get_contents(), writer)
active_font = None
count = 0
for operands, operator in content.operations:
    if operator == b'Tf':
        active_font = str(operands[0])
    if operator != b'TJ' or active_font != '/F4':
        continue
    values = operands[0]
    indices = [i for i, value in enumerate(values) if isinstance(value, TextStringObject)]
    decoded = ''.join(chr(ord(c) + 29) for i in indices for c in str(values[i]))
    if not decoded.startswith('Alu.2.0mm.thk. Sheet 1200x2400mm. / FL-PJ25-031-PP'):
        continue
    assert all(len(str(values[i])) == 1 for i in indices)
    deletions = set()
    for match in re.finditer(r'FL-|PP\d{2}-|STD', decoded):
        deletions.update(range(match.start(), match.end()))
    replacements = {}
    dimension = decoded.index('1200x2400')
    for offset, character in enumerate('1250x2440'):
        replacements[dimension + offset] = character
    updated = []
    for position, i in enumerate(indices):
        if position in deletions:
            continue
        next_index = indices[position + 1] if position + 1 < len(indices) else len(values)
        glyph = ByteStringObject((ord(replacements[position]) - 29).to_bytes(2, 'big')) if position in replacements else values[i]
        updated.append(glyph)
        updated.extend(values[i + 1:next_index])
    operands[0] = ArrayObject(updated)
    count += 1
assert count == 4, count
page[NameObject('/Contents')] = writer._add_object(content)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(reader.pages) == len(result.pages) == 5
for i, (a, b) in enumerate(zip(reader.pages, result.pages)):
    assert list(a.mediabox) == list(b.mediabox) and a.rotation == b.rotation
    if i > 0:
        assert a.get_contents().get_data() == b.get_contents().get_data()
with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    original, edited = before.pages[0].extract_text(), after.pages[0].extract_text()
    expected = re.sub(r'Alu\.2\.0mm\.thk\. Sheet 1200x2400mm\. / FL-PJ25-031-PP\d{2}-C06-PANEL-STD01', NEW_LINE, original)
    assert edited.count(NEW_LINE) == 4
    assert re.sub(r'\s+', '', expected) == re.sub(r'\s+', '', edited)
    assert 'JO PJ25-031' in edited
print('Page 1: all four material descriptions updated to the exact example; JO preserved; pages 2-5 unchanged.')
print(OUTPUT)
