from io import BytesIO
from pathlib import Path

from PIL import Image
from pypdf import PdfReader, PdfWriter, Transformation
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\Users\tawan.t\Downloads\pdf-manager-result (5).pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'pdf-manager-result_5_RED-LINES-NUMBERS.pdf'

# Begin from the original drawing rather than the green-highlight copy.
reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
page = writer.pages[0]
assert len(reader.pages) == 1 and page.rotation == 270
portrait_width = float(page.mediabox.width)
portrait_height = float(page.mediabox.height)
display_width, display_height = portrait_height, portrait_width
with Image.open(ROOT / 'source-1.png') as reference:
    pixel_width, pixel_height = reference.size

# Include each dimension's numeral and line within the two marked positions.
regions = [(589, 402, 609, 720), (914, 507, 932, 720)]
buffer = BytesIO()
c = canvas.Canvas(buffer, pagesize=(display_width, display_height))
# Screen with pure red maps black linework to red and keeps white paper white.
# This preserves the scan and its antialiasing without a coloured background.
c.setFillColorRGB(1, 0, 0)
c.setBlendMode('Screen')
for left, top, right, bottom in regions:
    c.rect(
        left * display_width / pixel_width,
        (pixel_height - bottom) * display_height / pixel_height,
        (right - left) * display_width / pixel_width,
        (bottom - top) * display_height / pixel_height,
        fill=1, stroke=0,
    )
c.save()
buffer.seek(0)
overlay = PdfReader(buffer).pages[0]
page.merge_transformed_page(
    overlay, Transformation((0, -1, 1, 0, 0, portrait_height)),
    over=True, expand=False,
)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(result.pages) == 1
assert list(result.pages[0].mediabox) == list(reader.pages[0].mediabox)
assert result.pages[0].rotation == reader.pages[0].rotation
assert result.pages[0].images[0].data == reader.pages[0].images[0].data
print('Red linework and numbers added at the two indicated positions; original scan preserved.')
print(OUTPUT)
