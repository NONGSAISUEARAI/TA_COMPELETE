import copy,zipfile,json
from pathlib import Path
from datetime import datetime
from lxml import etree as E
from build_rfq_native_controls import S,TEMPLATE,workbook_parts,xml_bytes,shift_shape_ids,worksheet_rels

OUT=Path('outputs/rfq_26106_rev01'); OUT.mkdir(parents=True,exist_ok=True)
# User table column order: PP17 S2214V, SA-09101, SD-9211; PP18 SD-9211;
# PP19 NS-1S-E0114, SD-9211; PP20 SD-9211.
raw=[
('STD',1000,1000,'SD-9211',[0,0,5,17,0,7,2]),
('STD',1000,800,'SD-9211',[0,0,7,11,0,8,8]),
('STD',1020,980,'SD-9211',[0,0,1,0,0,0,0]),
('STD',1050,950,'SD-9211',[0,0,1,0,0,0,0]),
('STD',1100,1300,'SA-09101',[0,2,0,0,0,0,0]),
('STD',1100,1300,'SD-9211',[0,0,2,0,0,0,0]),
('STD',1100,700,'SD-9211',[0,0,4,4,0,12,5]),
('STD',1100,900,'SD-9211',[0,0,3,3,0,2,3]),
('STD',1200,1200,'SD-9211',[0,0,2,6,0,20,0]),
('STD',1300,1100,'NS-1S-E0114',[0,0,0,0,8,0,0]),
('STD',1300,1100,'SD-9211',[0,0,3,1,0,4,0]),
('STD',1300,1400,'NS-1S-E0114',[0,0,0,0,2,0,0]),
('STD',1400,1000,'SD-9211',[0,0,6,14,0,18,0]),
('STD',1440,1260,'SA-09101',[0,1,0,0,0,0,0]),
('STD',1600,1100,'NS-1S-E0114',[0,0,0,0,2,0,0]),
('STD',800,1000,'SD-9211',[0,0,6,14,0,9,0]),
('STD',900,900,'SD-9211',[0,0,3,3,0,3,0]),
('STD',950,1050,'SD-9211',[0,0,4,0,0,0,0]),
('STD',950,1450,'SD-9211',[0,0,2,0,0,0,0]),
('VAR',1000,1000,'NS-1S-E0114',[0,0,0,0,10,0,0]),
('VAR',1000,1000,'SD-9211',[0,0,0,1,0,0,0]),
('VAR',1000,1400,'NS-1S-E0114',[0,0,0,0,2,0,0]),
('VAR',1400,1000,'SD-9211',[0,0,0,1,0,0,0]),
('VAR',1600,1100,'NS-1S-E0114',[0,0,0,0,2,0,0]),
('VAR',1900,800,'SA-09101',[0,2,0,0,0,0,0]),
('VAR',2400,300,'S2214V',[2,0,0,0,0,0,0]),
('VAR',500,2200,'SA-09101',[0,1,0,0,0,0,0]),
]
assert len(raw)==27 and sum(sum(r[4]) for r in raw)==259
assert [sum(r[4][i] for r in raw) for i in range(7)]==[2,6,49,75,26,83,18]
(OUT/'source_table.json').write_text(json.dumps(raw,ensure_ascii=False,indent=2),encoding='utf8')
dest=OUT/'BU2-DE-26106_REV01 - MRT PURPLE LINE 4 STATION_20261120-1300.xlsm'
if dest.exists():raise FileExistsError(dest)
with zipfile.ZipFile(TEMPLATE) as z:
 changes=workbook_parts(z,2)
 for page in (1,2):
  sh=E.fromstring(z.read('xl/worksheets/sheet1.xml'))
  cells={c.get('r'):c for c in sh.findall(f'.//{{{S}}}c')}
  def put(a,v=None,formula=None):
   c=cells[a]; c.attrib.pop('t',None)
   for ch in list(c):
    if E.QName(ch).localname in ('f','v','is'):c.remove(ch)
   if formula:E.SubElement(c,f'{{{S}}}f').text=formula
   if isinstance(v,str):
    c.set('t','inlineStr'); E.SubElement(E.SubElement(c,f'{{{S}}}is'),f'{{{S}}}t').text=v
   elif v is not None:E.SubElement(c,f'{{{S}}}v').text=str(v)
  for r in list(range(7,28))+list(range(31,42)):
   for col in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':put(f'{col}{r}')
   for col,idx in [('F',3),('G',2)]:put(f'{col}{r}',formula=f'IF(E{r}="","",VLOOKUP(E{r},$AE$50:$AG$86,{idx},FALSE))')
  for a,v in {'Z1':'BU2-DE-26106 REV01','Z2':'PJ26-031','C2':'MRT PURPLE LINE 4 STATION (PP17 - PP20)','C3':'CKST','V3':4,'W3':12,'X3':69,'C44':46346,'H44':None,'Z45':f'{page}/2'}.items():put(a,v)
  for j,(kind,w,l,color,qty) in enumerate(raw[(page-1)*20:page*20]):
   r=7+j; idx=(page-1)*20+j+1
   shape='STANDARD-SHAPE' if kind=='STD' else 'START-END_VARIES-SHAPE'
   name=f'ALU_TRAY_PANEL_FOR_RECESSED-LIGHT_{shape}_BOTTOM-VIEW'
   for a,v in {f'A{r}':idx,f'B{r}':f'{name}\n010 / {w},{l},{color}',f'E{r}':1,f'I{r}':1.2,f'K{r}':w,f'M{r}':l,f'V{r}':'1 ด้าน',f'W{r}':sum(qty),f'X{r}':'ชิ้น'}.items():put(a,v)
   if color=='SD-9211':put(f'P{r}',color)
   else:
    put(f'S{r}',color); put(f'T{r}','WET-P  or SP' if color=='SA-09101' else 'PE  or PC'); put(f'U{r}',{'SA-09101':'Thai Paint','S2214V':'Akzo Nobel','NS-1S-E0114':'Cornel'}[color])
   stations=[p for p,n in zip(['PP17','PP18','PP19','PP20'],[sum(qty[:3]),qty[3],sum(qty[4:6]),qty[6]]) if n]
   put(f'Z{r}',' / '.join(stations))
  changes[f'xl/worksheets/sheet{page}.xml']=shift_shape_ids(xml_bytes(sh),page)
  changes[f'xl/worksheets/_rels/sheet{page}.xml.rels']=worksheet_rels(z.read('xl/worksheets/_rels/sheet1.xml.rels'),page)
  for part in ['drawing','vmlDrawing']:
   ext='xml' if part=='drawing' else 'vml'
   changes[f'xl/drawings/{part}{page}.{ext}']=shift_shape_ids(z.read(f'xl/drawings/{part}1.{ext}'),page)
  if page==2:
   changes['xl/drawings/_rels/drawing2.xml.rels']=z.read('xl/drawings/_rels/drawing1.xml.rels')
   changes['xl/printerSettings/printerSettings2.bin']=z.read('xl/printerSettings/printerSettings1.bin')
   for i in range(1,10):changes[f'xl/ctrlProps/ctrlProp{i+9}.xml']=z.read(f'xl/ctrlProps/ctrlProp{i}.xml')
 with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as target:
  for info in z.infolist():
   if info.filename=='xl/calcChain.xml':continue
   target.writestr(copy.copy(info),changes.pop(info.filename,z.read(info.filename)))
  for n,b in changes.items():target.writestr(n,b)
print('BUILT 27 ITEMS 259 PIECES 2 PAGES')
