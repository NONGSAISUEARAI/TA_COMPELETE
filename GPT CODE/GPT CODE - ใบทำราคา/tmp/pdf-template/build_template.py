from pathlib import Path
import base64, json, math, struct, io, re
import zipfile
from xml.etree import ElementTree as ET
from collections import Counter, defaultdict
from html import escape
import pdfplumber
from pypdf import PdfReader

ROOT=Path(__file__).resolve().parents[2]
SOURCE=next((ROOT/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106').glob('BU2*.pdf'))
OUT=ROOT/'outputs/rfq-html-template';OUT.mkdir(parents=True,exist_ok=True)
page=pdfplumber.open(SOURCE).pages[0]
assert (page.width,page.height)==(792,612)
encode=lambda b:base64.b64encode(b).decode('ascii')

def checksum(b):
    b=b+b'\0'*((-len(b))%4)
    return sum(struct.unpack('>'+str(len(b)//4)+'I',b))&0xffffffff

def extract_ttf(collection,index):
    start=struct.unpack_from('>I',collection,12+4*index)[0]
    count=struct.unpack_from('>H',collection,start+4)[0]
    records=[]
    for i in range(count):
        tag,_,offset,length=struct.unpack_from('>4sIII',collection,start+12+16*i)
        content=collection[offset:offset+length]
        if tag==b'head':content=content[:8]+b'\0\0\0\0'+content[12:]
        records.append((tag,content))
    records.sort()
    result=bytearray(collection[start:start+12]+b'\0'*(16*count))
    head=None
    for i,(tag,content) in enumerate(records):
        result.extend(b'\0'*((-len(result))%4));offset=len(result)
        struct.pack_into('>4sIII',result,12+16*i,tag,checksum(content),offset,len(content))
        result.extend(content)
        if tag==b'head':head=offset
    result.extend(b'\0'*((-len(result))%4))
    struct.pack_into('>I',result,head+8,(0xb1b0afba-checksum(bytes(result)))&0xffffffff)
    assert checksum(bytes(result))==0xb1b0afba
    return bytes(result)

fonts=[]
collection=Path('C:/Windows/Fonts/cordia.ttc').read_bytes()
for family,index,weight,style in [('RFQCordia',0,400,'normal'),('RFQCordia',1,700,'normal'),('RFQCordia',2,700,'italic'),('RFQCordia',3,400,'italic'),('RFQUPC',4,400,'normal')]:
    data=extract_ttf(collection,index)
    fonts.append(f"@font-face{{font-family:{family};font-weight:{weight};font-style:{style};font-display:block;src:url(data:font/ttf;base64,{encode(data)}) format('truetype')}}")
fonts.append(f"@font-face{{font-family:RFQTahoma;font-weight:400;src:url(data:font/ttf;base64,{encode(Path('C:/Windows/Fonts/tahoma.ttf').read_bytes())}) format('truetype')}}")

def color(c):
    if c is None:return 'none'
    if isinstance(c,(float,int)):c=(c,c,c)
    if len(c)==1:c=c*3
    return '#'+''.join(f'{round(max(0,min(1,v))*255):02x}' for v in c[:3])

svg=['<svg class="form-lines" viewBox="0 0 792 612" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">']
for r in page.rects:
    svg.append(f'<rect x="{r["x0"]:.4f}" y="{r["top"]:.4f}" width="{r["width"]:.4f}" height="{r["height"]:.4f}" fill="{color(r["non_stroking_color"]) if r["fill"] else "none"}" stroke="{color(r["stroking_color"]) if r["stroke"] else "none"}" stroke-width="{r["linewidth"]:.4f}"/>')
for l in page.lines:
    p=l['pts']
    svg.append(f'<line x1="{p[0][0]:.4f}" y1="{p[0][1]:.4f}" x2="{p[-1][0]:.4f}" y2="{p[-1][1]:.4f}" stroke="{color(l["stroking_color"])}" stroke-width="{l["linewidth"]:.4f}"/>')
svg.append('</svg>')

images=[i for i in page.images if i['name']!='Image60']
def is_static(c):
    if 113.05 < c['top'] < 325.04:return False
    if 355.72 < c['top'] < 466.30:return False
    for image in images:
        if image['x0']-.5<=c['x0']<=image['x1']+.5 and image['top']-1<=c['top']<=image['bottom']+.5:return False
    return True

def face(font):
    return ('RFQUPC' if 'CordiaUPC' in font else 'RFQTahoma' if 'Tahoma' in font else 'RFQCordia',700 if 'Bold' in font else 400,'italic' if 'Italic' in font else 'normal')

runs=[]
paragraphs=defaultdict(list)
for index,c in enumerate(page.chars):
    if is_static(c):paragraphs[c['mcid'] if c['mcid'] is not None else f'char-{index}'].append(c)
combining=re.compile(r'^[\u0e31\u0e34-\u0e3a\u0e47-\u0e4e\s]+$')
for mcid,chars in paragraphs.items():
    lines=[]
    rotated=abs(chars[0]['matrix'][1])>.1
    for c in chars:
        y=612-c['matrix'][5]
        match=next((line for line in lines if rotated or abs(line[0]-y)<1.2),None)
        if match is None:lines.append([y,[c]])
        else:match[1].append(c)
    for _,line in lines:
        bases=[c for c in line if not combining.match(c['text'])] or line
        font,size=Counter((c['fontname'],round(c['size'],3)) for c in bases).most_common(1)[0][0]
        baseline=Counter(round(612-c['matrix'][5],3) for c in bases).most_common(1)[0][0]
        first=line[0];a,b,_,_,x,_=first['matrix']
        runs.append({'mcid':mcid,'x':x,'y':612-first['matrix'][5] if rotated else baseline,'text':''.join(c['text'] for c in line),'font':font,'size':size,'angle':-math.degrees(math.atan2(b,a))})

labels=[]
header_fields={2:'documentNo',5:'job',360:'project',349:'customer',7:'dueDay',8:'dueMonth',9:'dueYear',275:'requester',280:'requestDate',286:'pageNumber'}
headers={}
for i,r in enumerate(runs):
    text=r['text']
    for before,after in [('ท า','ทำ'),('ก า','กำ'),('ล า','ลำ'),('จ า','จำ'),('ต า','ตำ'),('ต ่า','ต่ำ')]:text=text.replace(before,after)
    family,weight,style=face(r['font'])
    field=header_fields.get(r['mcid'])
    attribute=f' data-header="{field}"' if field else ''
    if field:headers[field]=text
    labels.append(f'<span class="text-anchor" style="left:{r["x"]:.4f}px;top:{r["y"]:.4f}px;transform:rotate({r["angle"]:.3f}deg)"><span class="ink"{attribute} style="font-family:{family};font-size:{r["size"]:.4f}px;font-weight:{weight};font-style:{style}">{escape(text)}</span></span>')

reader=PdfReader(SOURCE)
logo=next(image for image in reader.pages[0].images if image.name.startswith('Image60.'))
logo_stream=io.BytesIO();logo.image.save(logo_stream,format='PNG')
logo_markup=f'<img class="logo" alt="FAMELINE" style="left:17.76px;top:46.393px;width:48.378px;height:10.927px" src="data:image/png;base64,{encode(logo_stream.getvalue())}">'

controls=[('quote','เพื่อเสนอราคา',566.23,50.10,576.41,54.48,False),('production','เพื่อผลิต',566.23,61.79,576.41,66.02,True),('ceiling','ฝ้าเพดาน',360.49,478.76,369.17,483.05,True),('sunshade','แผงบังแดด',407.90,478.77,416.57,483.26,False),('wall','ผนังหุ้มอาคาร',449.64,478.76,458.33,483.05,False),('other','อื่นๆ',496.17,478.76,504.84,483.05,False),('inside','ภายในอาคาร',360.48,493.28,369.17,497.57,True),('outside','ภายนอกอาคาร',407.88,493.28,416.57,497.57,False)]
control_markup=[]
for name,label,x,y,tx,baseline_y,checked in controls:
    control_markup.append(f'<label class="check-field" style="left:{x:.3f}px;top:{y:.3f}px"><input type="checkbox" name="{name}" aria-label="{label}" {"checked" if checked else ""}><svg class="check-box" viewBox="0 0 5 5" aria-hidden="true"><rect x=".2" y=".2" width="4.6" height="4.6" fill="white" stroke="#666" stroke-width=".4"/><path class="check-mark" d="M1 2.65 L2.05 3.65 L4.05 1.2" fill="none" stroke="#202020" stroke-width=".65" stroke-linecap="round" stroke-linejoin="round"/></svg><span class="text-anchor" style="left:{tx-x:.3f}px;top:{baseline_y-y:.3f}px"><span class="ink" style="font-family:RFQTahoma;font-size:4.68px">{label}</span></span></label>')
labels.append('<span class="text-anchor" style="left:566.9px;top:77.1px"><span class="ink" style="font-family:RFQCordia;font-size:6.36px;font-weight:700">กำหนดการใช้งานวันที่</span></span>')

edges=[18.30,32.58,163.64,172.76,225.44,248.51,301.07,326.75,352.43,378.13,404.65,431.17,457.69,484.21,520.36,563.44,603.88,635.56,658.62,679.14,697.86,727.02,773.58]
cols=['no','description','materialCode','material','thickness','special','width','height','length','cc','sp','pc','acp','otherCoat','specialColor','paintType','brand','sides','qty','unit','cost','remark']
names=['ลำดับ','รายการ / รหัสชิ้นงาน','รหัสวัสดุ','ชื่อวัสดุ','ความหนา','วัสดุพิเศษ','กว้าง','สูง','ยาว','CC','SP','PC','Coat. ACP','Coat. Other','รหัสสีเทียบ','ชนิดสี','ยี่ห้อ','ด้านที่พ่นสี','จำนวน','หน่วย','ราคาต้นทุน','หมายเหตุ']
rowtops=[113.0,123.08,133.16,143.24,153.32,163.40,173.48,183.59,193.67,203.75,213.83,223.91,233.99,244.07,254.15,264.23,274.31,284.39,294.49,304.57,314.65]
def celltext(x0,x1,y0,y1):
    chars=[c for c in page.chars if x0+.15<=c['x0']<x1-.15 and y0-.2< c['top'] < y1-1]
    return ''.join(c['text'] for c in chars).strip()
original=[]
for idx,y in enumerate(rowtops[:16]):
    row={k:celltext(edges[j],edges[j+1],y,rowtops[idx+1]) for j,k in enumerate(cols)}
    row['sides']='1 ด้าน';row['unit']='ชิ้น'
    row['qty']=int(re.sub(r'[^0-9]','',row['qty']))
    original.append(row)
assert sum(r['qty'] for r in original)==3278

new_spec=[(2400,'NS-1S-E0114',11),(2400,'NS-1S-E0114',4),(2400,'S2214V',63),(2400,'S2214V',1),(2600,'S2214V',8),(2400,'SA-05611',41),(2400,'SA-09101',11),(2800,'SA-09101',1),(2400,'SD-9211',55),(2400,'SD-9211',8)]
paint={'NS-1S-E0114':('PE or PC','Cornel','PC21010087'),'S2214V':('PE or PC','Akzo Nobel','PC21010085'),'SA-05611':('WET-P or SP','Thai Paint','PC21010082'),'SA-09101':('WET-P or SP','Thai Paint','PC21010083')}
new=[]
for idx,(length,finish,qty) in enumerate(new_spec,1):
    row={k:'' for k in cols}
    row.update(no=str(idx),description=f'AL.1.2mm.(thk.) TRAY-SOLID-249x{length}mm. / PJ25-031 AL-TRAY-SO-VA-{idx:02}',materialCode='1',material='Alu.sheet, MF',thickness='1.2',special='**',width='249.0',height='51.2',length=f'{length}.0',sides='1 ด้าน',qty=qty,unit='ชิ้น')
    if finish=='SD-9211':row['pc']=finish
    else:row.update(specialColor=finish,paintType=paint[finish][0],brand=paint[finish][1],remark=paint[finish][2])
    new.append(row)
assert sum(r['qty'] for r in new)==203
reference=next((ROOT/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106').glob('BU2*.xlsx'))
ns={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
with zipfile.ZipFile(reference) as z:
    shared=[''.join(x.itertext()) for x in ET.fromstring(z.read('xl/sharedStrings.xml'))]
    values={}
    for c in ET.fromstring(z.read('xl/worksheets/sheet1.xml')).findall('.//s:c',ns):
        value=c.findtext('s:v',default='',namespaces=ns)
        if c.get('t')=='s':value=shared[int(value)] if value else ''
        values[c.get('r')]=value
    materials={str(int(values[f'AE{r}'])):values[f'AF{r}'] for r in range(51,87)}
assert materials['1']=='Alu.sheet, MF' and materials['21']=='ACP. 605 FR core'
secondary_tops=[355.69,365.77,375.85,385.93,396.04,406.12,416.20,426.28,436.36,446.44,456.52,466.24]
model={'version':2,'edges':edges,'columns':cols,'columnNames':names,'rowTops':rowtops,'secondaryRowTops':secondary_tops,'materials':materials,'headers':headers,'defaultChecks':{c[0]:c[-1] for c in controls},'pageChecks':[],'pageCount':1,'secondary':[],'original':original,'new':new,'current':original,'mode':'original'}
template=Path(__file__).with_name('template.html').read_text(encoding='utf-8')
html=template.replace('__FONTS__','\n'.join(fonts)).replace('__GRID__',''.join(svg)).replace('__LABELS__',''.join(labels)).replace('__LOGO__',logo_markup).replace('__CONTROLS__',''.join(control_markup)).replace('__MODEL__',json.dumps(model,ensure_ascii=False,separators=(',',':')))
assert not re.search(r'__(FONTS|GRID|LABELS|LOGO|CONTROLS|MODEL)__',html)
dest=OUT/'RFQ-vector-template.html';dest.write_text(html,encoding='utf-8')
(OUT/'template-data.json').write_text(json.dumps(model,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'template-geometry.json').write_text(json.dumps({'page':[792,612],'columnEdges':edges,'rowTops':rowtops,'vectorRectangles':len(page.rects),'vectorLines':len(page.lines),'textRuns':len(labels),'rasterObjects':['logo only'],'fonts':['Cordia New','CordiaUPC','Tahoma']},indent=2),encoding='utf-8')
print(json.dumps({'htmlBytes':dest.stat().st_size,'nativeTextRuns':len(labels),'vectorShapes':len(page.rects)+len(page.lines),'originalRows':len(original),'originalQty':sum(r['qty'] for r in original),'newRows':len(new),'newQty':sum(r['qty'] for r in new),'fontChecksums':'passed'},indent=2))
