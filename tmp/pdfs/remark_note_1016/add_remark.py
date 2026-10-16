from io import BytesIO
from pathlib import Path

from PIL import Image, ImageChops
import pdfplumber
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\Users\tawan.t\Downloads\PJ25-031-ALU-PANEL-PART-001-004_261016_094159.pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_REMARK-3.0mm.pdf'
NOTE = ': ขนาดที่ไม่ได้กำหนดพิกัดความเผื่อไว้ให้ใช้ค่า ± 3.0mm.'

# Preserve Windows-shaped Thai letter placement in the visible label.
with Image.open(ROOT / 'remark-uncropped.png').convert('RGB') as image:
    ink = ImageChops.difference(image, Image.new('RGB', image.size, 'white')).getbbox()
    assert ink is not None
    cropped = image.crop(ink)
    cropped.save(ROOT / 'remark.png')
    width, height = cropped.width / 4, cropped.height / 4
assert width < 866 and height < 34, (width, height)

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
pdfmetrics.registerFont(TTFont('ThaiSearch', r'C:\Windows\Fonts\tahoma.ttf'))
for page in writer.pages:
    assert page.rotation == 0
    packet = BytesIO()
    c = canvas.Canvas(packet, pagesize=(float(page.mediabox.width), float(page.mediabox.height)))
    # First text cell after REMARK: x=223.2..1106.76, y=45.84..84.36.
    c.drawImage(str(ROOT / 'remark.png'), 232, 65.1 - height / 2, width=width, height=height)
    # A Unicode layer keeps the note searchable and copyable.
    text = c.beginText(232, 59)
    text.setFont('ThaiSearch', 19)
    text.setTextRenderMode(3)
    text.textOut(NOTE)
    c.drawText(text)
    c.save()
    packet.seek(0)
    page.merge_page(PdfReader(packet).pages[0], over=True)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as stream:
    writer.write(stream)

result = PdfReader(OUTPUT)
assert len(reader.pages) == len(result.pages) == 4
for original, edited in zip(reader.pages, result.pages):
    assert original.rotation == edited.rotation
    assert list(original.mediabox) == list(edited.mediabox)
    assert len(original.get('/Annots', [])) == len(edited.get('/Annots', []))
with pdfplumber.open(SOURCE) as original, pdfplumber.open(OUTPUT) as edited:
    for index, (before, after) in enumerate(zip(original.pages, edited.pages)):
        assert after.extract_text().count(NOTE) == 1
        # Compare all source text positioned outside the newly filled remark cell.
        before_text = before.filter(lambda obj: not (obj.get('object_type') == 'char' and 223.2 < obj['x0'] < 1106.76 and 1599.64 < obj['top'] < 1638.16)).extract_text()
        after_text = after.filter(lambda obj: not (obj.get('object_type') == 'char' and 223.2 < obj['x0'] < 1106.76 and 1599.64 < obj['top'] < 1638.16)).extract_text()
        assert before_text == after_text, index + 1
        print(f'Page {index + 1}: remark inserted; all other text preserved')
print(OUTPUT)
