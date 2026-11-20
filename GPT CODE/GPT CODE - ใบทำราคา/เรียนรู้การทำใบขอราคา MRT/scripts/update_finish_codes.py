from io import BytesIO
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas


SOURCE = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PANEL-PART-[001-004](1).pdf")
OUTPUT = Path(r"C:\Users\tawan.t\Documents\ChatGPT\ใบทำราคา\outputs\pdf\FL-PJ-26-031-ALU-PANEL-PART-[001-004]_FINISH-UPDATED.pdf")
FINISH_CODES = [
    "PA-1M-U0139",
    "PA-1S-G0309",
    "PA-1S-E0116",
    "PA-2S-W0803",
]


reader = PdfReader(SOURCE)
if len(reader.pages) != len(FINISH_CODES):
    raise ValueError(f"Expected 4 pages, found {len(reader.pages)}")

writer = PdfWriter()
writer.clone_document_from_reader(reader)

for page, code in zip(writer.pages, FINISH_CODES):
    width = float(page.mediabox.width)
    height = float(page.mediabox.height)
    overlay_bytes = BytesIO()
    overlay_canvas = canvas.Canvas(overlay_bytes, pagesize=(width, height))

    # Clear only the existing FINISH value, leaving the label and table lines intact.
    overlay_canvas.setFillColorRGB(1, 1, 1)
    overlay_canvas.rect(2117, 950, 255, 29, fill=1, stroke=0)

    # Match the original bold technical-note size and baseline.
    overlay_canvas.setFillColorRGB(0, 0, 0)
    overlay_canvas.setFont("Helvetica-Bold", 17.03)
    overlay_canvas.drawString(2121, 955.8, code)
    overlay_canvas.save()

    overlay_bytes.seek(0)
    overlay_page = PdfReader(overlay_bytes).pages[0]
    page.merge_page(overlay_page, over=True)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open("wb") as stream:
    writer.write(stream)

print(OUTPUT)
