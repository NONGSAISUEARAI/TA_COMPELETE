from pathlib import Path
from io import BytesIO
import pypdfium2 as pdf
from pypdf import PdfReader,PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from PIL import Image

folder=Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_FL-PART\ALUMINIUM TRAY\ALUMINIUM TRAY - LT (VARIES) & SOLID (VARIES) - REVISON & GROUP SIZE')
source=next(folder.glob('* OVL.pdf'));target=next(folder.glob('* SIGNED.pdf'))
out=Path(__file__).resolve().parents[1]/'outputs/rfq_26106_signature'
out.mkdir(parents=True,exist_ok=True)
doc=pdf.PdfDocument(source)
scale=4
im=doc[0].render(scale=scale).to_pil().convert('RGB')
# PDF coordinates measured from the observed source top-right signature region.
box=(630,32,708,72)
crop=im.crop(tuple(int(v*scale) for v in box)).convert('RGBA')
pixels=crop.load();ink=0
for y in range(crop.height):
 for x in range(crop.width):
  r,g,b,a=pixels[x,y]
  if b>110 and b-r>55 and b-g>35:
   pixels[x,y]=(r,g,b,255);ink+=1
  else:pixels[x,y]=(255,255,255,0)
assert ink>100
signature=out/'signature_source.png';crop.save(signature)
reader=PdfReader(target);assert len(reader.pages)==2
assert not any(f.get('/FT')=='/Sig' and f.get('/V') for f in (reader.get_fields() or {}).values())
writer=PdfWriter();writer.clone_document_from_reader(reader)
for page in writer.pages:
 w,h=float(page.mediabox.width),float(page.mediabox.height)
 buf=BytesIO();c=canvas.Canvas(buf,pagesize=(w,h))
 c.drawImage(ImageReader(crop),box[0],h-box[3],width=box[2]-box[0],height=box[3]-box[1],mask='auto')
 c.save();buf.seek(0);page.merge_page(PdfReader(buf).pages[0])
dest=out/(target.stem+' ใส่ลายเซ็นทุกหน้า.pdf')
if dest.exists():raise FileExistsError(dest)
with dest.open('wb') as stream:writer.write(stream)
check=PdfReader(dest);assert len(check.pages)==2
for a,b in zip(reader.pages,check.pages):assert a.extract_text()==b.extract_text()
render=pdf.PdfDocument(dest)
for i in range(2):render[i].render(scale=2).to_pil().save(out/f'page{i+1}.png')
print('VERIFIED: SIGNATURE IMAGE ADDED TO BOTH PAGES; ORIGINAL TEXT PRESERVED')
