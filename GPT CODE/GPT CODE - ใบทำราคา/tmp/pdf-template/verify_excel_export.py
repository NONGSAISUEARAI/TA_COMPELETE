from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as E
import hashlib,json,re,shutil,posixpath

root=Path(__file__).resolve().parents[2]
out=root/'outputs/rfq_26106_from_template'
download=json.loads((root/'tmp/pdf-template/excel-download.json').read_text(encoding='utf-8'))
html=(out/'BU2-DE-26106.html').read_text(encoding='utf-8')
model=json.loads(re.search(r'<script[^>]*id="template-model"[^>]*>(.*?)</script>',html,re.S).group(1))
original=root/'ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx'
dest=out/(model['fileNaming']['baseName']+'.xlsx')
shutil.copy2(download['path'],dest)
S='http://schemas.openxmlformats.org/spreadsheetml/2006/main'
R='http://schemas.openxmlformats.org/officeDocument/2006/relationships'
ns={'s':S}
resolve=lambda owner,target:posixpath.normpath(posixpath.join(posixpath.dirname(owner),target)) if not target.startswith('/') else target.lstrip('/')
cols={'no':'A','description':'B','materialCode':'E','material':'G','thickness':'I','special':'J','width':'K','height':'L','length':'M','cc':'N','sp':'O','pc':'P','acp':'Q','otherCoat':'R','specialColor':'S','paintType':'T','brand':'U','sides':'V','qty':'W','unit':'X','cost':'Y','remark':'Z'}
with ZipFile(original) as source,ZipFile(dest) as z:
    assert z.testzip() is None
    ss=[''.join(si.itertext()) for si in E.fromstring(z.read('xl/sharedStrings.xml'))]
    def value(c):
        if c is None:return ''
        if c.get('t')=='inlineStr':return ''.join(c.find('s:is',ns).itertext())
        v=c.findtext('s:v',default='',namespaces=ns)
        return ss[int(v)] if c.get('t')=='s' else v
    rels={r.get('Id'):r.get('Target') for r in E.fromstring(z.read('xl/_rels/workbook.xml.rels'))}
    sheets=E.fromstring(z.read('xl/workbook.xml')).find('s:sheets',ns)
    assert len(sheets)==model['pageCount']==2
    assert z.read('xl/styles.xml')==source.read('xl/styles.xml')
    first=E.fromstring(source.read('xl/worksheets/sheet1.xml'))
    original_merges=[m.get('ref') for m in first.findall('s:mergeCells/s:mergeCell',ns)]
    total=0;rows=0
    for page,sheet in enumerate(sheets):
        path=resolve('xl/workbook.xml',rels[sheet.get('{'+R+'}id')])
        xml=E.fromstring(z.read(path));cells={c.get('r'):c for c in xml.findall('s:sheetData/s:row/s:c',ns)}
        assert [m.get('ref') for m in xml.findall('s:mergeCells/s:mergeCell',ns)]==original_merges
        assert E.tostring(xml.find('s:cols',ns))==E.tostring(first.find('s:cols',ns))
        heights=lambda sheet:[(r.get('r'),r.get('ht'),r.get('customHeight')) for r in sheet.findall('s:sheetData/s:row',ns)]
        assert heights(xml)==heights(first)
        assert value(cells['Z1'])==model['headers']['documentNo']
        assert value(cells['C2'])==model['headers']['project']
        assert value(cells['Z45'])==f'{page+1}/2'
        assert not value(cells['H44'])
        for index,row in enumerate(model['current'][page*20:page*20+20]):
            er=index+7;rows+=1;total+=float(value(cells['W'+str(er)]))
            for key,col in cols.items():
                expected=str(row.get(key,''));actual=value(cells.get(col+str(er)))
                if key in {'no','materialCode','thickness','width','height','length','qty','cost'} and expected.strip():
                    try:assert float(expected.replace(',',''))==float(actual),(page,er,key,actual,expected)
                    except ValueError:assert actual==expected,(page,er,key,actual,expected)
                else:assert actual==expected,(page,er,key,actual,expected)
            assert cells['G'+str(er)].find('s:f',ns) is not None
            assert cells['E'+str(er)].get('t') is None
            assert cells['W'+str(er)].get('t') is None
        assert not value(cells['A27']) and not value(cells['B27'])
        checks=model['pageChecks'][page]
        vml_path=[n for n in z.namelist() if n.startswith('xl/drawings/rfq'+str(page+1)+'-') and n.endswith('.vml')][0]
        vml=E.fromstring(z.read(vml_path))
        checked=[]
        for client in vml.iter('{urn:schemas-microsoft-com:office:excel}ClientData'):
            if client.get('ObjectType')=='Checkbox':checked.append(client.findtext('{urn:schemas-microsoft-com:office:excel}Checked')=='1')
        keys=['quote','production','ceiling','sunshade','inside','wall','outside','other']
        assert checked==[checks[k] for k in keys]
        props=[]
        for i in range(1,9):
            prop=E.fromstring(z.read(f'xl/ctrlProps/rfq{page+1}-ctrlProp{i}.xml'))
            props.append(prop.get('checked')=='Checked')
        assert props==checked
    assert rows==37 and total==462
    # Every relationship target resolves to an existing package part.
    for path in z.namelist():
        if not path.endswith('.rels'):continue
        owner=path.replace('/_rels/','/').removesuffix('.rels') if path!='_rels/.rels' else ''
        for rel in E.fromstring(z.read(path)):
            if rel.get('TargetMode')=='External':continue
            target=resolve(owner,rel.get('Target'))
            assert target in z.namelist(),(path,target)
    payload_sha=re.search(r'id="excel-template-data"[^>]*data-sha256="([^"]+)"',html).group(1)
    assert hashlib.sha256(original.read_bytes()).hexdigest()==payload_sha
    report={'sheets':len(sheets),'items':rows,'quantity':total,'allFieldsMatch':True,'numericCells':True,'materialFormulas':True,'nativeCheckboxes':True,'templateStyleDefinitionsRetained':True,'widthsHeightsMergesUnchanged':True,'descriptionStyleExtendedFromFirstRow':True,'relationshipsValid':True,'sourceUnchanged':True,'output':str(dest)}
    (out/'excel-export-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(report,ensure_ascii=True,indent=2))
