from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET
import json

root=Path(__file__).resolve().parents[2]
source=root/'ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx'
ns={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main','r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}
with ZipFile(source) as z:
    shared=[''.join(si.itertext()) for si in ET.fromstring(z.read('xl/sharedStrings.xml'))]
    workbook=ET.fromstring(z.read('xl/workbook.xml'))
    print('WORKBOOK',ET.tostring(workbook,encoding='unicode'))
    print('RELS',z.read('xl/_rels/workbook.xml.rels').decode())
    print('PARTS',json.dumps([n for n in z.namelist() if any(s in n for s in ['drawing','ctrlProp','vml','activeX','printer','sheet'])],ensure_ascii=False))
    for name in [n for n in z.namelist() if n.startswith('xl/worksheets/sheet') and n.endswith('.xml')]:
        sheet=ET.fromstring(z.read(name));print('SHEET',name)
        for row in sheet.findall('s:sheetData/s:row',ns):
            cells=[]
            for c in row:
                v=c.findtext('s:v',default='',namespaces=ns);f=c.findtext('s:f',default='',namespaces=ns)
                if c.get('t')=='s':v=shared[int(v)] if v else ''
                if c.get('t')=='inlineStr':v=''.join(c.find('s:is',ns).itertext())
                if v or f:cells.append([c.get('r'),v,f])
            if cells:print(json.dumps(cells,ensure_ascii=False))
        print('MERGES',[x.get('ref') for x in sheet.findall('s:mergeCells/s:mergeCell',ns)])
        for key in ['sheetViews','sheetFormatPr','printOptions','pageMargins','pageSetup','headerFooter','drawing','legacyDrawing','controls','extLst','dataValidations']:
            node=sheet.find('s:'+key,ns)
            if node is not None:print(key,ET.tostring(node,encoding='unicode')[:2500])
    for name in z.namelist():
        if ('ctrlProps/' in name or 'vmlDrawing' in name or 'worksheets/_rels' in name) and not name.endswith('/'):
            data=z.read(name).decode(errors='replace')
            print('NATIVE',name,data[:30000])
