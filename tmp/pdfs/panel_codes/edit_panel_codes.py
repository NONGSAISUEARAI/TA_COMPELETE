from pathlib import Path
import re
import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ContentStream, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\FL-PJ-25031-ALU-PANEL-PART-001-004_1250x2440_FILM-NOTE.pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-C06-PANEL-01_PART-001-004_1250x2440_FILM-NOTE.pdf'
NEW_CODE = 'PJ25-031-C06-PANEL-01'
PANEL_ENCODED = ''.join(chr(ord(c) - 29) for c in 'PANEL-STD01')

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
for index, page in enumerate(writer.pages):
    content = ContentStream(page.get_contents(), writer)
    first_line = second_line = 0
    for operands, operator in content.operations:
        if operator == b'Tj' and re.fullmatch(r'FL-PJ-25031-PP\d{2}-C06-', str(operands[0])):
            operands[0] = TextStringObject(NEW_CODE)
            first_line += 1
        elif operator == b"'" and str(operands[0]) == PANEL_ENCODED:
            # Preserve the text-line movement, but remove the obsolete second
            # line now that the full shortened code fits on the first line.
            operands[0] = TextStringObject('')
            second_line += 1
    assert (first_line, second_line) == (1, 1), (index + 1, first_line, second_line)
    page[NameObject('/Contents')] = writer._add_object(content)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(result.pages) == len(reader.pages) == 4
assert set(result.get_fields() or {}) == set(reader.get_fields() or {})
for original, edited in zip(reader.pages, result.pages):
    assert original.rotation == edited.rotation and list(original.mediabox) == list(edited.mediabox)
    for a, b in zip(original.get('/Annots', []), edited.get('/Annots', [])):
        a, b = a.get_object(), b.get_object()
        assert a.get('/T') == b.get('/T') and list(a['/Rect']) == list(b['/Rect'])
        assert a['/AP']['/N'].get_object().get_data() == b['/AP']['/N'].get_object().get_data()

with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    for index, (a, b) in enumerate(zip(before.pages, after.pages)):
        original, edited = a.extract_text(), b.extract_text()
        expected = re.sub(r'FL-PJ-25031-PP\d{2}-C06-\s+PANEL-STD01', NEW_CODE, original)
        assert edited.count(NEW_CODE) == 1
        assert 'PANEL-STD01' not in edited
        assert re.sub(r'\s+', '', expected) == re.sub(r'\s+', '', edited)
        print(f'Page {index + 1}: part code updated; other text, page geometry and signature appearance preserved')
print(OUTPUT)
