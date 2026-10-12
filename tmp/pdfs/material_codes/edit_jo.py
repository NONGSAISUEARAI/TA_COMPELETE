from pathlib import Path
import re
import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, ByteStringObject, ContentStream, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'BU2-DE-26093_FIRST-PAGE_PART-CODE_FL-PJ25-031.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'BU2-DE-26093_FIRST-PAGE_PART-CODE_FL-PJ25-031_JO-PJ25-031.pdf'
OLD = 'PJ26-008'
NEW = 'PJ25-031'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
page = writer.pages[0]
content = ContentStream(page.get_contents(), writer)
count = 0
operations = []
active_font = None
for operands, operator in content.operations:
    if operator == b'Tf':
        active_font = list(operands)
    if operator != b'TJ':
        operations.append((operands, operator))
        continue
    values = operands[0]
    indices = [i for i, value in enumerate(values) if isinstance(value, TextStringObject)]
    decoded = ''.join(chr(ord(c) + 29) for i in indices for c in str(values[i]))
    if decoded != OLD:
        operations.append((operands, operator))
        continue
    assert len(indices) == len(NEW)
    updated = list(values)
    for character, i in zip(NEW, indices):
        updated[i] = ByteStringObject((ord(character) - 29).to_bytes(2, 'big'))
    # The Cordia New subset omits 5. Borrow just that digit from the embedded
    # CordiaUPC subset, which has the same numeric advance and Latin design.
    digit_five = indices[3]
    operations.extend([
        ([ArrayObject(updated[:digit_five])], b'TJ'),
        ([NameObject('/F4'), active_font[1]], b'Tf'),
        ([ArrayObject(updated[digit_five:digit_five + 1])], b'TJ'),
        (active_font, b'Tf'),
        ([ArrayObject(updated[digit_five + 1:])], b'TJ'),
    ])
    count += 1
assert count == 1, count
content.operations = operations
page[NameObject('/Contents')] = writer._add_object(content)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(result.pages) == len(reader.pages) == 5
for index, (a, b) in enumerate(zip(reader.pages, result.pages)):
    assert list(a.mediabox) == list(b.mediabox) and a.rotation == b.rotation
    if index > 0:
        assert a.get_contents().get_data() == b.get_contents().get_data()
with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    original, edited = before.pages[0].extract_text(), after.pages[0].extract_text()
    assert OLD not in edited and 'JO PJ25-031' in edited
    assert edited.count('FL-PJ25-031') == 4
    assert re.sub(r'\s+', '', original.replace(OLD, NEW)) == re.sub(r'\s+', '', edited)
print('JO updated on page 1; all four corrected part codes retained; pages 2-5 preserved exactly.')
print(OUTPUT)
