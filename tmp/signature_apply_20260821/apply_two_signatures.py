from io import BytesIO
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

target = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\PP18\รวม\IT3-M3-2026-0071-0074_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PURPLE LINE 4STATION (PP17 - PP20) C10 MOCKUP PP18__before_signature_2026-08-20 - Copy.pdf")
ekal = Path(r"C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\Codex Image Aug 21, 2026, 01_06_09 AM.png")
vudhichai = Path(r"C:\TA\TA_COMPELETE\GPT CODE\GPT CODEX - ตรวจแบบ PERFORMANCE\Codex Image Aug 21, 2026, 01_06_00 AM.png")
output = Path(r"C:\TA\TA_COMPELETE\tmp\signature_apply_20260821\signed_0071_0074_final.pdf")

page_width, page_height = 792, 612
overlay_buffer = BytesIO()
overlay = canvas.Canvas(overlay_buffer, pagesize=(page_width, page_height))

# Top-right: ผู้อนุมัติ. Bottom-right: Checked By.
overlay.drawImage(ImageReader(str(ekal)), 700, 545, width=34, height=18, mask='auto')
overlay.drawImage(ImageReader(str(vudhichai)), 733, 316, width=34, height=20, mask='auto')
overlay.save()
overlay_buffer.seek(0)
overlay_page = PdfReader(overlay_buffer).pages[0]

reader = PdfReader(str(target))
writer = PdfWriter()
for page in reader.pages:
    page.merge_page(overlay_page, over=True)
    writer.add_page(page)

with output.open('wb') as file:
    writer.write(file)
print(output)
