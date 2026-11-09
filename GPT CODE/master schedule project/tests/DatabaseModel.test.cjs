const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path');
const {boot,dataPattern}=require('./helpers/schedule-harness.cjs');
const root=path.join(__dirname,'..'),html=fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8'),data=JSON.parse(html.match(dataPattern)[1]),old=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/before-lv3-database.json'),'utf8'));
let checks=0;const check=(v,m)=>{assert(v,m);checks++},fresh=()=>{const b=boot(html);b.context.TextDecoder=TextDecoder;return b},csv=rows=>'\ufeff'+rows.map(r=>r.map(v=>'"'+String(v??'').replace(/"/g,'""')+'"').join(',')).join('\r\n')+'\r\n';
const app=fresh(),{run,elements,context}=app,project='pj25-031';
check(data.groups.length===2&&data.tasks.length===36,'Two roots and 36 child records');
check(data.groups[0].pjCode==='PJ25-031'&&data.groups[0].projectWorks==='MRT PURPLE LINE 4 STATION','LV1 combines project code/name');
const products=data.tasks.filter(t=>t.groupId===project&&!t.parentId),works=data.tasks.filter(t=>t.groupId===project&&t.parentId);
assert.deepEqual(products.map(t=>t.product),['C02','C03','C04','C05','C06','C08','C09','C10']);checks++;
check(products.every(t=>t.drawingGroup==='กลุ่มงานฝ้า'&&t.nodeType==='section'),'LV2 combines group/product');
check(works.length===19&&works.every(t=>products.some(p=>p.id===t.parentId)&&t.nodeType==='task'),'Exactly 19 LV3 works');
check(works.every(t=>t.start===null&&t.end===null&&t.actualStart===null&&t.actualEnd===null&&t.progress===null&&t.owner===''),'No fabricated dates, owners or progress');
assert.deepEqual(works.filter(t=>t.area==='C10').map(t=>t.name),['SHOP DWG','MATTERIAL TAKEOFF','PART DWG','MOCKUP (PP17)']);checks++;
assert.deepEqual(data.tasks.filter(t=>t.groupId!==project),old.tasks.filter(t=>t.groupId!==project));checks++;
assert.deepEqual(data.groups[1],old.groups[1]);checks++;
check(data.tasks.flatMap(t=>t.fileCatalog?.files||[]).filter(f=>f.selected).length===14,'All selected legacy files retained');
check(data.tasks.some(t=>t.id==='pp17-036'&&t.name==='PART DWG'),'Existing C10 job ID preserved');
check(!run('isEditor')&&run('drawingCoreHidden'),'Starts Viewer with four core columns hidden');
check(run('leafTasks().length')===19&&run('excelExportRecords().length')===19,'Summary and export count final works only');
check((elements.get('tasks').innerHTML.match(/<tr /g)||[]).length===38,'All tree rows render');
check((elements.get('tasks').innerHTML.match(/data-date-row="plan"/g)||[]).length===76,'Each Start/End has separate Plan line');
check((elements.get('tasks').innerHTML.match(/data-date-row="actual"/g)||[]).length===76,'Each Start/End has separate Actual line');
check(!/db-work[\s\S]*?data-task="pj25-031-c02-work-1"[\s\S]*?<\/tr>/.exec(elements.get('tasks').innerHTML)?.[0].includes('data-add-task-child'),'LV3 has no fourth-level add button');
check(/db-title-line[^>]*>[\s\S]*?MATTERIAL TAKEOFF[\s\S]*?task-files-disclosure/.test(elements.get('tasks').innerHTML),'File disclosure shares work title container');
const original=run('JSON.stringify(state)'),csvText=run('makeScheduleCSV()');context.source=csvText;
check(run('readScheduleCSV(source).database'),'CSV recognized as flat database');
check(run('readScheduleCSV(source).records.length')===19,'CSV pairs 38 phase rows into 19 works');
check(run('buildCSVImportPlan(readScheduleCSV(source)).issues.length')===0&&run('buildCSVImportPlan(readScheduleCSV(source)).changedCount')===0,'No-change CSV round trip');
const rows=JSON.parse(run('JSON.stringify(parseCSVRecords(source.replace(/^\\ufeff/,"")).map(r=>r.map(csvUnescape)))'));
check(rows.length===39&&rows[0].length===22,'CSV header plus 38 rows/22 metadata columns');
check(rows.slice(1).every(r=>r.slice(0,5).every(Boolean)&&r[18]==='Task'&&r[19]&&r[20]&&r[21]),'All rows contain five business fields and stable IDs');
const edit=structuredClone(rows);edit[1][4]=edit[2][4]='Updated Description';edit[1][6]='ตะวัน';edit[1][8]='0';edit[1][11]='2026-11-08';edit[1][12]='2026-11-11';edit[2][11]='2026-11-10';edit[2][12]='2026-11-12';context.edited=csv(edit);
run('var plan=buildCSVImportPlan(readScheduleCSV(edited))');
check(run('plan.issues.length')===0&&run('plan.changedCount')===1,'Task ID updates renamed Description');
check(run('plan.next.tasks.find(t=>t.id==="pj25-031-c02-work-1").start')==='2026-11-09','Sunday Plan moves to Monday');
check(run('plan.next.tasks.find(t=>t.id==="pj25-031-c02-work-1").actualStart')==='2026-11-10','Actual dates independent');
check(run('plan.next.tasks.find(t=>t.id==="pj25-031-c02-work-1").quantity')===0,'Zero quantity preserved');
check(run('JSON.stringify(state)')===original,'Import preview does not mutate state');
run('csvImportPreview=plan;confirmCSVImport()');check(run('JSON.stringify(state)')===original,'Viewer cannot confirm');
run('isEditor=true;csvImportPreview=plan;confirmCSVImport()');check(run('state.tasks[1].name')==='Updated Description','Confirm applies stable ID update');
const reopened=boot(run('snapshot().html'));check(reopened.run('state.tasks[1].actualEnd')==='2026-11-12'&&!reopened.run('isEditor'),'Snapshot persists dates and reopens Viewer');
const moved=fresh();moved.context.text=csv(edit);moved.run('state.tasks.reverse();var p=buildCSVImportPlan(readScheduleCSV(text))');check(moved.run('p.issues.length')===0&&moved.run('p.next.tasks.find(t=>t.id==="pj25-031-c02-work-1").owner')==='ตะวัน','ID matching survives ordering changes');
for(const [label,mutate] of [
 ['wrong project',r=>{r[1][0]=r[2][0]='WRONG'}],
 ['mismatched pair identity',r=>{r[2][19]='other-id'}],
 ['unknown task ID',r=>{r[1][19]=r[2][19]='unknown-id'}],
 ['duplicate task ID',r=>{r[3][19]=r[4][19]=r[1][19]}],
 ['missing business field',r=>{r[1][2]=r[2][2]=''}]
]){const b=fresh(),r=structuredClone(rows);mutate(r);b.context.bad=csv(r);let rejected=false;try{rejected=b.run('buildCSVImportPlan(readScheduleCSV(bad)).issues.length')>0}catch{rejected=true}check(rejected,'Reject '+label)}
const added=fresh(),newRows=[rows[0],...structuredClone(rows.slice(1,3))];for(const r of newRows.slice(1)){r[4]='NEW WORK';r[16]='';r[19]=''}added.context.text=csv(newRows);added.run('var p=buildCSVImportPlan(readScheduleCSV(text))');check(added.run('p.createdCount')===1&&added.run('p.issues.length')===0,'New flat work supports blank WBS/Task ID');check(added.run('p.next.tasks.filter(t=>t.groupId==="pj25-031"&&!t.parentId).length')===8,'New work reuses Product');
for(const r of newRows.slice(1)){r[0]='PJ26-001';r[1]='New Project';r[3]='C11';r[20]=r[21]=''}added.context.text=csv(newRows);added.run('var p2=buildCSVImportPlan(readScheduleCSV(text))');check(added.run('p2.createdCount')===1&&added.run('p2.issues.length')===0&&added.run('p2.next.groups.length')===3,'Complete flat row creates missing project/product');
added.context.text=csvText;check(added.run('buildCSVImportPlan(readScheduleCSV(text),"append").issues.length')===19,'Append refuses existing work duplicates');
run('openTask(null,"pj25-031")');check(elements.get('f-db-level').value==='product'&&elements.get('f-pjCode').readOnly,'Add LV2 inherits project');
check(elements.get('f-name').wrapper.hidden&&!elements.get('f-name').required,'Hidden generic name is not required for Product');
run('$("f-product").value="C11";$("f-drawingGroup").value="กลุ่มงานฝ้า";configureDatabaseTaskForm();$("task-form").listeners.submit[0]({preventDefault(){}})');
check(run('state.tasks.some(t=>t.product==="C11"&&t.nodeType==="section"&&t.parentId===null)'),'Editor creates Product');
run('openTask(null,null,"pj25-031-product-c04")');check(elements.get('f-db-level').value==='work'&&elements.get('f-product').readOnly&&elements.get('f-product').value==='C04','Add LV3 inherits Product');
run('$("f-name").value="FORM WORK";$("task-form").listeners.submit[0]({preventDefault(){}})');check(run('state.tasks.some(t=>t.name==="FORM WORK"&&t.parentId==="pj25-031-product-c04")'),'Editor creates LV3');
run('openTask("pj25-031-product-c04");$("f-product").value="C04A";$("task-form").listeners.submit[0]({preventDefault(){}})');check(run('drawingFieldsFor(state.tasks.find(t=>t.id==="pj25-031-c04-work-1")).product')==='C04A','Product rename propagates authoritative export fields');
const guard=fresh();guard.run('isEditor=true;openTask(null,null,"pj25-031-c02-work-1")');check(!guard.elements.get('task-dialog').open,'Direct fourth-level add blocked');
guard.run('openGroup();$("g-pjCode").value="PJ26-002";$("g-projectWorks").value="Project 2";$("group-form").onsubmit({preventDefault(){}})');check(guard.run('state.groups.some(g=>g.pjCode==="PJ26-002"&&isDatabaseGroup(g))'),'Editor creates LV1 from PJ/Works');
let nested=false;try{guard.run('saveGroupPlacement("pj25-031",{name:"test"},"group:mrt-purple-line-std-dwg-c1")')}catch{nested=true}check(nested,'Database LV1 cannot nest below legacy group');
check(guard.run('treeGuides(2,[true],true,false).includes("non-scaling-stroke")'),'SVG tree stroke method preserved');
const output=fresh().run('buildExcelWorkbook()'),bytes=Buffer.from(output.bytes),files={};let offset=0;while(bytes.readUInt32LE(offset)===0x04034b50){const n=bytes.readUInt16LE(offset+26),extra=bytes.readUInt16LE(offset+28),size=bytes.readUInt32LE(offset+18),start=offset+30+n+extra;files[bytes.toString('utf8',offset+30,offset+30+n)]=bytes.toString('utf8',start,start+size);offset=start+size}
const sheet=files['xl/worksheets/sheet1.xml'];check(output.recordCount===19&&output.days===28,'XLSX contains 19 work pairs');
check(sheet.includes('A1:AX42')&&sheet.includes('min="23" max="50"'),'XLSX calendar begins W and includes all 28 columns');
check((sheet.match(/<conditionalFormatting /g)||[]).length===38&&sheet.includes('WEEKDAY(W$3,2)&lt;&gt;7'),'Gantt phase bars exclude Sundays');
check(!sheet.includes('NaN')&&!sheet.includes('undefined'),'All XLSX cell styles valid');
check(files['xl/styles.xml'].includes('FFFFC000')&&files['xl/styles.xml'].includes('FF404040'),'Reference Excel colors retained');
check(run('CSV_VBA_TEXT')===fs.readFileSync(path.join(root,'Export_MasterSchedule_CSV.bas'),'utf8'),'Downloaded macro matches standalone file');
check(fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8')===html,'Tests never change saved HTML');
fs.mkdirSync(path.join(root,'outputs/database'),{recursive:true});fs.writeFileSync(path.join(root,'outputs/database/Master_Schedule_PJ25-031.csv'),csvText);fs.writeFileSync(path.join(root,'outputs/database/Master_Schedule_PJ25-031.xlsx'),bytes);
console.log(JSON.stringify({result:'PASS',checks,products:8,works:19,phaseRows:38,selectedFiles:14,browserQA:'Separate test',VBAexecution:'Not performed'},null,2));
