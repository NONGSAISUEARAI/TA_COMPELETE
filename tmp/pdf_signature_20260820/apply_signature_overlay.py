from io import BytesIO
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader

target_path = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\PP18\รวม\IT3-M3-2026-0071-0074_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PURPLE LINE 4STATION (PP17 - PP20) C10 MOCKUP PP18_.pdf")
signature_image = Path(r"C:\TA\TA_COMPELETE\tmp\pdf_signature_20260820\signature_cell-9.png")
output_path = Path(r"C:\TA\TA_COMPELETE\tmp\pdf_signature_20260820\signed_0071_0074.pdf")

page_width, page_height = 792, 612
x, top, width, height = 735.927, 277.0, 52.364, 36.0
y = page_height - top - height

overlay_bytes = BytesIO()
overlay_canvas = canvas.Canvas(overlay_bytes, pagesize=(page_width, page_height))
overlay_canvas.drawImage(ImageReader(str(signature_image)), x, y, width=width, height=height, mask='auto')
overlay_canvas.save()
overlay_bytes.seek(0)
overlay_page = PdfReader(overlay_bytes).pages[0]

reader = PdfReader(str(target_path))
writer = PdfWriter()
for page in reader.pages:
    page.merge_page(overlay_page, over=True)
    writer.add_page(page)

with output_path.open("wb") as file:
    writer.write(file)

print(output_path)
