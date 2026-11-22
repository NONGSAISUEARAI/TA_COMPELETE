from pathlib import Path
import hashlib,importlib.util,json,subprocess,sys,tempfile

root=Path(__file__).resolve().parents[2]
skill=root/'skills/rfq-html'
script=skill/'scripts/create_rfq.py'
spec=importlib.util.spec_from_file_location('rfq_builder',script)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
master=root/'ฟอร์มกลาง/BU2-DE-26xxx-MASTER.html'
before=hashlib.sha256(master.read_bytes()).hexdigest()
text=master.read_text(encoding='utf-8');blank=module.read_model(text)
assert not blank['current'] and blank['pageCount']==1
assert not any(blank['defaultChecks'].values())
assert all(not value for key,value in blank['headers'].items() if key not in {'documentNo','pageNumber'})
assert master.read_bytes()==(skill/'assets/BU2-DE-26xxx-MASTER.html').read_bytes()
qa=Path(tempfile.mkdtemp(prefix='rfq-skill-',dir=root/'tmp'))
payload={'headers':{'documentNo':'BU2-DE-26TEST','project':'QA ONLY'},'materialName':'QA MATERIAL','checks':{'quote':True},'rows':[{'description':'QA DUPLICATE ROW','materialCode':'1','qty':2,'unit':'ชิ้น'} for _ in range(21)]}
source=qa/'data.json';source.write_text(json.dumps(payload,ensure_ascii=False),encoding='utf-8')
output=qa/'generated.html'
command=[sys.executable,str(script),'--input',str(source),'--output',str(output)]
run=subprocess.run(command,check=True,capture_output=True,text=True)
report=json.loads(run.stdout)
model=module.read_model(output.read_text(encoding='utf-8'))
assert report['items']==21 and report['quantity']==42 and report['pages']==2
assert len(model['current'])==21 and model['current'][0]['description']==model['current'][1]['description']
assert [row['no'] for row in model['current']]==list(map(str,range(1,22)))
assert model['current'][0]['material']==blank['materials']['1']
assert model['pageChecks'][0]['quote'] and model['pageChecks'][1]['quote']
assert subprocess.run(command,capture_output=True).returncode!=0
bad={**payload,'rows':[{'materialCode':'INVALID','qty':1}]}
try:module.create(text,bad)
except ValueError:pass
else:raise AssertionError('Invalid material code accepted')
_,missing=module.create(text,{**payload,'rows':[{'description':'QA MISSING QTY','materialCode':'1'}]})
assert missing['warnings'] and missing['quantity']==0
assert hashlib.sha256(master.read_bytes()).hexdigest()==before
(root/'tmp/pdf-template/skill-qa-location.json').write_text(json.dumps({'directory':str(qa),'html':str(output)},ensure_ascii=False),encoding='utf-8')
print(json.dumps({'blankMaster':True,'portableAssetMatches':True,'pagination21Rows':True,'duplicateRowsRetained':True,'materialLookup':True,'overwriteBlocked':True,'invalidCodeRejected':True,'missingQuantityWarned':True,'masterUnchanged':True,'qaHtml':str(output)},ensure_ascii=True,indent=2))
