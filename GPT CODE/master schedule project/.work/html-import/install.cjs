const fs=require('fs'),assert=require('assert/strict'),vm=require('vm');
const file='Master_Schedule.html',before=fs.readFileSync(file,'utf8'),pattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/;
const data=JSON.parse(before.match(pattern)[1]),backup=fs.readFileSync('.work/html-import/backup-path.txt','utf8');
assert.equal(before,fs.readFileSync(backup+'/'+file,'utf8'),'File changed after backup; read latest data and back up again');
let h=before;function once(a,b){assert.equal(h.split(a).length,2,'Patch not unique: '+a.slice(0,100));h=h.replace(a,()=>b)}
// Recover only prior view features, never the schedule data in older backups.
if(!h.includes('id="tree-level-1"')){
 const prior=fs.readFileSync('.work/level-controls.cjs','utf8'),start=prior.indexOf('let h=before;'),end=prior.indexOf('assert.equal(h.match(pattern)');
 const patch=prior.slice(start,end)+'\nh;';h=vm.runInNewContext(patch,{before:h,assert});
}
if(!h.includes('id="full-width-layout"'))once('</head>','<style id="full-width-layout">@media screen{main{max-width:none;width:100%;margin:0;padding:24px 0 32px}}</style>\n</head>');
once('<button id="download">↓ บันทึกสำเนา HTML</button>','<button id="download" type="button" title="ดาวน์โหลดโปรแกรมรุ่นนี้พร้อมข้อมูลปัจจุบันเป็นไฟล์ใหม่">Export HTML</button><button id="import-html" type="button" data-editor-only="">Import HTML</button>');
const dialog=`<dialog id="html-import-dialog" aria-labelledby="html-import-title">
<div class="dialog-header"><strong id="html-import-title">Import ข้อมูลจาก HTML</strong><button type="button" data-close="html-import-dialog" aria-label="ปิด">×</button></div>
<div class="form-body">
<p class="calendar-note field full">นำเข้าเฉพาะข้อมูลงาน วันที่ สี และรายการไฟล์ โปรแกรมรุ่นปัจจุบันยังคงอยู่ เหมาะสำหรับย้ายข้อมูลจากสำเนาหรือหน้ารุ่นเก่า ไม่เปิดหรือรันโปรแกรมในไฟล์ที่เลือก</p>
<label class="field full">เลือก Master Schedule HTML<input id="html-import-file" type="file" accept=".html,.htm,text/html"></label>
<label class="field full">วิธีนำเข้า<select id="html-import-mode"><option value="merge">ผสานตามรหัส — เก็บรายการและลำดับเดิม เพิ่มงานใหม่ต่อท้าย</option><option value="replace">แทนที่ข้อมูลทั้งหมด — ใช้รายการและลำดับจากไฟล์</option></select></label>
<small class="field full">รหัสเดียวกันใช้ค่าที่มีในไฟล์นำเข้า รวมค่าว่างและการเลือกไฟล์ หากไฟล์เก่ามีค่าที่ยังต้องเก็บ ให้ตรวจค่าก่อน → หลังทุกครั้ง ต่างรหัสถือเป็นคนละรายการ ไม่จับคู่จากชื่อ ส่วนไฟล์แนบนำเข้าเฉพาะรายการและที่อยู่ ไม่รวมเนื้อหาเอกสาร</small>
<label class="field full csv-check" id="html-import-replace-field" hidden><input type="checkbox" id="html-import-replace-ok">ยืนยันใช้ข้อมูลทั้งชุดจากไฟล์ รวมการลบรายการที่ไม่มีในไฟล์</label>
<p class="calendar-note field full" id="html-import-summary" role="status" aria-live="polite"></p><p class="error field full" id="html-import-errors" role="alert"></p>
<div class="csv-preview field full"><table class="csv-preview-table"><thead><tr><th>ผล</th><th>หัวข้อ / รหัส</th><th>ข้อมูลที่จะเปลี่ยน</th></tr></thead><tbody id="html-import-preview"></tbody></table></div>
<div class="field full html-import-pages"><button type="button" id="html-import-prev">ก่อนหน้า</button><span id="html-import-page"></span><button type="button" id="html-import-next">ถัดไป</button></div>
<small class="field full">ยังไม่เปลี่ยนข้อมูลจนกดยืนยัน หลังนำเข้าจะหยุด Auto-save และยกเลิกปลายทางบันทึกเดิม ให้กด Export HTML เก็บเป็นไฟล์ใหม่</small>
</div><div class="dialog-footer"><button type="button" id="html-import-backup">Export HTML ก่อนนำเข้า</button><button type="button" data-close="html-import-dialog">ยกเลิก</button><button type="button" id="html-import-recheck">ตรวจข้อมูลอีกครั้ง</button><button type="button" class="primary" id="html-import-confirm" disabled>ยืนยันนำเข้า</button></div></dialog>\n`;
once('<dialog id="csv-import-dialog"',dialog+'<dialog id="csv-import-dialog"');
once('</head>','<meta name="master-schedule-build" content="rev04-html-io-20261113">\n<style id="html-import-style">#html-import-dialog{width:min(1100px,96vw)}#html-import-dialog pre{white-space:pre-wrap;overflow-wrap:anywhere;max-height:260px;overflow:auto;font-size:12px}#html-import-dialog .dialog-footer{flex-wrap:wrap}.html-import-pages{display:flex;align-items:center;justify-content:flex-end;gap:12px}</style>\n</head>');
once('clearCSVImport();cancelOrderMove();isEditor=false;','clearCSVImport();clearHTMLImport();cancelOrderMove();isEditor=false;');
once("['csv-import-dialog','file-dialog'","['html-import-dialog','csv-import-dialog','file-dialog'");
once("function filename(){return 'Master_Schedule_Rev04_'+state.project.reportDate+'.html'}","function filename(){return 'Master_Schedule_Rev04_'+new Date().toISOString().replace(/[-:]/g,'').replace(/\\.\\d{3}Z$/,'Z').replace('T','_')+'.html'}");
once("doc.title=copy.project.name+' · Master Schedule · Rev03'","doc.title=copy.project.name+' · Master Schedule · Rev04'");
once('const version=revision,snap=snapshot(),stream=await fileHandle.createWritable();','await checkHTMLSaveTarget(fileHandle);\n  const version=revision,snap=snapshot(),stream=await fileHandle.createWritable();');
once('savedRevision=version;dirty=revision!==savedRevision;state.savedAt=snap.data.savedAt;','htmlSaveExpectedData=JSON.stringify(snap.data);savedRevision=version;dirty=revision!==savedRevision;state.savedAt=snap.data.savedAt;');
// The existing Connect action must run the same checks as Save and never parse source HTML as a document.
once("file=await handle.getFile(),doc=new DOMParser().parseFromString(await file.text(),'text/html'),node=doc.getElementById('schedule-data'),data=node?JSON.parse(node.textContent):null;","file=await handle.getFile(),data=JSON.parse(htmlDataBlock(await file.text()));");
once('if(!isEditor)return;fileHandle=handle;dirty=true;saveStatus();','if(!isEditor)return;await checkHTMLSaveTarget(handle);fileHandle=handle;dirty=true;saveStatus();');
// Insert before initial render; all staging remains in memory and is absent from snapshot state.
once('render();saveStatus();\n',fs.readFileSync('.work/html-import/html-io.js','utf8')+'\nrender();saveStatus();\n');
assert.equal(h.match(pattern)[1],before.match(pattern)[1],'Must preserve latest data byte for byte');
for(const s of h.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g))if(!s[1].includes('application/json'))new vm.Script(s[2]);
fs.writeFileSync(file,h);console.log(JSON.stringify({backup,groups:data.groups.length,tasks:data.tasks.length,installed:true}));
