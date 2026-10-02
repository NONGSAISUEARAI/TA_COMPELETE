from io import BytesIO
from pathlib import Path

from pypdf import PdfReader, PdfWriter, Transformation
from reportlab.pdfgen import canvas
from reportlab.lib.colors import white, black


SOURCE = Path(r"C:\Users\tawan.t\Downloads\6060CL-A-PF-S-ACOUS  0.8 mm. thk..pdf")
OUTPUT = Path(r"C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE\output\pdf\6060CL-A-PF-S-ACOUS_0.8mm_dimension_3.0_corrected.pdf")


reader = PdfReader(SOURCE)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
page = writer.pages[0]

# Keep the source page rotation unchanged. Its signature widget uses the
# original portrait coordinate system, so changing /Rotate would displace it.
portrait_width = float(page.mediabox.width)
portrait_height = float(page.mediabox.height)
landscape_width = portrait_height
landscape_height = portrait_width

packet = BytesIO()
c = canvas.Canvas(packet, pagesize=(landscape_width, landscape_height))

# Cover only the original diameter callout, leaving its leader line intact.
c.setFillColor(white)
c.rect(627.4, 281.7, 17.0, 10.6, fill=1, stroke=0)

# Reproduce the compact italic drafting label with the corrected value.
c.setFillColor(black)
c.setFont("Helvetica-Oblique", 7.2)
c.drawString(628.0, 284.0, "Ø3.0")
c.save()

packet.seek(0)
overlay = PdfReader(packet).pages[0]
# Convert the landscape overlay into the page's original portrait coordinates.
# The existing /Rotate 270 then displays both the drawing and the replacement
# upright, while the widget annotation remains exactly where it was.
landscape_to_portrait = Transformation((0, -1, 1, 0, 0, portrait_height))
page.merge_transformed_page(overlay, landscape_to_portrait, over=True, expand=False)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open("wb") as stream:
    writer.write(stream)

print(OUTPUT)
