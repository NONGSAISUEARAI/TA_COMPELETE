from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as E
import json,importlib.util,re,hashlib
root=Path(__file__).resolve().parents[2]
ns={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
with ZipFile(root/'tmp/pdf-template/edited-qa.xlsx') as z:
    wb=E.fromstring(z.read('xl/workbook.xml'))
    assert len(wb.find('s:sheets',ns))==3
    shape_ids=[]
    def cells(i):
        xml=E.fromstring(z.read(f'xl/worksheets/rfq{i}-sheet1.xml'))
        shape_ids.extend(c.get('shapeId') for c in xml.findall('.//s:control',ns))
        return {c.get('r'):c for c in xml.findall('.//s:sheetData/s:row/s:c',ns)}
    first,second,third=map(cells,[1,2,3])
    val=lambda c:c.findtext('s:v',default='',namespaces=ns) if c.get('t')!='inlineStr' else ''.join(c.find('s:is',ns).itertext())
    assert val(first['W7'])=='12'
    assert val(first['E7'])=='2'
    assert val(first['G7'])=='Alu.coil, MF'
    assert val(third['B31'])=='QA secondary'
    assert val(third['W31'])=='0' and third['W31'].get('t') is None
    assert val(third['W32'])==''
    assert len(shape_ids)==len(set(shape_ids))==27
    total=sum(float(val(c) or 0) for sheet in [first,second,third] for addr,c in sheet.items() if re.fullmatch(r'W(?:[7-9]|1[0-9]|2[0-6]|3[1-9]|4[01])',addr))
    assert total==464
    props=[n for n in z.namelist() if n.startswith('xl/ctrlProps/rfq3-')]
    assert len(props)==9
    checked=sum(E.fromstring(z.read(n)).get('checked')=='Checked' for n in props)
    assert checked==4
spec=importlib.util.spec_from_file_location('rfq',root/'skills/rfq-html/scripts/create_rfq.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
master=(root/'ฟอร์มกลาง/BU2-DE-26xxx-MASTER.html').read_text(encoding='utf-8')
result,report=m.create(master,{'headers':{'documentNo':'BU2-DE-26QA','project':'QA'},'rows':[{'description':'QA','materialCode':'2','qty':0}],'fileName':'QA.xlsx'})
assert report['filename']=='QA' and report['items']==1 and report['quantity']==0
for id in ['excel-template-data','excel-export-library','rfq-excel-export','pdf-export-library','pdf-fontkit-library']:
    assert f'id="{id}"' in result
embedded=re.search(r'id="excel-template-data"[^>]*data-sha256="([^"]+)"',master).group(1)
assert embedded==hashlib.sha256((root/'ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx').read_bytes()).hexdigest()
assert m.read_model(master)['current']==[]
assert (root/'skills/rfq-html/assets/BU2-DE-26xxx-MASTER.html').read_text(encoding='utf-8')==master
print(json.dumps({'editedQuantity':total,'pages':3,'materialChanged':True,'secondaryZeroRetained':True,'allControlIdsUnique':True,'page3QuoteChecked':True,'newDocumentKeepsBothExporters':True,'originalWorkbookUnchanged':True}))
