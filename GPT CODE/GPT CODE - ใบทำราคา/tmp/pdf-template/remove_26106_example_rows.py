from pathlib import Path
import copy,hashlib,json,os,re,tempfile

root=Path(__file__).resolve().parents[2]
document=root/'outputs/rfq_26106_from_template/BU2-DE-26106.html'
template=root/'ฟอร์มกลาง/BU2-DE-26xxx.html'
template_hash=hashlib.sha256(template.read_bytes()).hexdigest()
raw=document.read_bytes()
match=re.search(rb'(<script\b[^>]*\bid=["\x27]template-model["\x27][^>]*>)(.*?)(</script>)',raw,re.S)
assert match,'Missing template-model'
before=json.loads(match.group(2).decode('utf-8'))
model=copy.deepcopy(before)
assert len(before['current'])==53
removed=[r for r in before['current'] if 28<=int(r['no'])<=43]
assert len(removed)==16 and all(r['sourceGroup']=='STD' for r in removed)
assert sum(int(r['qty']) for r in removed)==3278

for key in ('current','document','original','new'):
    rows=model.get(key)
    if not isinstance(rows,list) or not rows:continue
    # These document datasets must have the same numbering before the edit.
    if len(rows)==53:
        kept=[r for r in rows if not 28<=int(r['no'])<=43]
        assert len(kept)==37
        for i,row in enumerate(kept,1):row['no']=str(i)
        model[key]=kept
    else:
        assert not any(r.get('sourceGroup')=='STD' for r in rows)

rows=model['current']
assert len(rows)==37 and sum(int(r['qty']) for r in rows)==462
assert rows[:27]==before['current'][:27]
for old,new in zip(before['current'][43:],rows[27:]):
    assert {k:v for k,v in old.items() if k!='no'}=={k:v for k,v in new.items() if k!='no'}
assert [r['no'] for r in rows]==[str(i) for i in range(1,38)]
assert [re.search(r'AL-TRAY-SO-VA-(\d{2})$',r['description']).group(1) for r in rows[27:]]==[f'{i:02}' for i in range(1,11)]
assert not any(r.get('sourceGroup')=='STD' for r in rows)
assert not any(any(str(v).strip() for v in row.values()) for page in model.get('secondary',[]) for row in (page or [])),'Unexpected data in secondary table'
model['pageCount']=2
model['headers']['pageNumber']='1/2'
model['pageChecks']=model.get('pageChecks',[])[:2]
model['secondary']=model.get('secondary',[])[:2]
payload=json.dumps(model,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').encode('utf-8')
updated=raw[:match.start(2)]+payload+raw[match.end(2):]
updated=updated.replace('ใบขอราคา 53 รายการ'.encode('utf-8'),'ใบขอราคา 37 รายการ'.encode('utf-8'))
assert b'"sourceGroup":"STD"' not in updated
assert re.findall(rb'<script>(.*?)</script>',raw,re.S)==re.findall(rb'<script>(.*?)</script>',updated,re.S)
history=document.parent/'history';history.mkdir(exist_ok=True)
backup=history/'BU2-DE-26106-before-removing-examples.html'
if backup.exists():raise FileExistsError(backup)
backup.write_bytes(raw)
with tempfile.NamedTemporaryFile(dir=document.parent,prefix='.26106-',suffix='.tmp',delete=False) as f:
    f.write(updated);temp_path=Path(f.name)
os.replace(temp_path,document)
assert hashlib.sha256(template.read_bytes()).hexdigest()==template_hash
saved=json.loads(re.search(rb'<script\b[^>]*\bid=["\x27]template-model["\x27][^>]*>(.*?)</script>',document.read_bytes(),re.S).group(1).decode('utf-8'))
assert saved==model
report={'items':37,'qty':462,'pages':2,'removedItems':16,'removedQty':3278,'solidRange':[28,37],'solidCodes':['01','10'],'solidQty':203,'templateUnchanged':True,'templateSHA256':template_hash,'backup':str(backup),'pageBreakdown':[{'page':i+1,'items':len(rows[i*20:(i+1)*20]),'qty':sum(int(r['qty']) for r in rows[i*20:(i+1)*20]),'firstItem':rows[i*20]['no'],'lastItem':rows[min(len(rows),(i+1)*20)-1]['no']} for i in range(2)]}
(document.parent/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
(document.parent/'items.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('backup','templateSHA256')},ensure_ascii=False,indent=2))
