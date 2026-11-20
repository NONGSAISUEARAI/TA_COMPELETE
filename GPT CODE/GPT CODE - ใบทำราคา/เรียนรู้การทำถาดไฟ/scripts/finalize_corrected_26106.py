import json,zipfile,copy
from pathlib import Path
from lxml import etree as E
root=Path(__file__).resolve().parents[1]
old=root/'outputs/rfq_26106_rev01'
src=next(p for p in old.glob('*.xlsm') if 'REV' not in p.name)
out=root/'outputs/rfq_26106_corrected'; edits=json.loads((out/'edits.json').read_text())
dest=out/src.name
S='http://schemas.openxmlformats.org/spreadsheetml/2006/main';ns={'s':S}
with zipfile.ZipFile(src) as zin:
 changes={}
 for page,data in edits.items():
  part=f'xl/worksheets/sheet{page}.xml';sh=E.fromstring(zin.read(part));cells={c.get('r'):c for c in sh.findall('.//s:c',ns)}
  for a,v in data.items():
   if a.startswith('V') and a[1:].isdigit() and int(a[1:])>=7 and v is not None:v='1 \u0e14\u0e49\u0e32\u0e19'
   if a.startswith('X') and a[1:].isdigit() and int(a[1:])>=7 and v is not None:v='\u0e0a\u0e34\u0e49\u0e19'
   c=cells[a];c.attrib.pop('t',None)
   for child in list(c):
    if E.QName(child).localname in ('v','f','is'):c.remove(child)
   if isinstance(v,str):
    c.set('t','inlineStr');E.SubElement(E.SubElement(c,f'{{{S}}}is'),f'{{{S}}}t').text=v
   elif v is not None:E.SubElement(c,f'{{{S}}}v').text=str(v)
  changes[part]=E.tostring(sh,encoding='UTF-8',xml_declaration=True,standalone=True)
 if dest.exists():
  backup=dest.with_suffix('.before_unicode_fix.xlsm')
  if backup.exists():raise FileExistsError(backup)
  dest.rename(backup)
 with zipfile.ZipFile(dest,'w') as zout:
  for info in zin.infolist():zout.writestr(copy.copy(info),changes.get(info.filename,zin.read(info.filename)))
print('NATIVE FORM PRESERVED; 27 CORRECTED ITEMS')
