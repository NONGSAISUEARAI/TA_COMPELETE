from pathlib import Path
from html import escape, unescape
from html.parser import HTMLParser
import base64
import mimetypes
import re

root=Path(__file__).resolve().parents[2]
folder=root/'outputs/excel26106-html'
styles=[]
pages=[]
image_count=0
class TextOnly(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts=[]
    def handle_data(self, value): self.parts.append(value)

for number in (1,2):
    source=folder/f'page{number}.html'
    raw=source.read_bytes()
    charset=re.search(rb'charset=([^"\s;>]+)',raw[:1000])
    encoding=charset.group(1).decode('ascii') if charset else 'utf-8'
    text=raw.decode(encoding)
    styles.extend(re.findall(r'<style\b[^>]*>(.*?)</style>',text,re.S|re.I))
    body=re.search(r'<body\b[^>]*>(.*?)</body>',text,re.S|re.I).group(1)
    body=re.sub(r'<!--\[if.*?<!\[endif\]-->', '',body,flags=re.S|re.I)
    body=re.sub(r'<script\b[^>]*>.*?</script>','',body,flags=re.S|re.I)
    def embed(match):
        global image_count
        name=unescape(next(v for v in match.groups() if v is not None))
        if name.startswith(('data:', '#')): return match.group(0)
        asset=(source.parent/name.replace('\\','/')).resolve()
        if not asset.is_relative_to(folder.resolve()): raise ValueError('Asset outside output folder')
        if not asset.exists(): raise FileNotFoundError(asset)
        data=base64.b64encode(asset.read_bytes()).decode('ascii')
        mime=mimetypes.guess_type(asset.name)[0] or 'application/octet-stream'
        image_count+=1
        return f'src="data:{mime};base64,{data}"'
    body=re.sub(r'\bsrc\s*=\s*(?:"([^"]+)"|\x27([^\x27]+)\x27|([^\s>]+))',embed,body,flags=re.I)
    parser=TextOnly(); parser.feed(body)
    visible=' '.join(parser.parts)
    expected=20 if number==1 else 7
    codes=set(re.findall(r'PJ25-031AL-TRAY-LT-VA-\d{2}',visible))
    if len(codes)!=expected: raise ValueError(f'Page {number}: {len(codes)} codes, expected {expected}')
    if 'BU2-DE-26106' not in visible: raise ValueError('Missing document number')
    pages.append(f'<section class="rfq-page" id="page{number}" aria-label="หน้า {number} จาก 2"><h2>หน้า {number} / 2</h2><div class="rfq-sheet">{body}</div></section>')

doc='''<!doctype html>
<html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BU2-DE-26106 — ใบขอราคา</title>
<style>
body{margin:0;background:#e8edf2;color:#17202a;font-family:Tahoma,Arial,sans-serif}
.rfq-top{padding:18px 24px;background:#fff;border-bottom:1px solid #bcc8d2;display:flex;align-items:center;gap:24px;flex-wrap:wrap}
.rfq-top h1{margin:0;font-size:20px;font-weight:500}
.rfq-top nav{display:flex;gap:16px}.rfq-top a{color:#164f80}
main{padding:24px;display:grid;gap:24px}.rfq-page{min-width:0}
.rfq-page h2{font-size:14px;font-weight:500;margin:0 0 10px}
.rfq-sheet{overflow-x:auto;background:white;padding:18px;box-shadow:0 1px 5px #0002}
.rfq-sheet>div{margin:0!important;text-align:left}
@media(max-width:600px){main{padding:10px}.rfq-top{padding:14px}.rfq-sheet{padding:8px}}
@media print{body{background:white}.rfq-top,.rfq-page>h2{display:none}main{display:block;padding:0}.rfq-page{break-after:page}.rfq-sheet{overflow:visible;box-shadow:none;padding:0}}
</style>
'''+''.join('<style>'+s+'</style>' for s in styles)+'''</head><body>
<header class="rfq-top"><h1>BU2-DE-26106</h1><nav aria-label="เลือกหน้า"><a href="#page1">หน้า 1</a><a href="#page2">หน้า 2</a></nav></header>
<main>'''+''.join(pages)+'''</main></body></html>'''
if re.search(r'\bsrc=["\x27](?!data:)',doc,re.I): raise ValueError('External asset reference remains')
output=folder/'BU2-DE-26106-full-form.html'
output.write_text(doc,encoding='utf-8')
print('SELF-CONTAINED HTML: 2 pages; 27 item codes; embedded images:',image_count)
print('Size:',output.stat().st_size)
