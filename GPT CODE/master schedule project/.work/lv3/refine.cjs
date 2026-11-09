const fs=require('node:fs'),assert=require('node:assert/strict'),vm=require('node:vm');
let h=fs.readFileSync('Master_Schedule.html','utf8');JSON.parse(h.match(/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/)[1]);
function patch(a,b){assert(h.includes(a),'Missing '+a.slice(0,80));h=h.replace(a,()=>b)}
patch("max=\"'+(18+days)+'\"", "max=\"'+(22+days)+'\"");
patch("if(parentId&&isDatabaseGroup(state.groups.find(g=>g.id===groupId))", "if(parentId&&isDatabaseGroup(databaseGroup(state.tasks.find(t=>t.id===parentId)||{}))");
patch("const target=groupParentDestination(targetKey,sourceId);if(!String(values.name", "const target=groupParentDestination(targetKey,sourceId);if(target&&(isDatabaseGroup(source)||isDatabaseGroup(values)||isDatabaseGroup(target.group)))throw Error('โครงการฐานข้อมูลใช้ LV1 / LV2 / LV3 เท่านั้น');if(!String(values.name");
patch("const current=editingId?state.tasks.find(t=>t.id===editingId):null,level=current?", "const current=editingId?state.tasks.find(t=>t.id===editingId):null;if(current&&!isDatabaseGroup(databaseGroup(current)))throw Error('ย้ายงานเอกสารเดิมเข้าโครงการฐานข้อมูลไม่ได้ ให้เพิ่ม Product หรืองานใหม่');const level=current?");
// Keep existing database records in a project/product tree when changing groups.
patch("if(!isDatabaseGroup(group))return;const current=editingId?", "if(!isDatabaseGroup(group)){if(editingId&&isDatabaseGroup(databaseGroup(state.tasks.find(t=>t.id===editingId)||{})))throw Error('เลือกโครงการแบบ LV1 / LV2 / LV3 สำหรับงานนี้');return}const current=editingId?");
patch("r.transientCode=transientCodes.has(r.code)}", "r.transientCode=transientCodes.has(r.code);if(r.actual)for(const c of [0,1,2,3,19,20,21])if(csvName(r.actual[c])!==csvName(r.plan[c]))throw Error('WBS '+r.code+': ข้อมูลโครงการ / Product / รหัสงานของ Plan และ Actual ไม่ตรงกัน')}");
patch('ใช้ CSV UTF-8 ที่มีตำแหน่ง A–P ตามตัวอย่าง, Q = WBS และ R = Plan / Actual กรอกข้อมูลทั่วไปที่แถว Plan ส่วนแถว Actual อ่านเฉพาะวันเริ่ม–จบ ชื่อและ WBS ใช้จับคู่งานเดิม ไม่เปลี่ยนต้นไม้ในโหมดอัปเดต','ฐานข้อมูลงาน LV3: กรอก PJ, Project Works, Group Drawing, Product และ Description ครบทุกแถว แยก Plan / Actual คนละบรรทัด ใช้ Task ID จับคู่งานเดิมแม้ย้ายลำดับหรือแก้ Description เพิ่มงานใหม่โดยเว้น Task ID และ WBS ข้อมูลทั่วไปอ่านจาก Plan ส่วน Actual อ่านวันเริ่ม–จบ');
patch('<tr><td>S</td><td>Node Type (ชนิดรายการ)</td></tr>', '<tr><td>S</td><td>Node Type = Task</td></tr><tr><td>T</td><td>Task ID (รหัสงานถาวร)</td></tr><tr><td>U</td><td>Project ID</td></tr><tr><td>V</td><td>Product ID</td></tr>');
patch('A–P เหมือนตัวอย่าง · Q/R จำเป็น · S ชนิดรายการเป็นตัวช่วยรักษาหัวข้อที่ยังไม่มีลูก · P Duration คำนวณจากวันที่','A–P ตามตัวอย่าง · Q WBS ใช้แสดงลำดับ · R Plan / Actual · S–V รหัสอ้างอิง งานใหม่เว้น Q/T ได้ หากเพิ่มโครงการหรือ Product ใหม่ให้เว้น U/V ด้วย · P Duration คำนวณจากวันที่');
patch('VBA อ่านชีต Programm Database แถวหัวตาราง 4 และสร้าง WBS จากการเยื้อง Description โดยไม่บันทึกทับไฟล์ Excel เดิม','VBA อ่านชีต Programm Database แถวหัวตาราง 4 เก็บรหัสงานจากไฟล์ที่ส่งออก หากเป็นฐานข้อมูลใหม่ให้กรอก A–E ครบทุกแถว โดยไม่บันทึกทับ Excel เดิม');
// Make the macro preserve database IDs and avoid generating project/indent rows
// for a fully populated, flat source database. Legacy sparse sheets still work.
let v=fs.readFileSync('Export_MasterSchedule_CSV.bas','utf8');
const vp=(a,b)=>{assert(v.includes(a),'VBA missing '+a);v=v.replace(a,()=>b)};
vp('hasWBS As Boolean','hasWBS As Boolean, databaseRow As Boolean, dbCounter As Long');
vp('"Node Type")','"Node Type", "Task ID", "Project ID", "Product ID")');
v=v.replaceAll('ReDim values(0 To 18)','ReDim values(0 To 21)').replaceAll('ReDim projectValues(0 To 18)','ReDim projectValues(0 To 21)');
vp('            values(4) = description','            databaseRow = True\n            For c = 0 To 4\n                If Len(Trim$(CStr(values(c)))) = 0 Then databaseRow = False\n            Next c\n            For c = 19 To 22\n                If MSCHeader(CStr(ws.Cells(4, c).Value2)) = MSCHeader(CStr(headers(c - 1))) Then\n                    If IsError(ws.Cells(r, c).Value2) Then Err.Raise vbObjectError + 118, , "Invalid metadata at row " & r\n                    values(c - 1) = CStr(ws.Cells(r, c).Value2)\n                End If\n            Next c\n            values(4) = description');
vp('            Else\n                newProject =', '            ElseIf databaseRow Then\n                dbCounter = dbCounter + 1\n                code = CStr(1000000 + dbCounter)\n                track = "Plan"\n                values(18) = "Task"\n            Else\n                newProject =');
vp('        If InStr(code, ".") = 0 Then','        If Len(CStr(item(18))) > 0 Then\n            If LCase$(CStr(item(18))) <> "group" And LCase$(CStr(item(18))) <> "section" And LCase$(CStr(item(18))) <> "task" Then Err.Raise vbObjectError + 119, , "Invalid Node Type for " & code\n        ElseIf Len(CStr(item(0))) > 0 And Len(CStr(item(1))) > 0 And Len(CStr(item(2))) > 0 And Len(CStr(item(3))) > 0 Then\n            item(18) = "Task"\n        ElseIf InStr(code, ".") = 0 Then');
fs.writeFileSync('Export_MasterSchedule_CSV.bas',v);
h=h.replace(/const CSV_VBA_TEXT=[\s\S]*?;\nfunction csvDownload/,()=> 'const CSV_VBA_TEXT='+JSON.stringify(v).replace(/</g,'\\u003c')+';\nfunction csvDownload');
assert(h.includes(JSON.stringify(v).slice(0,100)),'embedded VBA');
for(const m of h.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g))if(!m[1].includes('application/json'))new vm.Script(m[2]);
fs.writeFileSync('Master_Schedule.html',h);
// Previous tests are explicit legacy fixtures, using current application code.
for(const file of ['tests/CSVImport.test.cjs','tests/Recovery.test.cjs']){
 let t=fs.readFileSync(file,'utf8');
 if(file.includes('CSVImport')){
  t=t.replace("const root=path.join(__dirname,'..'),html=fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8');", "const root=path.join(__dirname,'..'),savedHTML=fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8'),html=savedHTML.replace(dataPattern,()=>'<script id=\"schedule-data\" type=\"application/json\">'+fs.readFileSync(path.join(__dirname,'fixtures/before-lv3-database.json'),'utf8')+'</script>');");
  t=t.replace("check(actual===html,", "check(actual===savedHTML,");
  t=t.replace(/ fs.mkdirSync\(path.join\(root,'outputs','csv-import'\)[\s\S]*?fresh\(\).run\('makeScheduleCSV\("pj25-031"\)'\),'utf8'\);/, '');
 }else{
  t=t.replace("html=fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8'),data=", "savedHTML=fs.readFileSync(path.join(root,'Master_Schedule.html'),'utf8'),html=savedHTML.replace(dataPattern,()=>'<script id=\"schedule-data\" type=\"application/json\">'+fs.readFileSync(path.join(__dirname,'fixtures/before-lv3-database.json'),'utf8')+'</script>'),data=");
  t=t.replace('assert.equal(saved,html);','assert.equal(saved,savedHTML);').replace(/fs.writeFileSync\(path.join\(root,'backups',audit,'Export_validation.xlsx'\),bytes\);/,'');
 }
 fs.writeFileSync(file,t);
}
console.log('Refined database forms, CSV IDs, XLSX layout, VBA and legacy test fixtures');
