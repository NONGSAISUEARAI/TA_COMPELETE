from pathlib import Path
from html.parser import HTMLParser
import json,re,hashlib

root=Path(__file__).resolve().parents[2]
paths=[root/'sites/rfq-full-preview/dist/index.html',root/'outputs/rfq-full-preview.html']
pattern=r'AL\.1\.2mm\.\(thk\.\) TRAY-SOLID-249x(\d+)mm\. / AL-TRAY-0x-SO-VA \(L=\1 mm\.\)'
class Security(HTMLParser):
    def __init__(self):super().__init__();self.csp=[];self.frames=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='meta' and a.get('http-equiv','').lower()=='content-security-policy':self.csp.append(a['content'])
        if tag=='iframe':self.frames.append(a)

for path in paths:
    text=path.read_text(encoding='utf-8');before=Security();before.feed(text)
    count=[0]
    def rename(match):
        count[0]+=1
        return f'AL.1.2mm.(thk.) TRAY-SOLID-249x{match.group(1)}mm. / PJ25-031 AL-TRAY-SO-VA-{count[0]:02}'
    updated=re.sub(pattern,rename,text)
    assert count[0]==10,(path,count)
    after=Security();after.feed(updated)
    assert before.csp==after.csp
    assert len(before.frames)==len(after.frames)
    for previous,current in zip(before.frames,after.frames):
        assert {k:v for k,v in previous.items() if k not in ('srcdoc','data-srcdoc')}=={k:v for k,v in current.items() if k not in ('srcdoc','data-srcdoc')}
        inner_before=Security();inner_before.feed(previous.get('data-srcdoc',previous.get('srcdoc','')))
        inner_after=Security();inner_after.feed(current.get('data-srcdoc',current.get('srcdoc','')))
        assert inner_before.csp==inner_after.csp
    path.write_text(updated,encoding='utf-8')
    print(json.dumps({'file':path.name,'renamed':count[0],'CSPUnchanged':True,'sandboxUnchanged':True,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}))
