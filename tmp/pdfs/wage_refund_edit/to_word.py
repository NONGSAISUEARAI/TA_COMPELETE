from docx import Document
from docx.shared import Cm, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from PIL import Image
from pathlib import Path

out=Path('output/docx'); out.mkdir(parents=True,exist_ok=True)
im=Image.open('tmp/pdfs/wage_refund_edit/new_source.png')
im.crop((175,110,390,155)).save('tmp/pdfs/wage_refund_edit/word_logo.png')
d=Document(); s=d.sections[0]
s.page_width=Cm(21); s.page_height=Cm(29.7)
s.top_margin=Cm(1.8); s.bottom_margin=Cm(1.6); s.left_margin=Cm(2.5); s.right_margin=Cm(2)
style=d.styles['Normal']; style.font.name='Tahoma'; style.font.size=Pt(11)
style.element.rPr.rFonts.set(qn('w:eastAsia'),'Tahoma')
style.paragraph_format.space_after=Pt(5)
style.paragraph_format.line_spacing=1.35
def p(t='',before=0,after=5,align=None):
    x=d.add_paragraph(t); x.paragraph_format.space_before=Pt(before); x.paragraph_format.space_after=Pt(after)
    if align is not None: x.alignment=align
    return x
x=p(); x.add_run().add_picture('tmp/pdfs/wage_refund_edit/word_logo.png',width=Cm(4))
x=p('FAMELINE PRODUCTS CO., LTD.\n36/11 Kanchanaphisek Road, Dokmai, Prawet, Bangkok 10250\nT +662 365 5899   F +662 365 5890   info@fameline.com',after=18,align=WD_ALIGN_PARAGRAPH.RIGHT)
for r in x.runs:r.font.size=Pt(8)
x=p('ลำดับ.......................................\tวันที่ 10 พฤศจิกายน พ.ศ. 2569',after=18)
x.paragraph_format.tab_stops.add_tab_stop(Cm(9))
p('เรียน ฝ่ายบริหารทรัพยากรบุคคล')
p('เรื่อง เอกสารขอเงินคืนครั้งที่ 3',after=24)
p('ข้าพเจ้า นาย ตะวัน ไตรรัตน์')
x=p('รหัสพนักงาน 11350  ฝ่าย IP&EP Management  แผนก ฝ่ายบริหารโครงการ 1')
for r in x.runs:r.font.size=Pt(10)
p('ของงวดค่าจ้างประจำเดือน กันยายน พ.ศ. 2569',after=22)
p('เนื่องจากข้าพเจ้าบันทึกวันลาพักร้อนในระบบคลาดเคลื่อน โดยวันที่ลาพักร้อนจริงคือวันที่ 7-11 กันยายน พ.ศ. 2569 แต่บันทึกเป็นวันที่ 7-11 พฤศจิกายน พ.ศ. 2569 ส่งผลให้ข้าพเจ้าถูกหักค่าจ้างประจำเดือนกันยายน พ.ศ. 2569 เป็นจำนวนเงินทั้งสิ้น 5,464 บาท',after=20)
p('จึงเรียนมาเพื่อทราบ',after=20)
for t,b in [('ขอแสดงความนับถือ',0),('................................................',24),('(ตะวัน ไตรรัตน์)',0)]:
    x=p(t,b); x.paragraph_format.left_indent=Cm(9); x.alignment=WD_ALIGN_PARAGRAPH.CENTER
x=p('........................................\t........................................',before=38)
x.paragraph_format.left_indent=Cm(2); x.paragraph_format.tab_stops.add_tab_stop(Cm(7))
x=p('(......................................)\t(......................................)')
x.paragraph_format.left_indent=Cm(2); x.paragraph_format.tab_stops.add_tab_stop(Cm(7))
x=p('ผู้จัดการฝ่าย\tเจ้าหน้าที่ฝ่ายบุคคล',before=12)
x.paragraph_format.left_indent=Cm(3); x.paragraph_format.tab_stops.add_tab_stop(Cm(7))
f=s.footer.paragraphs[0]
f.text='หมายเหตุ : อ้างอิงประกาศฉบับที่ 005 / 2563 การขอคืนสิทธิ์รับค่าจ้าง หากตรวจพบว่าพนักงานมีการทำผิดซ้ำติดต่อกันตั้งแต่ 3 ครั้งขึ้นไป ขอสงวนสิทธิ์ไม่ทำจ่ายคืน'
for r in f.runs:r.font.name='Tahoma'; r.font.size=Pt(8)
d.save(out/'เอกสารขอเงินคืนครั้งที่_3.docx')
