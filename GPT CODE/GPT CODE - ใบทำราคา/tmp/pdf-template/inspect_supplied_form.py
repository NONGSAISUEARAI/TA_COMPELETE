from pathlib import Path
from collections import Counter
from html.parser import HTMLParser
import json,re,hashlib,difflib

root=Path(__file__).resolve().parents[2]
path=root/'ฟอร์มกลาง/BU2-DE-26xxx.html'
text=path.read_text(encoding='utf-8')
match=re.search(r'<script[^>]*id=["\x27]template-model["\x27][^>]*>(.*?)</script>',text,re.S)
if not match:raise ValueError('No template-model found')
model=json.loads(match.group(1))
rows=model.get('current',[])
print(json.dumps({'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'modelKeys':list(model),'mode':model.get('mode'),'pageCount':model.get('pageCount'),'rows':len(rows),'qty':sum(float(str(r.get('qty',0)).replace(',','') or 0) for r in rows),'groups':dict(Counter(r.get('sourceGroup','unspecified') for r in rows)),'headers':model.get('headers'),'lastRows':[{'no':r.get('no'),'description':r.get('description'),'length':r.get('length'),'qty':r.get('qty'),'group':r.get('sourceGroup')} for r in rows[-12:]]},ensure_ascii=False,indent=2))
scripts=re.findall(r'<script>(.*?)</script>',text,re.S)
print('SCRIPTS',len(scripts),'TOTAL_JS_CHARS',sum(map(len,scripts)))
previous=(root/'outputs/rfq_26106_rebuilt/BU2-DE-26106.html').read_text(encoding='utf-8')
old_scripts=re.findall(r'<script>(.*?)</script>',previous,re.S)
diff=list(difflib.unified_diff(''.join(old_scripts).splitlines(),''.join(scripts).splitlines(),fromfile='previous-script',tofile='supplied-script',n=2))
print('\n'.join(diff[:100]))
