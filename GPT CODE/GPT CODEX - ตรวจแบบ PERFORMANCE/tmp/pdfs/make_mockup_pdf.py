from pathlib import Path
from io import BytesIO
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.colors import white, black

src = Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\HOOK-ON\CAD\PJ25-031-P041.pdf')
out = Path('output/pdf/PJ25-031-P013_P014_mockup.pdf')
w = h = None
project_line1 = 'MRT PURPLE LINE  4STATION'
project_line2 = '(PP17 - PP20) C10 MOCKUP PP17 19'

sheets = [
    {'part_code': '300HK-A-NPF (FOR PP17)', 'finish': 'S2214V', 'length': '500.0', 'dwg': 'FL-PJ-26-031-MCK-P-013', 'sheet': '13'},
    {'part_code': '300HK-A-NPF (FOR PP19)', 'finish': 'NS-1S-P0070', 'length': '900.0', 'dwg': 'FL-PJ-26-031-MCK-P-014', 'sheet': '14'},
]

def top_y(top):
    return h - top

def overlay_for(data):
    packet = BytesIO()
    c = canvas.Canvas(packet, pagesize=(w, h))
    c.setFillColor(white)
    c.setStrokeColor(white)

    # Cover values only. Keep every original title-block line and label intact.
    c.rect(1942, top_y(515), 422, 80, fill=1, stroke=0)       # project value only
    c.rect(2051, top_y(548), 310, 19, fill=1, stroke=0)       # part code value; stays below border
    c.rect(2061, top_y(740), 185, 26, fill=1, stroke=0)       # finish value
    c.rect(1983, top_y(1548), 210, 28, fill=1, stroke=0)      # dwg no value
    c.rect(2188, top_y(1526), 58, 25, fill=1, stroke=0)       # sheet no value
    c.rect(2188, top_y(1584), 58, 25, fill=1, stroke=0)       # total value

    # Replace the "Length" field above BOTTOM VIEW, not the 900.0 dimension.
    c.rect(996, top_y(164), 76, 30, fill=1, stroke=0)

    c.setFillColor(black)
    c.setStrokeColor(black)
    # Fit the project name comfortably inside the original PROJECT cell.
    c.setFont('Helvetica-Bold', 11.5)
    c.drawCentredString(2153, top_y(463), project_line1)
    c.drawCentredString(2153, top_y(486), project_line2)

    c.setFont('Helvetica', 17)
    c.drawCentredString(1034, top_y(158), data['length'].split('.')[0])

    c.setFont('Helvetica', 17)
    c.drawString(2054.9, top_y(541.5), data['part_code'])
    c.drawString(2064.9, top_y(733.0), data['finish'])
    c.drawString(1985.9, top_y(1540.0), data['dwg'])
    c.drawString(2208, top_y(1518.0), data['sheet'])
    c.drawString(2207, top_y(1576.0), '14')

    c.save()
    packet.seek(0)
    return PdfReader(packet).pages[0]

reader = PdfReader(str(src))
w = float(reader.pages[0].mediabox.width)
h = float(reader.pages[0].mediabox.height)
writer = PdfWriter()
for data in sheets:
    page = PdfReader(str(src)).pages[0]
    page.merge_page(overlay_for(data))
    writer.add_page(page)
with out.open('wb') as f:
    writer.write(f)
