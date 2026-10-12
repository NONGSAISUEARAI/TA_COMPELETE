from io import BytesIO
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw
from pypdf import PdfReader, PdfWriter, Transformation
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\Users\tawan.t\Downloads\pdf-manager-result (5).pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'pdf-manager-result_5_GREEN-HIGHLIGHT.pdf'

reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
page = writer.pages[0]
assert len(reader.pages) == 1 and page.rotation == 270
portrait_width = float(page.mediabox.width)
portrait_height = float(page.mediabox.height)
display_width, display_height = portrait_height, portrait_width
with Image.open(ROOT / 'source-1.png') as image:
    pixel_width, pixel_height = image.size

# The two marked strips in the reference screenshot correspond to the 3650
# and 2100 vertical dimension lines. Coordinates refer to the rendered source.
regions = [(594, 402, 608, 720), (916, 507, 931, 720)]
buffer = BytesIO()
c = canvas.Canvas(buffer, pagesize=(display_width, display_height))
c.setFillColorRGB(0, 1, 0)
c.setFillAlpha(0.82)
c.setBlendMode('Multiply')
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
display_to_original = Transformation((0, -1, 1, 0, 0, portrait_height))
page.merge_transformed_page(overlay, display_to_original, over=True, expand=False)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as output:
    writer.write(output)

result = PdfReader(OUTPUT)
assert len(result.pages) == 1
assert list(result.pages[0].mediabox) == list(reader.pages[0].mediabox)
assert result.pages[0].rotation == reader.pages[0].rotation
assert result.pages[0].images[0].data == reader.pages[0].images[0].data
print('Added two green highlights; original scanned drawing and page geometry preserved.')
print(OUTPUT)
