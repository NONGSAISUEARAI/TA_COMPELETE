from pathlib import Path
import re,json
root=Path(__file__).resolve().parents[2]
folder=root/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106_sorted_20261125'
file=next(folder.glob('*.html'))
text=file.read_text(encoding='utf8')
m=re.search(r'(<script[^>]*id="template-model"[^>]*>)(.*?)(</script>)',text,re.S)
model=json.loads(m[2]);count=0
for key in ['current','document','original']:
 for row in model.get(key,[]):
  if (row.get('specialColor') or row.get('pc'))=='SD-9211':
   row['remark']='PP17 PP18 PP19 PP20'
   if key=='current':count+=1
assert count==18,count
assert len(model['current'])==37 and sum(float(r['qty']) for r in model['current'])==462
backup=folder/'history_before_sd_remark'
backup.mkdir(exist_ok=True)
backup_file=backup/file.name
if not backup_file.exists():backup_file.write_bytes(file.read_bytes())
file.write_text(text[:m.start(2)]+json.dumps(model,ensure_ascii=False,separators=(',',':'))+text[m.end(2):],encoding='utf8')
saved=json.loads(re.search(r'<script[^>]*id="template-model"[^>]*>(.*?)</script>',file.read_text(encoding='utf8'),re.S)[1])
assert all(r['remark']=='PP17 PP18 PP19 PP20' for r in saved['current'] if (r.get('specialColor') or r.get('pc'))=='SD-9211')
print('VERIFIED SD-9211 REMARKS:',count,'ROWS; 37 ITEMS; 462 PCS')
