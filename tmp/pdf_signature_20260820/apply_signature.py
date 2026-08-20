from pathlib import Path
import fitz

source_path = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\PP18\รวม\IT3-M3-2026-0061-0069_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PURPLE LINE 4STATION (PP17 - PP20) C10 MOCKUP PP18_.pdf")
target_path = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\Generic\Gen C10\MCK C10 PP17 PP19\PP18\รวม\IT3-M3-2026-0071-0074_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PURPLE LINE 4STATION (PP17 - PP20) C10 MOCKUP PP18_.pdf")
output_path = Path(r"C:\TA\TA_COMPELETE\tmp\pdf_signature_20260820\signed_0071_0074.pdf")

# The rectangle is the signature/value cell below "Checked By".  Source and
# target PDFs use the same 792 x 612 page template.
signature_rect = fitz.Rect(736, 317, 770, 347)

source = fitz.open(source_path)
target = fitz.open(target_path)
try:
    if source.page_count < 9:
        raise ValueError("Expected the source PDF to have page 9 for the approved signature.")
    for page in target:
        page.show_pdf_page(signature_rect, source, 8, clip=signature_rect, overlay=True)
    target.save(output_path, garbage=4, deflate=True)
finally:
    target.close()
    source.close()

print(output_path)
