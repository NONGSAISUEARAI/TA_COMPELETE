from pathlib import Path
import hashlib,importlib.util,re,shutil

root=Path(__file__).resolve().parents[2]
source=root/'outputs/rfq_26106_from_template/BU2-DE-26106.html'
target=root/'ฟอร์มกลาง/BU2-DE-26xxx-MASTER.html'
skill=root/'skills/rfq-html'
spec=importlib.util.spec_from_file_location('rfq_builder',skill/'scripts/create_rfq.py')
builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
raw=source.read_bytes();source_hash=hashlib.sha256(raw).hexdigest()
text=raw.decode('utf-8');model=builder.read_model(text)
model['headers']={key:'' for key in model['headers']}
model['headers'].update(documentNo='BU2-DE-26xxx',pageNumber='1/1')
for key in ['current','document','original','new','secondary','pageChecks']:
    model[key]=[]
model.update(pageCount=1,mode='document',documentTitle='BU2-DE-26xxx',downloadFilename='BU2-DE-26xxx_โครงการ.html')
model['fileNaming']={'materialName':'','baseName':'BU2-DE-26xxx_โครงการ','manual':False}
model['defaultChecks']={key:False for key in model['defaultChecks']}
text=builder.put_model(text,model)
text=text.replace('placeholder="เช่น ถาดไฟ VA และ SOLID"','placeholder="เช่น แผ่นอลูมิเนียม"')
text=text.replace("model.fileNaming=model.fileNaming||{materialName:'ถาดไฟ VA และ SOLID',baseName:'',manual:false};","model.fileNaming=model.fileNaming||{materialName:'',baseName:'',manual:false};")
# Remove template checkbox defaults; page rendering resolves all actual values.
start=text.index('<template id="page-template">');end=text.index('</template>',start)
part=text[start:end]
part=re.sub(r'(<input\b[^>]*type="checkbox"[^>]*?)\s+checked(?:="[^"]*")?',r'\1',part)
text=text[:start]+part+text[end:]
# Keep the visible toolbar heading in step with an edited document number.
needle="document.title=safeFileBase(model.fileNaming.baseName)||automaticFileBase();"
text=text.replace(needle,needle+"\n  document.querySelector('.toolbar h1').textContent=model.headers.documentNo||'BU2-DE-26xxx';",1)
assert 'BU2-DE-26106' not in text
assert 'PJ25-031' not in text
assert 'MRT PURPLE LINE' not in text
assert '3,740' not in text
assert builder.read_model(text)['materials']==builder.read_model(raw.decode('utf-8'))['materials']
if target.exists():raise FileExistsError(target)
target.write_text(text,encoding='utf-8')
(skill/'assets').mkdir(exist_ok=True)
shutil.copy2(target,skill/'assets/BU2-DE-26xxx-MASTER.html')
assert hashlib.sha256(source.read_bytes()).hexdigest()==source_hash
print('Created blank shared master and portable skill asset; RFQ 26106 unchanged')
