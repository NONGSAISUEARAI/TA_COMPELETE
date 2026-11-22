from pathlib import Path
from xml.etree import ElementTree as E
from collections import Counter
from datetime import date,timedelta
import copy,hashlib,json,re,zipfile

ROOT=Path(__file__).resolve().parents[2]
template_path=ROOT/'outputs/rfq-html-template/RFQ-vector-template.html'
html=template_path.read_text(encoding='utf-8')
template_hash=hashlib.sha256(template_path.read_bytes()).hexdigest()
match=re.search(r'(<script type="application/json" id="template-model">)(.*?)(</script>)',html,re.S)
template=json.loads(match.group(2))
source=next((ROOT/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106_height17_ready').glob('*.xlsm'))
ns={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
field_cols={'no':'A','description':'B','materialCode':'E','thickness':'I','special':'J','width':'K','height':'L','length':'M','cc':'N','sp':'O','pc':'P','acp':'Q','otherCoat':'R','specialColor':'S','paintType':'T','brand':'U','sides':'V','qty':'W','unit':'X','cost':'Y','remark':'Z'}
va=[]
with zipfile.ZipFile(source) as z:
    shared=[''.join(x.itertext()) for x in E.fromstring(z.read('xl/sharedStrings.xml'))]
    for page in (1,2):
        values={}
        for cell in E.fromstring(z.read(f'xl/worksheets/sheet{page}.xml')).findall('.//s:c',ns):
            if cell.get('t')=='inlineStr':value=''.join(x.text or '' for x in cell.findall('.//s:t',ns))
            else:
                value=cell.findtext('s:v',default='',namespaces=ns)
                if cell.get('t')=='s':value=shared[int(value)] if value else ''
            values[cell.get('r')]=value
        assert values['Z2']=='PJ25-031'
        for r in range(7,27):
            if not values.get(f'A{r}'):continue
            row={k:values.get(f'{c}{r}','') for k,c in field_cols.items()}
            row['material']=template['materials'].get(row['materialCode'],'')
            row['qty']=int(float(row['qty']))
            codes=re.findall(r'PC\d+',row['remark'])
            row['remark']=' / '.join(dict.fromkeys(codes))
            row['description']=' '.join(row['description'].split())
            va.append(row)
assert len(va)==27 and sum(r['qty'] for r in va)==259
standard=copy.deepcopy(template['original'])
solid=copy.deepcopy(template['new'])
groups=[('VA',va,27,259),('STD',standard,16,3278),('SOLID',solid,10,203)]
rows=[]
for group,items,count,qty in groups:
    assert len(items)==count and sum(int(r['qty']) for r in items)==qty
    for item in items:
        item['sourceGroup']=group
        item['material']=template['materials'][str(item['materialCode'])]
        item['no']=str(len(rows)+1)
        item['qty']=int(item['qty'])
        assert re.fullmatch(r'(PC\d+)?',item['remark'])
        assert item['width'] in ('249','249.0')
        assert item['thickness']=='1.2'
        rows.append(item)
assert len(rows)==53 and sum(r['qty'] for r in rows)==3740
issue=date(2026,11,22);due=issue+timedelta(days=14)
model=copy.deepcopy(template)
model.update(mode='document',current=rows,document=copy.deepcopy(rows),original=copy.deepcopy(rows),new=[],pageCount=3,pageChecks=[],secondary=[],documentTitle='BU2-DE-26106',downloadFilename='BU2-DE-26106.html')
model['headers'].update(documentNo='BU2-DE-26106',job='PJ25-031',project='MRT PURPLE LINE 4 STATION (PP17 - PP20)',customer='CKST',dueDay=str(due.day),dueMonth=str(due.month),dueYear=str((due.year+543)%100),requestDate=issue.strftime('%d/%m/%y'),pageNumber='1/3')
model['pageChecks']=[copy.deepcopy(model['defaultChecks']) for _ in range(3)]
html=html[:match.start(2)]+json.dumps(model,ensure_ascii=False,separators=(',',':'))+html[match.end(2):]
html=html.replace('<title>RFQ - HTML Template</title>','<title>BU2-DE-26106 - MRT PURPLE LINE 4 STATION</title>')
html=html.replace('<h1>ใบขอราคา</h1>','<h1>BU2-DE-26106</h1>')
html=html.replace('<option value="original">ตัวอย่าง PDF เดิม</option><option value="new">ข้อมูลใหม่ 203 ชิ้น</option><option value="blank">ฟอร์มว่าง</option>','<option value="document">ใบขอราคา 53 รายการ</option>')
html=html.replace("a.download='RFQ-template-edited.html'","a.download='BU2-DE-26106.html'")
out=ROOT/'outputs/rfq_26106_rebuilt';out.mkdir(parents=True,exist_ok=True)
dest=out/'BU2-DE-26106.html';dest.write_text(html,encoding='utf-8')
report={'document':'BU2-DE-26106','job':'PJ25-031','issueDate':issue.isoformat(),'dueDate':due.isoformat(),'totalItems':len(rows),'totalQty':sum(r['qty'] for r in rows),'groups':[{'group':g,'items':len(items),'qty':sum(r['qty'] for r in items)} for g,items,_,_ in groups],'pages':[{'page':p+1,'items':len(rows[p*20:(p+1)*20]),'qty':sum(r['qty'] for r in rows[p*20:(p+1)*20]),'firstItem':rows[p*20]['no'],'lastItem':rows[min((p+1)*20,len(rows))-1]['no']} for p in range(3)],'colorQty':dict(Counter()),'templateUnchanged':hashlib.sha256(template_path.read_bytes()).hexdigest()==template_hash}
for row in rows:
    color=row['pc'] or row['specialColor'];report['colorQty'][color]=report['colorQty'].get(color,0)+row['qty']
(out/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
(out/'items.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
Path(__file__).with_name('document_26106_check.js').write_text(re.search(r'<script>(.*?)</script>',html,re.S).group(1),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
