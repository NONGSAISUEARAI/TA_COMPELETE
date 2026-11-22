from pathlib import Path
import copy,hashlib,json,os,re,tempfile

root=Path(__file__).resolve().parents[2]
document=root/'outputs/rfq_26106_from_template/BU2-DE-26106.html'
prototype=root/'ฟอร์มกลาง/BU2-DE-26xxx.html'
prototype_hash=hashlib.sha256(prototype.read_bytes()).hexdigest()
raw=document.read_bytes();text=raw.decode('utf-8')
assert 'id="file-name"' not in text,'File naming controls already exist'
match=re.search(r'(<script\b[^>]*\bid=["\x27]template-model["\x27][^>]*>)(.*?)(</script>)',text,re.S)
model=json.loads(match.group(2))
assert len(model['current'])==37 and sum(int(r['qty']) for r in model['current'])==462
before=copy.deepcopy(model)
material='ถาดไฟ VA และ SOLID'
project=re.sub(r'^\s*โครงการ\s*','',model['headers']['project']).strip()
base=f"{model['headers']['documentNo']}_โครงการ {project} {material}"
model['fileNaming']={'materialName':material,'baseName':base,'manual':False}
model['downloadFilename']=base+'.html'
text=text[:match.start(2)]+json.dumps(model,ensure_ascii=False,separators=(',',':'))+text[match.end(2):]
css='''
.file-settings{display:flex;align-items:end;gap:12px;flex-wrap:wrap;padding:12px 18px;background:#f8fafc;border-bottom:1px solid #bbc7d1;font:13px Tahoma,Arial,sans-serif}
.file-settings label{display:flex;flex-direction:column;gap:5px;min-width:220px}.file-settings .material-field{flex:0 1 260px}.file-settings .filename-field{flex:1 1 460px}
.file-settings input{width:100%;min-width:0;font:13px Tahoma,Arial,sans-serif;padding:8px 10px;color:#172b3a;background:#fff;border:1px solid #a3b1be;border-radius:4px}
.file-settings button{font:13px Tahoma,Arial,sans-serif;padding:8px 11px;background:#fff;color:#244c6b;border:1px solid #a3b1be;border-radius:4px;cursor:pointer}
.file-settings .save-status{flex:1 0 100%;font-size:12px;color:#3c5264;overflow-wrap:anywhere;min-height:0}.file-settings .save-status:empty{display:none}
@media(max-width:600px){.file-settings label{flex:1 1 100%;min-width:0}}
@media print{.file-settings{display:none!important}html,body{-webkit-print-color-adjust:exact;print-color-adjust:exact}}
'''
text=text.replace('</style></head>',css+'</style></head>',1)
settings='''
<section class="file-settings" aria-label="ตั้งชื่อไฟล์">
<label class="material-field" for="file-material">ชื่อวัสดุ<input id="file-material" type="text" placeholder="เช่น ถาดไฟ VA และ SOLID" autocomplete="off"></label>
<label class="filename-field" for="file-name">ชื่อไฟล์ (ไม่ต้องใส่นามสกุล)<input id="file-name" type="text" autocomplete="off" spellcheck="false"></label>
<button type="button" id="auto-file-name">ตั้งชื่ออัตโนมัติ</button>
<span id="file-save-status" class="save-status" role="status" aria-live="polite"></span>
</section>
'''
assert text.count('</header>')==1
text=text.replace('</header>','</header>'+settings,1)
assert text.count('<button type="button" id="print">พิมพ์</button>')==1
text=text.replace('<button type="button" id="print">พิมพ์</button>','<button type="button" id="save-pdf">Save as PDF</button><button type="button" id="print">พิมพ์</button>',1)
assert text.count("document.getElementById('print').addEventListener('click',()=>window.print());")==1
text=text.replace("document.getElementById('print').addEventListener('click',()=>window.print());","document.getElementById('print').addEventListener('click',()=>{exportFileBase();window.print();});",1)
assert text.count("document.getElementById('save').addEventListener('click',()=>{")==1
text=text.replace("document.getElementById('save').addEventListener('click',()=>{","document.getElementById('save').addEventListener('click',()=>{\n  const saveBase=exportFileBase();",1)
text,count=re.subn(r"a\.download='[^']+\.html'","a.download=saveBase+'.html'",text)
assert count==1
needle="for(const other of pages.querySelectorAll(`[data-header=\"${el.dataset.header}\"]`))if(other!==el)other.textContent=el.textContent;\n    return;"
assert needle in text
text=text.replace(needle,needle.replace('    return;','    if([\'documentNo\',\'project\'].includes(el.dataset.header))syncFileName();\n    return;'),1)
extra=Path(__file__).with_name('file_naming_controls.js').read_text(encoding='utf-8')
text,inserted=re.subn(r'renderPages\(\);resize\(\);(\s*document\.fonts\.ready)',lambda m:extra+'\nrenderPages();resize();'+m.group(1),text)
assert inserted==1
# Avoid starting with an obsolete title before the naming controls initialize.
text=re.sub(r'<title>[^<]*</title>',lambda _: '<title>'+base+'</title>',text,count=1)
updated=text.encode('utf-8')
after=json.loads(re.search(r'<script\b[^>]*\bid=["\x27]template-model["\x27][^>]*>(.*?)</script>',text,re.S).group(1))
for key in before:
    if key!='downloadFilename':assert after[key]==before[key],key
history=document.parent/'history';history.mkdir(exist_ok=True)
backup=history/'BU2-DE-26106-before-file-naming.html'
if backup.exists():raise FileExistsError(backup)
backup.write_bytes(raw)
with tempfile.NamedTemporaryFile(dir=document.parent,prefix='.filename-',suffix='.tmp',delete=False) as f:
    f.write(updated);temporary=Path(f.name)
os.replace(temporary,document)
assert hashlib.sha256(prototype.read_bytes()).hexdigest()==prototype_hash
script=re.search(r'<script>(.*?)</script>',text,re.S).group(1)
Path(__file__).with_name('file_naming_check.js').write_text(script,encoding='utf-8')
print(json.dumps({'items':len(after['current']),'qty':sum(int(r['qty']) for r in after['current']),'pages':after['pageCount'],'defaultFilename':base,'templateUnchanged':True,'dataUnchanged':True,'savePDF':'native print dialog with document filename'},ensure_ascii=False,indent=2))
