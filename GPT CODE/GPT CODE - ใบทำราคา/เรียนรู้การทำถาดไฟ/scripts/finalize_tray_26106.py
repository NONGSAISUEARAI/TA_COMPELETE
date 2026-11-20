import json,zipfile,copy
from pathlib import Path
from datetime import datetime
from lxml import etree as E
root=Path.cwd(); out=root/'outputs/rfq_26106'
src=Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_FL-PART\ALUMINIUM TRAY\BU2-DE-26060_โครงการ MRT PURPLE LINE 4 STATION (PP17 - PP20).xlsx')
S='http://schemas.openxmlformats.org/spreadsheetml/2006/main'; ns={'s':S}
edits=json.loads((out/'edits.json').read_text()); edits['C44']=(datetime(2026,11,20)-datetime(1899,12,30)).days
name='BU2-DE-26106 - MRT PURPLE LINE 4 STATION (PP17 - PP20)_20261120-1200.xlsx'
with zipfile.ZipFile(src) as zin:
 sh=E.fromstring(zin.read('xl/worksheets/sheet1.xml'))
 for addr,val in edits.items():
  c=sh.find(f'.//s:c[@r="{addr}"]',ns)
  for ch in list(c):
   if E.QName(ch).localname in ('v','f','is'): c.remove(ch)
  c.attrib.pop('t',None)
  if isinstance(val,str):
   c.set('t','inlineStr'); E.SubElement(E.SubElement(c,f'{{{S}}}is'),f'{{{S}}}t').text=val
  elif val is not None:E.SubElement(c,f'{{{S}}}v').text=str(val)
 wb=E.fromstring(zin.read('xl/workbook.xml'))
 for i,s in enumerate(wb.find('s:sheets',ns)):
  if i:s.set('state','hidden')
 changes={'xl/worksheets/sheet1.xml':E.tostring(sh,xml_declaration=True,encoding='UTF-8',standalone=True),'xl/workbook.xml':E.tostring(wb,xml_declaration=True,encoding='UTF-8',standalone=True)}
 dest=out/name
 if dest.exists():raise FileExistsError(dest)
 with zipfile.ZipFile(dest,'w') as zout:
  for info in zin.infolist():zout.writestr(copy.copy(info),changes.get(info.filename,zin.read(info.filename)))
print(dest)
print('date',edits['C44'])
