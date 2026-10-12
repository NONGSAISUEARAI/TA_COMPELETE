from pathlib import Path
import re
import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ContentStream, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-C06-PANEL-01_PART-001-004_1250x2440_FILM-NOTE.pdf'
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'FL-PJ25-031_PART-001-004_1250x2440_FILM-NOTE.pdf'
OLD = 'FL-PJ-25031'
NEW = 'FL-PJ25-031'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
for i, page in enumerate(writer.pages):
    stream = ContentStream(page.get_contents(), writer)
    count = 0
    for operands, operator in stream.operations:
        if operator == b'Tj' and OLD in str(operands[0]):
            operands[0] = TextStringObject(str(operands[0]).replace(OLD, NEW))
            count += 1
    assert count == 2, (i + 1, count)
    page[NameObject('/Contents')] = writer._add_object(stream)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(result.pages) == len(reader.pages) == 4
assert set(result.get_fields() or {}) == set(reader.get_fields() or {})
for a, b in zip(reader.pages, result.pages):
    assert a.rotation == b.rotation and list(a.mediabox) == list(b.mediabox)
    for original, edited in zip(a.get('/Annots', []), b.get('/Annots', [])):
        original, edited = original.get_object(), edited.get_object()
        assert original.get('/T') == edited.get('/T') and list(original['/Rect']) == list(edited['/Rect'])
        assert original['/AP']['/N'].get_object().get_data() == edited['/AP']['/N'].get_object().get_data()
with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    for i, (a, b) in enumerate(zip(before.pages, after.pages)):
        original, edited = a.extract_text(), b.extract_text()
        assert OLD not in edited and edited.count(NEW) == 2
        assert edited.count('PJ25-031-C06-PANEL-01') == 1
        assert re.sub(r'\s+', '', original.replace(OLD, NEW)) == re.sub(r'\s+', '', edited)
        print(f'Page {i + 1}: project and drawing prefixes updated; corrected part code and other content retained')
print(OUTPUT)
