from pathlib import Path
import json,shutil,subprocess
import pdfplumber
import pypdfium2
from pypdf import PdfReader

root=Path(__file__).resolve().parents[2]
out=root/'outputs/rfq_26106_from_template'
name='BU2-DE-26106_โครงการ MRT PURPLE LINE 4 STATION (PP17 - PP20) ถาดไฟ VA และ SOLID.pdf'
dest=out/name
download=json.loads((out/'pdf-download-path.json').read_text(encoding='utf-8'))
shutil.copy2(Path(download['path']),dest)
reader=PdfReader(dest)
report={'pages':len(reader.pages),'dimensions':[[float(p.mediabox.width),float(p.mediabox.height)] for p in reader.pages],'title':reader.metadata.title}
with pdfplumber.open(dest) as pdf:
    report['vectorPaths']=[len(p.rects)+len(p.lines)+len(p.curves) for p in pdf.pages]
    report['images']=[len(p.images) for p in pdf.pages]
    report['chars']=[len(p.chars) for p in pdf.pages]
    text='\n'.join(p.extract_text() or '' for p in pdf.pages)
    (out/'direct-pdf-extracted.txt').write_text(text,encoding='utf-8')
    report['firstRow']=all(s in text for s in ['BU2-DE-26106','PJ25-031','NS-1S-E0114'])
assert report['pages']==2 and report['dimensions']==[[792.,612.]]*2
assert all(n>700 for n in report['vectorPaths'])
assert report['images']==[1,1]
assert report['firstRow']
subprocess.run(['pdftoppm','-scale-to','1800','-png',str(dest),str(out/'direct-pdf-page')],check=True,capture_output=True)
pdfium=pypdfium2.PdfDocument(str(dest))
searchable='\n'.join(p.get_textpage().get_text_range() for p in pdfium)
(out/'direct-pdf-searchable.txt').write_text(searchable,encoding='utf-8')
report['thaiLabels']={s:s in searchable for s in ['ชื่อโครงการ','เพื่อผลิต','ภายในอาคาร','ชิ้น','จำนวน']}
assert all(report['thaiLabels'].values())
(out/'direct-pdf-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=True,indent=2))
