from io import BytesIO
from pathlib import Path

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ContentStream, NameObject, FloatObject, TextStringObject
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PANEL-PART-[001-004]_FINISH-UPDATED.pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'FL-PJ-26-031-ALU-PANEL-PART-001-004_1250x2440_FILM-NOTE.pdf'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
pdfmetrics.registerFont(TTFont('ThaiNote', r'C:\Windows\Fonts\tahoma.ttf'))
old_encoded = '\x14\x15\x13\x13[\x15\x17\x13\x13PP\x11'
source_annots = []

for index, page in enumerate(writer.pages):
    source_annots.append([(str(a.get_object().get('/T')), list(a.get_object()['/Rect']), a.get_object()['/AP']['/N'].get_object().get_data()) for a in reader.pages[index].get('/Annots', [])])
    content = ContentStream(page.get_contents(), writer)
    operations = []
    replacements = 0
    active_font = None
    for operands, operator in content.operations:
        if operator == b'Tf':
            active_font = list(operands)
        if operator == b'Tj' and len(operands) == 1 and str(operands[0]) == old_encoded:
            # Retain the original text position, size, and page coordinates.
            # The original subset font lacks the digit 5, so use Helvetica Bold
            # for this one dimension line and restore the drafting font after it.
            operations.extend([
                ([NameObject('/F2'), FloatObject(17.0264)], b'Tf'),
                ([TextStringObject('1250x2440mm.')], b'Tj'),
                (active_font, b'Tf'),
            ])
            replacements += 1
        else:
            operations.append((operands, operator))
    assert replacements == 1, (index + 1, replacements)
    content.operations = operations
    page[NameObject('/Contents')] = writer._add_object(content)

    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=(float(page.mediabox.width), float(page.mediabox.height)))
    # Render Thai via Windows text shaping for correct vowel and tone marks.
    c.drawImage(str(ROOT / 'note.png'), 1560, 195, width=425, height=105)
    # Keep a searchable Unicode text layer beneath the visible note.
    t = c.beginText(1560, 272)
    t.setFont('ThaiNote', 27)
    t.setTextRenderMode(3)
    t.textLine('หมายเหตุ:')
    t.setTextOrigin(1560, 222)
    t.setFont('ThaiNote', 32)
    t.textLine('ติดฟิล์ม ด้านทำสี 1 ด้าน')
    c.drawText(t)
    c.save()
    buffer.seek(0)
    page.merge_page(PdfReader(buffer).pages[0], over=True)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as stream:
    writer.write(stream)

# Reopen and verify text, page geometry, and signature appearance data.
result = PdfReader(OUTPUT)
assert len(result.pages) == len(reader.pages) == 4
assert set(result.get_fields() or {}) == set(reader.get_fields() or {})
for i, page in enumerate(result.pages):
    assert page.rotation == reader.pages[i].rotation
    assert list(page.mediabox) == list(reader.pages[i].mediabox)
    annots = [(str(a.get_object().get('/T')), list(a.get_object()['/Rect']), a.get_object()['/AP']['/N'].get_object().get_data()) for a in page.get('/Annots', [])]
    assert annots == source_annots[i]
with pdfplumber.open(OUTPUT) as doc:
    for i, page in enumerate(doc.pages):
        text = page.extract_text()
        assert '1250x2440mm.' in text and '1200x2400mm.' not in text
        assert 'ติดฟิล์ม ด้านทำสี 1 ด้าน' in text
        print(f'Page {i + 1}: dimension, note, geometry, signature appearance verified')
print(OUTPUT)
