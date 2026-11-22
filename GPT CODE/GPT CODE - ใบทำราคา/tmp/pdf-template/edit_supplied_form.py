from pathlib import Path
import copy,hashlib,json,re

root=Path(__file__).resolve().parents[2]
source=root/'ฟอร์มกลาง/BU2-DE-26xxx.html'
raw=source.read_bytes()
before_hash=hashlib.sha256(raw).hexdigest()
match=re.search(rb'(<script\b[^>]*\bid=["\x27]template-model["\x27][^>]*>)(.*?)(</script>)',raw,re.S)
if not match:raise ValueError('Missing template-model')
original=json.loads(match.group(2).decode('utf-8'))
model=copy.deepcopy(original)
changes=[]
for key in ('current','document','original','new'):
    rows=model.get(key)
    if not isinstance(rows,list):continue
    solid=[r for r in rows if r.get('sourceGroup')=='SOLID']
    if not solid:continue
    assert len(solid)==10,(key,len(solid))
    for index,row in enumerate(solid,1):
        assert int(row['no'])==43+index
        length=int(float(row['length']))
        row['description']=f'AL.1.2mm.(thk.) TRAY-SOLID-249x{length}mm. / PJ25-031 AL-TRAY-SO-VA-{index:02}'
        if key=='current':changes.append({'item':row['no'],'length':length,'code':f'PJ25-031 AL-TRAY-SO-VA-{index:02}','qty':row['qty']})
    for before,after in zip(original[key],rows):
        if before.get('sourceGroup')!='SOLID':assert before==after
        else:
            assert {k:v for k,v in before.items() if k!='description'}=={k:v for k,v in after.items() if k!='description'}

assert len(changes)==10
assert model['current'][:43]==original['current'][:43]
assert len(model['current'])==53
assert sum(int(r['qty']) for r in model['current'])==3740
assert sum(int(r['qty']) for r in model['current'][43:])==203
assert model['headers']==original['headers']
assert model['pageChecks']==original['pageChecks']
payload=json.dumps(model,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').encode('utf-8')
updated=raw[:match.start(2)]+payload+raw[match.end(2):]
assert b'AL-TRAY-0x-SO-VA' not in updated
assert updated[:match.start(2)]==raw[:match.start(2)]
assert updated[match.start(2)+len(payload):]==raw[match.end(2):]
out=root/'outputs/rfq_26106_from_template';out.mkdir(parents=True,exist_ok=True)
dest=out/'BU2-DE-26106.html'
if dest.exists():raise FileExistsError('Refusing to overwrite an existing output: '+str(dest))
dest.write_bytes(updated)
assert hashlib.sha256(source.read_bytes()).hexdigest()==before_hash
saved=json.loads(re.search(rb'<script\b[^>]*\bid=["\x27]template-model["\x27][^>]*>(.*?)</script>',dest.read_bytes(),re.S).group(1).decode('utf-8'))
assert saved==model
script=re.search(rb'<script>(.*?)</script>',updated,re.S).group(1)
Path(__file__).with_name('supplied_form_check.js').write_bytes(script)
report={'source':str(source),'output':str(dest),'templateSHA256':before_hash,'templateUnchanged':True,'layoutAndScriptBytesUnchanged':True,'earlierItemsUnchanged':True,'items':53,'qty':3740,'pages':model['pageCount'],'solidItems':10,'solidQty':203,'changes':changes}
(out/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('source','output','changes')},ensure_ascii=False,indent=2))
print(json.dumps(changes,ensure_ascii=False))
