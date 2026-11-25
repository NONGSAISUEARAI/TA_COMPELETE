from pathlib import Path
import re,json,copy,collections
project=Path(__file__).resolve().parents[2]
src=Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_FL-PART\ALUMINIUM TRAY\ALUMINIUM TRAY - LT (VARIES) & SOLID (VARIES) - REVISON & GROUP SIZE')
files=list(src.glob('BU2-DE-26106*.html'))
assert len(files)==1,files
source=files[0]; text=source.read_text(encoding='utf8')
match=re.search(r'(<script[^>]*id="template-model"[^>]*>)(.*?)(</script>)',text,re.S)
model=json.loads(match[2]); print('KEYS',[(k,len(v) if isinstance(v,(list,dict)) else str(v)[:60]) for k,v in model.items()])
rows=model['current']; before=copy.deepcopy(rows)
rank={'S2214V':0,'SA-09101':0,'SA-05611':1,'NS-1S-E0114':2,'SD-9211':3}
station={'S2214V':'PP17','SA-09101':'PP17','SA-05611':'PP18','NS-1S-E0114':'PP19'}
paint={'S2214V':'PC21010085','SA-09101':'PC21010083','SA-05611':'PC21010082','NS-1S-E0114':'PC21010087'}
def finish(r):return r.get('specialColor') or r.get('pc')
def kind(r):
 if 'TRAY-LT' in r['description']:return 0
 if 'TRAY-SOLID' in r['description'] or 'TRAY-SO' in r['description']:return 1
 raise ValueError(r['description'])
def length(r):return float(r['length'])
def totals(rs):
 out=collections.Counter()
 for r in rs:out[(finish(r),kind(r))]+=float(r['qty'])
 return out
rows.sort(key=lambda r:(rank[finish(r)],kind(r),length(r)))
for i,r in enumerate(rows,1):
 r['no']=str(i)
 color=finish(r)
 if color in station:r['remark']=paint[color]+' '+station[color]
 # SD-9211 retains its original remark; no station is appended.
assert totals(before)==totals(rows)
assert len(rows)==37 and sum(float(r['qty']) for r in rows)==462
for key,value in list(model.items()):
 if key!='current' and isinstance(value,list) and len(value)==len(before) and value==before:model[key]=copy.deepcopy(rows)
model['current']=rows
out=project/'เรียนรู้การทำถาดไฟ'/'outputs'/'rfq_26106_sorted_20261125'
out.mkdir(parents=True,exist_ok=True)
dest=out/source.name
if dest.exists():raise FileExistsError(dest)
updated=text[:match.start(2)]+json.dumps(model,ensure_ascii=False,separators=(',',':'))+text[match.end(2):]
dest.write_text(updated,encoding='utf8')
saved=json.loads(re.search(r'<script[^>]*id="template-model"[^>]*>(.*?)</script>',dest.read_text(encoding='utf8'),re.S)[1])
assert saved['current']==rows
assert re.findall(r'<script[^>]*id="excel-template-data"[^>]*>.*?</script>',text,re.S)==re.findall(r'<script[^>]*id="excel-template-data"[^>]*>.*?</script>',updated,re.S)
print('VERIFIED 37 ROWS 462 PCS; LT BEFORE SO; LENGTH ASC; TEMPLATE UNCHANGED')
print([(r['no'],finish(r),'LT' if kind(r)==0 else 'SO',r['length'],r['qty'],r.get('remark')) for r in rows])
