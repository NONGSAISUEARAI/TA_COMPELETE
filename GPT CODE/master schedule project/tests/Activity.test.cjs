const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path'),vm=require('node:vm');
const {boot,dataPattern}=require('./helpers/schedule-harness.cjs');
const root=path.join(__dirname,'..'),html=fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8'),data=JSON.parse(html.match(dataPattern)[1]);
let checks=0;const check=(v,m)=>{assert(v,m);checks++},fresh=()=>{const b=boot(html);b.context.TextDecoder=TextDecoder;return b};
const app=fresh(),{run,elements,context}=app,project=data.groups.find(g=>g.databaseModel),product=data.tasks.find(t=>t.groupId===project.id&&!t.parentId&&t.nodeType==='section'),description=data.tasks.find(t=>t.parentId===product.id&&t.nodeType==='task');
context.projectID=project.id;context.productID=product.id;context.descID=description.id;
const original=run('JSON.stringify(state)'),leafCount=run('leafTasks().length'),exportCount=run('excelExportRecords().length');
assert.deepEqual(JSON.parse(run('JSON.stringify(state.tasks)')),data.tasks);checks++;
check(new Set([...data.groups,...data.tasks].map(t=>t.id)).size===data.groups.length+data.tasks.length,'Existing IDs unique');
check(run('taskPaths().size')===data.tasks.length,'All existing tasks reachable');
check(!run('isEditor')&&run('drawingCoreHidden'),'Viewer and hidden core columns unchanged');
check(run('databaseLevel(state.groups.find(g=>g.id===projectID))')===1&&run('databaseLevel(state.tasks.find(t=>t.id===productID))')===2&&run('databaseLevel(state.tasks.find(t=>t.id===descID))')===3,'Existing levels inferred without migrating records');
check(run('excelExportRecords().length')===leafCount,'Existing leaf exports counted once');
check(elements.get('tasks').innerHTML.includes('data-add-task-child="'+description.id+'"'),'Description gets add Activity button');
run('openTask(null,null,descID)');check(run('JSON.stringify(state)')===original&&!elements.get('task-dialog').open,'Viewer cannot add Activity');
run('isEditor=true;Object.assign(state.tasks.find(t=>t.id===descID),{start:"2026-11-02",end:"2026-11-07",progress:60,actualStart:"2026-11-03",actualEnd:"2026-11-05",dateMode:"auto",actualDateMode:"auto"});openTask(null,null,descID)');
check(elements.get('f-db-level').value==='activity'&&elements.get('dialog-title').textContent.includes('LV4'),'Description child opens Activity dialog');
check(elements.get('f-name-label').textContent.startsWith('Activity')&&elements.get('f-description').value===description.name,'Activity name and read-only parent Description');
check(elements.get('f-product').value===product.product&&elements.get('f-product').readOnly&&elements.get('f-pjCode').readOnly,'Activity inherits project/product');
check(elements.get('f-owner').value===''&&elements.get('f-start').value===''&&elements.get('f-progress').value==='','Activity does not invent dates, owner or progress');
run('renderDatabaseParentPicker()');check(elements.get('parent-options').innerHTML.includes('data-parent-pick="'+description.id+'"')&&elements.get('parent-options').innerHTML.includes('parent-option-context'),'Activity picker shows Description under Product context');
run('$("f-name").value="จัดทำแบบ";$("task-form").listeners.submit[0]({preventDefault(){}});var activityID=state.tasks.at(-1).id');
check(elements.get('task-error').textContent==='','Activity form submits');
check(run('databaseLevel(state.tasks.find(t=>t.id===activityID))')===4&&run('state.tasks.find(t=>t.id===activityID).parentId')===description.id,'New Activity has its own ID under Description');
check(run('taskPaths().get(activityID).split(".").length')===4,'Four-level WBS');
check(run('state.tasks.find(t=>t.id===descID).dateMode')==='manual'&&run('summarizeTask(state.tasks.find(t=>t.id===descID)).start')==='2026-11-02','First Activity preserves existing parent Plan');
check(run('state.tasks.find(t=>t.id===descID).actualDateMode')==='manual'&&run('summarizeTask(state.tasks.find(t=>t.id===descID)).actualEnd')==='2026-11-05','First Activity preserves existing parent Actual');
check(run('summarizeTask(state.tasks.find(t=>t.id===descID)).progress')===null&&run('leafTasks().length')===leafCount,'Parent progress summarizes unknown Activity without double counting');
check(!elements.get('tasks').innerHTML.match(new RegExp('data-task="'+run('activityID')+'"[\\s\\S]*?</tr>'))[0].includes('data-add-task-child'),'Activity has no fifth-level button');
run('$("task-dialog").close();openTask(null,null,activityID)');check(!elements.get('task-dialog').open,'Fifth level blocked directly');
run('openTask(descID)');check(elements.get('f-progress').readOnly&&!elements.get('date-plan-controls').hidden,'Description with children summarizes % and allows manual Plan');
check(!elements.get('f-actual-controls').hidden,'Description exposes Actual summary controls');
run('useChildDates();useActualChildren("f");$("task-form").listeners.submit[0]({preventDefault(){}})');
check(run('state.tasks.find(t=>t.id===descID).dateMode')==='auto'&&run('state.tasks.find(t=>t.id===descID).actualDateMode')==='auto','Parent can return to automatic dates independently');
run('Object.assign(state.tasks.find(t=>t.id===activityID),{start:"2026-11-02",end:"2026-11-03",actualStart:"2026-11-03",actualEnd:"2026-11-04",progress:50});openTask(null,null,descID);$("f-name").value="ตรวจทานแบบ";$("task-form").listeners.submit[0]({preventDefault(){}});var secondID=state.tasks.at(-1).id;Object.assign(state.tasks.find(t=>t.id===secondID),{start:"2026-11-04",end:"2026-11-07",actualStart:"2026-11-05",actualEnd:"2026-11-06",progress:100});render()');
check(run('summarizeTask(state.tasks.find(t=>t.id===descID)).progress')===83,'Parent progress weighted 2 and 4 working days');
check(run('summarizeTask(state.tasks.find(t=>t.id===descID)).start')==='2026-11-02'&&run('summarizeTask(state.tasks.find(t=>t.id===descID)).actualEnd')==='2026-11-06','Automatic Plan/Actual aggregate correctly');
check(run('leafTasks().length')===leafCount+1&&run('excelExportRecords().length')===exportCount+1,'Two Activities replace one Description in totals/exports');
run('openTask(descID);$("f-start").value="2026-12-01";$("f-end").value="2026-12-05";$("task-form").listeners.submit[0]({preventDefault(){}})');
check(run('state.tasks.find(t=>t.id===activityID).start')==='2026-11-02'&&run('summarizeTask(state.tasks.find(t=>t.id===descID)).start')==='2026-12-01','Editing parent manual dates does not change Activity dates');
assert.throws(()=>run('inlineUpdate("task",descID,"progress","40")'),/งานย่อย/);checks++;
run('inlineUpdate("task",activityID,"progress","0")');check(run('state.tasks.find(t=>t.id===activityID).progress')===0,'Activity inline editing retains explicit zero');
run('openTask(activityID);$("f-name").value="จัดทำแบบฉบับแก้";$("task-form").listeners.submit[0]({preventDefault(){}})');check(run('state.tasks.find(t=>t.id===activityID).name')==='จัดทำแบบฉบับแก้','Activity edit preserves ID');
run('var currentCSV=makeScheduleCSV();var parsed=readScheduleCSV(currentCSV);var plan=buildCSVImportPlan(parsed)');
check(run('plan.issues.length')===0&&run('plan.changedCount')===0,'Activity CSV no-change round trip');
check(run('parsed.records.filter(r=>r.isActivity).length')===2,'CSV has separate Activity records');
check(run('parsed.records.find(r=>r.taskId===activityID).plan[4]')===description.name&&run('parsed.records.find(r=>r.taskId===activityID).activity')==='จัดทำแบบฉบับแก้','CSV E stays Description, W holds Activity');
check(run('parsed.records.find(r=>r.taskId===activityID).descriptionId')===description.id&&run('parsed.records.find(r=>r.taskId===activityID).productId')===product.id,'CSV stores both Product ID and Description ID');
const moved=boot(run('snapshot().html'));moved.context.descID=description.id;moved.context.aid=run('activityID');moved.run('isEditor=true;var targetProduct=state.tasks.find(t=>databaseLevel(t)===2&&t.groupId===state.tasks.find(d=>d.id===descID).groupId&&t.id!==state.tasks.find(d=>d.id===descID).parentId);openTask(descID);chooseParent(targetProduct.id);$("task-form").listeners.submit[0]({preventDefault(){}})');
check(moved.run('state.tasks.find(t=>t.id===descID).parentId===targetProduct.id')&&moved.run('drawingFieldsFor(state.tasks.find(t=>t.id===aid)).product===targetProduct.product'),'Moving Description carries Activities to new Product');
check(moved.run('state.tasks.find(t=>t.id===aid).area===targetProduct.product'),'Inherited Activity area follows moved Description');
check(moved.run('JSON.stringify(state.tasks.filter(t=>t.fileCatalog))')===run('JSON.stringify(state.tasks.filter(t=>t.fileCatalog))'),'Moving Description retains file catalogs');
const toCSV=rows=>'\ufeff'+rows.map(r=>r.map(v=>'"'+String(v??'').replace(/"/g,'""')+'"').join(',')).join('\r\n')+'\r\n';
const rows=JSON.parse(run('JSON.stringify(parseCSVRecords(currentCSV.replace(/^\\ufeff/,"")).map(r=>r.map(csvUnescape)))')),aid=run('activityID'),actRows=rows.filter(r=>r[19]===aid);
const edited=structuredClone(rows);for(const r of edited.filter(r=>r[19]===aid))r[22]='แก้ชื่อผ่าน CSV';edited.find(r=>r[19]===aid&&r[17]==='Actual')[11]='2026-11-08';edited.find(r=>r[19]===aid&&r[17]==='Actual')[12]='2026-11-12';context.editedCSV=toCSV(edited);
run('var editedPlan=buildCSVImportPlan(readScheduleCSV(editedCSV))');check(run('editedPlan.issues.length')===0&&run('editedPlan.changedCount')===1,'CSV updates Activity by stable ID');
check(run('editedPlan.next.tasks.find(t=>t.id===activityID).actualStart')==='2026-11-09','Imported Activity Sunday moves to Monday');
// Valid Actual range stays independent of the existing Plan.
if(run('editedPlan.issues.length'))throw Error(run('JSON.stringify(editedPlan.issues)'));
for(const [label,mutate] of [
 ['wrong Description ID',r=>{for(const x of r.filter(x=>x[19]===aid))x[23]='wrong-id'}],
 ['wrong Description',r=>{for(const x of r.filter(x=>x[19]===aid))x[4]='Wrong Description'}],
 ['mismatched pair Activity',r=>{r.find(x=>x[19]===aid&&x[17]==='Actual')[22]='Wrong Activity'}],
 ['reversed Actual dates',r=>{r.find(x=>x[19]===aid&&x[17]==='Actual')[11]='2026-12-01'}],
 ['Activity turned into Description',r=>{for(const x of r.filter(x=>x[19]===aid)){x[22]='';x[23]='';x[18]='Task'}}]
]){const bad=structuredClone(rows);mutate(bad);context.badCSV=toCSV(bad);let rejected=false;try{rejected=run('buildCSVImportPlan(readScheduleCSV(badCSV)).issues.length')>0}catch{rejected=true}check(rejected,'Reject '+label)}
const newRows=[rows[0],...structuredClone(actRows)];for(const r of newRows.slice(1)){r[16]='';r[19]='';r[22]='ขั้นตอนใหม่จาก CSV';r[11]=r[12]=''}context.newCSV=toCSV(newRows);run('var newPlan=buildCSVImportPlan(readScheduleCSV(newCSV))');
check(run('newPlan.issues.length')===0&&run('newPlan.createdCount')===1,'New Activity supports blank Task ID/WBS');
check(run('newPlan.next.tasks.at(-1).parentId')===description.id&&run('newPlan.next.tasks.filter(t=>t.parentId===productID&&t.name==='+JSON.stringify(description.name)+').length')===1,'Import reuses correct Description instead of duplicating it');
const legacy=fresh();legacy.context.input=legacy.run('makeScheduleCSV()');const legacyRows=JSON.parse(legacy.run('JSON.stringify(parseCSVRecords(input.replace(/^\\ufeff/,"")).map(r=>r.map(csvUnescape)))')).map(r=>r.slice(0,22));legacy.context.input=toCSV(legacyRows);check(legacy.run('buildCSVImportPlan(readScheduleCSV(input)).issues.length')===0&&legacy.run('buildCSVImportPlan(readScheduleCSV(input)).changedCount')===0,'Old 22-column CSV remains supported for Description-only records');
run('var snap=snapshot().html');const reopened=boot(run('snap'));check(reopened.run('databaseLevel(state.tasks.find(t=>t.id==='+JSON.stringify(aid)+'))')===4&&!reopened.run('isEditor'),'Activity snapshot reopens in Viewer');
check(reopened.run('state.tasks.find(t=>t.id==='+JSON.stringify(description.id)+').dateMode')==='manual','Parent manual dates persist');
assert.deepEqual(JSON.parse(run('JSON.stringify(state.tasks.filter(t=>t.fileCatalog))')),data.tasks.filter(t=>t.fileCatalog));checks++;
const workbook=run('buildExcelWorkbook({calendar:true,start:"2026-11-02",end:"2026-11-29"})'),bytes=Buffer.from(workbook.bytes),files={};let off=0;while(bytes.readUInt32LE(off)===0x04034b50){const n=bytes.readUInt16LE(off+26),extra=bytes.readUInt16LE(off+28),size=bytes.readUInt32LE(off+18),start=off+30+n+extra;files[bytes.toString('utf8',off+30,off+30+n)]=bytes.toString('utf8',start,start+size);off=start+size}
const sheet=files['xl/worksheets/sheet1.xml'];check(sheet.includes('r="W4"')&&sheet.includes('>Activity<')&&sheet.includes('>Description ID<'),'XLSX includes appended Activity metadata');
check(sheet.includes('min="25" max="52"')&&sheet.includes('Y$3'),'Calendar starts Y after 24 metadata columns');
check(sheet.includes('r="Y3"')&&!sheet.includes('undefined')&&!sheet.includes('NaN'),'XLSX calendar and styles valid');
check(sheet.includes('จัดทำแบบฉบับแก้')&&sheet.includes(description.id),'XLSX contains Activity and parent ID');
check(workbook.recordCount===exportCount+1,'XLSX exports leaves only');
check((sheet.match(/<conditionalFormatting /g)||[]).length===workbook.recordCount*2,'Plan and Actual Gantt for every leaf');
check(files['xl/styles.xml'].includes('FFFFC000')&&files['xl/styles.xml'].includes('FF404040'),'Existing reference palette retained');
check(run('treeGuides(3,[true,false],true,false).includes("non-scaling-stroke")'),'Existing SVG tree method supports LV4');
const ids=run('JSON.stringify([activityID,secondID])');run('state.tasks=state.tasks.filter(t=>![activityID,secondID].includes(t.id))');check(run('summarizeTask(state.tasks.find(t=>t.id===descID)).start')==='2026-12-01','Description without Activities retains manually edited plan');
check(fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8')===html,'Tests never modify saved user data');
fs.mkdirSync(path.join(root,'outputs/lv4-validation'),{recursive:true});fs.writeFileSync(path.join(root,'outputs/lv4-validation/synthetic-activities.xlsx'),bytes);fs.writeFileSync(path.join(root,'outputs/lv4-validation/synthetic-activities.csv'),context.currentCSV||app.run('currentCSV'));fs.writeFileSync(path.join(root,'outputs/lv4-validation/expected.json'),JSON.stringify({recordCount:workbook.recordCount,activityIDs:JSON.parse(ids),descriptionID:description.id,description:description.name},null,2));
console.log(JSON.stringify({result:'PASS',checks,userGroups:data.groups.length,userTasks:data.tasks.length,baselineWorks:leafCount,syntheticActivities:2,scope:'LV4 forms/parents, dates/summary/inline editing, stable IDs, CSV old/new roundtrip and parent checks, XLSX metadata/styles/calendar, snapshots, no data changes',browserQA:'Separate test'},null,2));
