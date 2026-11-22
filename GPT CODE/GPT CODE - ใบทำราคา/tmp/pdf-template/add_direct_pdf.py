from pathlib import Path
import hashlib,json,re

ROOT=Path(__file__).resolve().parents[2]
target=ROOT/'outputs/rfq_26106_from_template/BU2-DE-26106.html'
prototype=ROOT/'ฟอร์มกลาง/BU2-DE-26xxx.html'
prototype_hash=hashlib.sha256(prototype.read_bytes()).hexdigest()
raw=target.read_bytes();html=raw.decode('utf-8')
original_model=re.search(r'<script[^>]*id="template-model"[^>]*>(.*?)</script>',html,re.S).group(1)
assert 'id="pdf-export-library"' not in html
backup=target.parent/'history/BU2-DE-26106-before-direct-pdf.html'
assert not backup.exists()
backup.write_bytes(raw)
runtime=Path('C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1119-907-0_26.1119.907.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules')
pdf_lib=(runtime/'pdf-lib/dist/pdf-lib.min.js').read_text(encoding='utf-8')
fontkit=(Path(__file__).parent/'vendor/fontkit.umd.min.js').read_text(encoding='utf-8')
license_text=(runtime/'pdf-lib/LICENSE.md').read_text(encoding='utf-8')
license_text=license_text.replace('Copyright (c) 2019 Andrew Dillon','Copyright (c) 2019 Andrew Dillon\nCopyright (c) 2014-present Devon Govett (fontkit)')
libraries='\n<!-- PDF export: pdf-lib 1.17.1, @pdf-lib/fontkit 1.1.1; embedded for offline use.\n'+license_text+'-->\n'
for ident,source in [('pdf-export-library',pdf_lib),('pdf-fontkit-library',fontkit)]:
    source=re.sub(r'//# sourceMappingURL=[^\r\n]*','',source)
    source=source.replace('</script','<\\/script')
    libraries+=f'<script id="{ident}">\n{source}\n</script>\n'
html=html.replace('<script>\nconst model=',libraries+'<script>\nconst model=',1)
assert 'id="pdf-export-library"' in html
old=Path(__file__).with_name('file_naming_controls.js').read_text(encoding='utf-8')
start=old.index("document.getElementById('save-pdf').addEventListener")
end=old.index('\nsyncFileName();',start)
old_handler=old[start:end]
assert html.count(old_handler)==1
direct=Path(__file__).with_name('direct_pdf_export.js').read_text(encoding='utf-8')
html=html.replace(old_handler,direct,1)
html=html.replace('id="save-pdf">Save as PDF</button>','id="save-pdf">ดาวน์โหลด PDF</button>',1)
assert re.search(r'<script[^>]*id="template-model"[^>]*>(.*?)</script>',html,re.S).group(1)==original_model
assert hashlib.sha256(prototype.read_bytes()).hexdigest()==prototype_hash
target.write_text(html,encoding='utf-8')
script=re.search(r'<script>\s*(const model=.*?)</script>',html,re.S).group(1)
Path(__file__).with_name('direct_pdf_check.js').write_text(script,encoding='utf-8')
model=json.loads(original_model)
print(json.dumps({'htmlBytes':target.stat().st_size,'items':len(model['current']),'qty':sum(int(r['qty']) for r in model['current']),'pages':model['pageCount'],'prototypeUnchanged':True,'dataUnchanged':True,'pdf':'direct offline vector export'},ensure_ascii=False))
