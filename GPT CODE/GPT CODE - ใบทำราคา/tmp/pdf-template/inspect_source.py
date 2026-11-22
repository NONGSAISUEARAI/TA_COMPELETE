from pathlib import Path
import json,struct
import pdfplumber

root=Path(__file__).resolve().parents[2]
source=next((root/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106').glob('BU2*.pdf'))
page=pdfplumber.open(source).pages[0]
out=Path(__file__).parent
data={'width':page.width,'height':page.height,'rects':page.rects,'lines':page.lines,'chars':page.chars,'images':[{k:v for k,v in image.items() if k not in ['stream']} for image in page.images]}
(out/'source_geometry.json').write_text(json.dumps(data,ensure_ascii=False,default=str),encoding='utf-8')
vertical=sorted(set((round(l['x0'],3),round(l['top'],3),round(l['bottom'],3)) for l in page.lines if abs(l['x0']-l['x1'])<0.01))
horizontal=sorted(set((round(l['top'],3),round(l['x0'],3),round(l['x1'],3)) for l in page.lines if abs(l['top']-l['bottom'])<0.01))
print('VERTICAL',vertical)
print('HORIZONTAL',horizontal)
print('RAW TEXT TOP', ''.join(c['text'] for c in page.chars if c['top']<95))
for r in page.rects:
    if r['width']>0.1 and r['height']>0.1 and r['fill'] and r['top']<140:
        print('FILL',round(r['x0'],2),round(r['top'],2),round(r['x1'],2),round(r['bottom'],2),r['non_stroking_color'])
ttc=Path('C:/Windows/Fonts/cordia.ttc').read_bytes()
count=struct.unpack_from('>I',ttc,8)[0]
for i in range(count):
    offset=struct.unpack_from('>I',ttc,12+4*i)[0]
    number=struct.unpack_from('>H',ttc,offset+4)[0]
    for j in range(number):
        tag,check,start,length=struct.unpack_from('>4sIII',ttc,offset+12+16*j)
        if tag!=b'name':continue
        _,n,base=struct.unpack_from('>HHH',ttc,start)
        names={}
        for k in range(n):
            platform,enc,lang,nid,size,pos=struct.unpack_from('>HHHHHH',ttc,start+6+12*k)
            if nid in (1,2,6) and platform==3 and lang==1033:
                names[nid]=ttc[start+base+pos:start+base+pos+size].decode('utf-16be')
        print('TTC FONT',i,names)
