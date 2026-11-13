// Import reads JSON only; source markup and JavaScript are never attached or executed.
const HTML_IMPORT_LIMIT=20*1024*1024,HTML_IMPORT_NODES=20000;
let htmlImportSource=null,htmlImportPlan=null,htmlImportGeneration=0,htmlImportPage=0;
let htmlSaveExpectedData=JSON.stringify(JSON.parse($('schedule-data').textContent));
function htmlDataBlock(text){
 const blocks=[];
 for(const match of text.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi)){
  const attrs={};for(const a of match[1].matchAll(/([^\s=<>"']+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/g))attrs[a[1].toLowerCase()]=a[2]??a[3]??a[4];
  if(attrs.id==='schedule-data'&&String(attrs.type).toLowerCase()==='application/json')blocks.push(match[2]);
 }
 if(blocks.length!==1)throw Error('ต้องมี schedule-data ชนิด application/json เพียงหนึ่งชุด');
 return blocks[0];
}
function htmlProgramSignature(text){
 const parts=[];for(const m of text.matchAll(/<(script|style)\b([^>]*)>([\s\S]*?)<\/\1\s*>/gi)){
  if(m[1].toLowerCase()==='script'&&/\bid\s*=\s*["']schedule-data["']/i.test(m[2]))continue;
  parts.push(m[1].toLowerCase()+m[3].replace(/\r\n/g,'\n'));
 }return parts.join('\n');
}
async function checkHTMLSaveTarget(handle){
 const file=await handle.getFile();if(!file.size)return;
 if(file.size>HTML_IMPORT_LIMIT)throw Error('ปลายทางมีขนาดเกินกำหนด กรุณา Export HTML เป็นไฟล์ใหม่');
 const text=await file.text();let target;try{target=JSON.parse(htmlDataBlock(text));if(target.app!==state.app||target.projectId!==state.projectId)throw Error()}catch{throw Error('ปลายทางไม่ใช่ Master Schedule ของชุดนี้ กรุณา Export HTML เป็นไฟล์ใหม่')}
 if(htmlProgramSignature(text)!==htmlProgramSignature(initialHTML))throw Error('ปลายทางใช้โปรแกรมคนละรุ่น หยุดการเซฟทับแล้ว: ให้ Export HTML แยกชื่อ แล้ว Import ข้อมูลเข้าไฟล์รุ่นล่าสุด');
 if(JSON.stringify(target)!==htmlSaveExpectedData)throw Error('ข้อมูลปลายทางเปลี่ยนจากตอนเปิดหน้า หยุดการเซฟทับแล้ว: ให้ Export HTML แยกชื่อ แล้ว Import เพื่อผสานข้อมูล');
}
function htmlJSONClone(value){return JSON.parse(JSON.stringify(value))}
function validateHTMLSchedule(data){
 const fail=message=>{throw Error(message)},object=v=>v!==null&&typeof v==='object'&&!Array.isArray(v);
 if(!object(data)||data.app!=='ppline-master-schedule-v1')fail('ไม่ใช่ข้อมูล Master Schedule ที่รองรับ');
 if(data.schemaVersion!==undefined&&(!Number.isInteger(data.schemaVersion)||data.schemaVersion<1||data.schemaVersion>3))fail('รุ่นโครงสร้างข้อมูลยังไม่รองรับ');
 // Refuse unsafe keys even in optional metadata before using object spreads.
 const stack=[data];while(stack.length){const value=stack.pop();if(!value||typeof value!=='object')continue;for(const key of Object.keys(value)){if(['__proto__','prototype','constructor','sessionToken','accessToken','helperToken','fileHandle','fileDirectoryHandle'].includes(key))fail('พบชื่อช่องข้อมูลที่ไม่อนุญาต');if(value[key]&&typeof value[key]==='object')stack.push(value[key])}}
 if(!object(data.project)||typeof data.project.name!=='string'||!data.project.name.trim())fail('ชื่อโครงการส่วนหัวไม่ครบ');
 const date=(v,label)=>{if(v!==undefined&&v!==null&&v!==''&&(typeof v!=='string'||!v||!validRecordDate(v)))fail(label+' วันที่ไม่ถูกต้อง')};
 date(data.project.reportDate,'วันรายงาน');if(!data.project.reportDate)fail('ต้องระบุวันรายงาน');date(data.project.handover,'วันส่งมอบ');
 for(const key of ['name','description'])if(data.project[key]!==undefined&&typeof data.project[key]!=='string')fail('ส่วนหัว '+key+' ต้องเป็นข้อความ');
 if(!Array.isArray(data.groups)||!Array.isArray(data.tasks)||!data.groups.length)fail('ไม่พบรายการหมวดหลัก/งาน');
 if(data.groups.length+data.tasks.length>HTML_IMPORT_NODES)fail('จำนวนหัวข้อและงานรวมต้องไม่เกิน 20,000 รายการ');
 const ids=new Set(),groups=new Map(),tasks=new Map();let files=0;
 const record=(r,label)=>{
  if(!object(r)||typeof r.id!=='string'||!r.id.trim()||r.id.length>200||ids.has(r.id))fail(label+' รหัสว่าง/ซ้ำ/ยาวเกินกำหนด');ids.add(r.id);
  if(typeof r.name!=='string'||!r.name.trim()||r.name.length>2000)fail(label+' ชื่อว่างหรือยาวเกินกำหนด');
  for(const key of ['area','owner','note','pjCode','projectWorks','drawingGroup','product','category','currentInfo','unit','workStatus','action','remark'])if(r[key]!==undefined&&typeof r[key]!=='string')fail(label+' '+key+' ต้องเป็นข้อความ');
  for(const key of ['start','end','planStart','planEnd','actualStart','actualEnd','approvedDate'])date(r[key],label+' '+key);
  for(const [start,end]of [['start','end'],['planStart','planEnd'],['actualStart','actualEnd']])if(r[start]&&r[end]&&(r[end]<r[start]||dateNumber(r[end])-dateNumber(r[start])>DAY*366*10))fail(label+' '+start+'/'+end+' ช่วงวันผิดหรือเกิน 10 ปี');
  if(r.progress!==undefined&&r.progress!==null&&(!Number.isInteger(r.progress)||r.progress<0||r.progress>100))fail(label+' ผลงานต้องเป็นจำนวนเต็ม 0–100 หรือ null');
  if(r.quantity!==undefined&&r.quantity!==null&&(typeof r.quantity!=='number'||!Number.isFinite(r.quantity)||r.quantity<0))fail(label+' Quantity ไม่ถูกต้อง');
  if(r.barColor!==undefined&&r.barColor!==null&&(typeof r.barColor!=='string'||!/^#[0-9a-f]{6}$/i.test(r.barColor)))fail(label+' สีไม่ถูกต้อง');
  for(const key of ['dateMode','actualDateMode'])if(r[key]!==undefined&&!['auto','manual'].includes(r[key]))fail(label+' '+key+' ไม่ถูกต้อง');
  if(r.fileCatalog!==undefined&&r.fileCatalog!==null){
   const c=r.fileCatalog;if(!object(c)||!Array.isArray(c.files))fail(label+' รายการไฟล์ไม่ถูกต้อง');
   for(const key of ['rootName','address','scannedAt','warning'])if(c[key]!==undefined&&typeof c[key]!=='string')fail(label+' ข้อมูลโฟลเดอร์ไม่ถูกต้อง');
   if(c.source!==undefined&&!['local','picker'].includes(c.source))fail(label+' ที่มาของโฟลเดอร์ไม่ถูกต้อง');
   const paths=new Set();for(const f of c.files){files++;if(files>20000)fail('รายการไฟล์แนบรวมเกิน 20,000 ไฟล์');
    if(!object(f)||typeof f.name!=='string'||!f.name||typeof f.path!=='string'||!f.path||f.path.length>8000||/^(?:[\\/]|[a-z]:)/i.test(f.path)||/[\x00-\x1f]/.test(f.path)||f.path.split(/[\\/]/).some(p=>p==='..'||p==='.')||paths.has(f.path))fail(label+' ชื่อ/ที่อยู่ไฟล์ไม่ถูกต้องหรือซ้ำ');paths.add(f.path);
    if(f.selected!==undefined&&typeof f.selected!=='boolean')fail(label+' การเลือกไฟล์ต้องเป็น true/false');
    for(const key of ['size','modified'])if(f[key]!==undefined&&(typeof f[key]!=='number'||!Number.isFinite(f[key])||f[key]<0))fail(label+' '+key+' ของไฟล์ไม่ถูกต้อง');
   }
  }
 };
 data.groups.forEach((g,i)=>{record(g,'หมวด '+(i+1));if(g.databaseModel!==undefined&&g.databaseModel!=='project-product-work-v1')fail('รูปแบบหมวดหลักยังไม่รองรับ');if(g.databaseModel&&(!g.pjCode?.trim()||!g.projectWorks?.trim()))fail('หมวด '+g.id+' ต้องมี PJ และ Project Works');groups.set(g.id,g)});
 data.tasks.forEach((t,i)=>{record(t,'งาน '+(i+1));if(typeof t.groupId!=='string'||!groups.has(t.groupId))fail('งาน '+t.id+' ไม่พบหมวดหลัก');if(t.parentId!==null&&t.parentId!==undefined&&typeof t.parentId!=='string')fail('รหัสแม่ไม่ถูกต้อง: '+t.id);if(t.nodeType!==undefined&&!['task','section'].includes(t.nodeType))fail('ชนิดงานไม่ถูกต้อง: '+t.id);tasks.set(t.id,t)});
 // Iterative depth resolution catches cycles without recursion on untrusted trees.
 const depths=new Map();for(const t of data.tasks){let cursor=t;const chain=[],seen=new Set();while(cursor&&!depths.has(cursor.id)){
   if(seen.has(cursor.id))fail('หัวข้อวนกลับหาตัวเอง: '+t.id);seen.add(cursor.id);chain.push(cursor);
   if(!cursor.parentId){cursor=null;break}const parent=tasks.get(cursor.parentId);if(!parent||parent.groupId!==cursor.groupId)fail('ไม่พบหัวข้อแม่หรืออยู่คนละหมวด: '+cursor.id);cursor=parent;
  }let depth=cursor?depths.get(cursor.id):1;while(chain.length){if(++depth>128)fail('โครงสร้างลึกเกิน 128 ระดับ');depths.set(chain.pop().id,depth)}
 }
 for(const t of data.tasks)if(groups.get(t.groupId).databaseModel==='project-product-work-v1'){
  const level=depths.get(t.id);if(level>4||(level===2?t.nodeType!=='section':t.nodeType!=='task'))fail('โครงสร้าง LV2 Product / LV3 Description / LV4 Activity ไม่ถูกต้อง: '+t.id);
  if(level===2&&(!t.product?.trim()||!t.drawingGroup?.trim()))fail('หัวข้อ '+t.id+' ต้องมี Product และ Group Drawing');
 }
 if(data.primaryProjectId!==undefined&&data.primaryProjectId!==null&&!groups.has(data.primaryProjectId))fail('ไม่พบโครงการหลักที่อ้างอิง');
 return data;
}
function readHTMLSchedule(text){
 if(typeof text!=='string'||new TextEncoder().encode(text).length>HTML_IMPORT_LIMIT)throw Error('HTML ต้องมีขนาดไม่เกิน 20 MB');
 let data;try{data=JSON.parse(htmlDataBlock(text))}catch(error){throw Error('อ่านข้อมูล HTML ไม่สำเร็จ: '+error.message)}return validateHTMLSchedule(data);
}
const HTML_ROOT_KEYS=['project','groups','tasks','primaryProjectId','schemaVersion'];
function buildHTMLImportPlan(source,mode='merge'){
 if(!['merge','replace'].includes(mode))throw Error('วิธีนำเข้าไม่ถูกต้อง');validateHTMLSchedule(source);
 const next=htmlJSONClone(state),incoming=htmlJSONClone(source),changes=[];
 for(const key of HTML_ROOT_KEYS)if(Object.hasOwn(incoming,key)){
  if(mode==='merge'&&(key==='groups'||key==='tasks')){
   const byId=new Map(incoming[key].map(r=>[r.id,r]));next[key]=next[key].map(r=>byId.has(r.id)?{...r,...byId.get(r.id)}:r);
   const existing=new Set(next[key].map(r=>r.id));next[key].push(...incoming[key].filter(r=>!existing.has(r.id)));
  }else if(key==='project'&&mode==='merge')next.project={...next.project,...incoming.project};else next[key]=incoming[key];
 }
 // Preserve this app's container identity and draft key; only business data crosses files.
 next.app=state.app;next.projectId=state.projectId;validateHTMLSchedule(next);
 for(const [key,label]of [['project','ส่วนหัว'],['primaryProjectId','โครงการหลัก'],['schemaVersion','รุ่นข้อมูล']])if(JSON.stringify(state[key])!==JSON.stringify(next[key]))changes.push({kind:'แก้ไข',label,before:state[key],after:next[key]});
 for(const key of ['groups','tasks']){
  const before=new Map(state[key].map(r=>[r.id,r])),after=new Map(next[key].map(r=>[r.id,r]));
  for(const r of next[key])if(!before.has(r.id))changes.push({kind:'เพิ่ม',label:r.name+' · '+r.id,before:null,after:r});else{
   const a=before.get(r.id),fields=Object.keys({...a,...r}).filter(k=>JSON.stringify(a[k])!==JSON.stringify(r[k]));
   if(fields.length)changes.push({kind:'แก้ไข',label:r.name+' · '+r.id,before:Object.fromEntries(fields.map(k=>[k,a[k]??null])),after:Object.fromEntries(fields.map(k=>[k,r[k]??null]))});
  }
  for(const r of state[key])if(!after.has(r.id))changes.push({kind:'ลบ',label:r.name+' · '+r.id,before:r,after:null});
  const commonBefore=state[key].filter(r=>after.has(r.id)).map(r=>r.id),commonAfter=next[key].filter(r=>before.has(r.id)).map(r=>r.id);
  if(JSON.stringify(commonBefore)!==JSON.stringify(commonAfter))changes.push({kind:'ลำดับ',label:key==='groups'?'ลำดับหมวดหลัก':'ลำดับงาน',before:commonBefore,after:commonAfter});
 }
 return {next,changes,mode,revision,source:htmlJSONClone(source)};
}
function clearHTMLImport(){htmlImportGeneration++;htmlImportSource=null;htmlImportPlan=null;htmlImportPage=0}
function htmlImportCanConfirm(){return isEditor&&!saving&&htmlImportPlan&&htmlImportPlan.revision===revision&&htmlImportPlan.changes.length>0&&(htmlImportPlan.mode!=='replace'||$('html-import-replace-ok').checked)}
function renderHTMLImportPage(){
 const plan=htmlImportPlan,rows=plan?.changes||[],pages=Math.max(1,Math.ceil(rows.length/30));htmlImportPage=Math.max(0,Math.min(htmlImportPage,pages-1));
 const value=v=>escapeHTML(JSON.stringify(v,null,2)??'ไม่มี');
 $('html-import-preview').innerHTML=rows.slice(htmlImportPage*30,(htmlImportPage+1)*30).map(r=>'<tr><td>'+escapeHTML(r.kind)+'</td><td>'+escapeHTML(r.label)+'</td><td><details><summary>ดูค่าก่อน → หลัง</summary><pre>'+value(r.before)+'\n→\n'+value(r.after)+'</pre></details></td></tr>').join('');
 $('html-import-page').textContent='หน้า '+(htmlImportPage+1)+' / '+pages+' · '+rows.length+' การเปลี่ยนแปลง';$('html-import-prev').disabled=htmlImportPage===0;$('html-import-next').disabled=htmlImportPage>=pages-1;$('html-import-confirm').disabled=!htmlImportCanConfirm();
}
function refreshHTMLImport(){
 htmlImportPlan=null;htmlImportPage=0;$('html-import-errors').textContent='';const replace=$('html-import-mode').value==='replace';$('html-import-replace-field').hidden=!replace;
 if(!htmlImportSource){$('html-import-summary').textContent='เลือกไฟล์ HTML ที่บันทึกข้อมูลไว้ โปรแกรมรุ่นปัจจุบันจะคงอยู่';renderHTMLImportPage();return}
 try{
  htmlImportPlan=buildHTMLImportPlan(htmlImportSource.data,$('html-import-mode').value);
  const p=htmlImportPlan,source=htmlImportSource.data,older=Number(source.updatedAt)<Number(state.updatedAt);
  $('html-import-summary').textContent=htmlImportSource.name+' · '+state.groups.length+'/'+state.tasks.length+' → '+p.next.groups.length+'/'+p.next.tasks.length+' หมวด/งาน · '+p.changes.length+' การเปลี่ยนแปลง'+(source.savedAt?' · ต้นทางบันทึก '+source.savedAt:'')+(older?' · ต้นทางเก่ากว่าข้อมูลปัจจุบัน โปรดตรวจค่าที่จะทับ':'')+(replace?' · แทนที่และใช้ลำดับจากไฟล์':' · ผสานตาม ID เก็บรายการ/ลำดับเดิม เพิ่มรายการใหม่ต่อท้าย; ค่าว่างที่มีในต้นทางจะทับค่าปัจจุบัน');
 }catch(error){$('html-import-errors').textContent=error.message}
 renderHTMLImportPage();
}
function openHTMLImport(){
 if(!requireEditor()||saving)return;clearHTMLImport();$('html-import-file').value='';$('html-import-mode').value='merge';$('html-import-replace-ok').checked=false;refreshHTMLImport();$('html-import-dialog').showModal();
}
async function readHTMLImportFile(file){
 if(!requireEditor())return;clearHTMLImport();const token=htmlImportGeneration;refreshHTMLImport();if(!file)return;$('html-import-summary').textContent='กำลังอ่าน '+file.name+'…';
 try{
  if(!/\.html?$/i.test(file.name))throw Error('กรุณาเลือกไฟล์ .html หรือ .htm');if(file.size>HTML_IMPORT_LIMIT)throw Error('HTML ต้องมีขนาดไม่เกิน 20 MB');
  const bytes=await file.arrayBuffer();if(token!==htmlImportGeneration||!isEditor)return;
  let text;try{text=new TextDecoder('utf-8',{fatal:true}).decode(bytes)}catch{throw Error('ไฟล์ HTML ต้องเป็น UTF-8')}
  const data=readHTMLSchedule(text);if(token!==htmlImportGeneration||!isEditor)return;htmlImportSource={name:file.name,data};$('html-import-replace-ok').checked=false;refreshHTMLImport();
 }catch(error){if(token!==htmlImportGeneration||!isEditor)return;htmlImportPlan=null;$('html-import-errors').textContent=error.message;renderHTMLImportPage()}
}
function confirmHTMLImport(){
 if(!requireEditor()||saving)return;const plan=htmlImportPlan;if(!plan)return;
 if(plan.revision!==revision){htmlImportPlan=null;$('html-import-errors').textContent='ข้อมูลเปลี่ยนหลังตรวจ กรุณากดตรวจข้อมูลอีกครั้ง';renderHTMLImportPage();return}
 if(!htmlImportCanConfirm())return;
 // Revalidate against live data, including cross-file ID collisions and parent moves.
 let checked;try{checked=buildHTMLImportPlan(plan.source,plan.mode)}catch(error){$('html-import-errors').textContent=error.message;return}
 clearTimeout(saveTimer);$('autosave').checked=false;fileHandle=null;clearCSVImport();cancelInlineEdit();cancelOrderMove();loadSavedFileCatalog();
 state=checked.next;arrangeTaskTree();activeTreeLevel=null;collapsedGroups.clear();expandedFileLists.clear();lastFilterKey=null;changed();$('html-import-dialog').close();toast('นำเข้าเฉพาะข้อมูลแล้ว โปรแกรมปัจจุบันยังอยู่ · กด Export HTML เพื่อเก็บไฟล์ใหม่');
}
$('import-html').onclick=openHTMLImport;
$('html-import-file').addEventListener('change',()=>readHTMLImportFile($('html-import-file').files?.[0]));
$('html-import-mode').addEventListener('change',()=>{$('html-import-replace-ok').checked=false;refreshHTMLImport()});
$('html-import-replace-ok').addEventListener('change',renderHTMLImportPage);
$('html-import-recheck').onclick=refreshHTMLImport;
$('html-import-confirm').onclick=confirmHTMLImport;
$('html-import-backup').onclick=downloadHTML;
$('html-import-prev').onclick=()=>{htmlImportPage--;renderHTMLImportPage()};$('html-import-next').onclick=()=>{htmlImportPage++;renderHTMLImportPage()};
$('html-import-dialog').addEventListener('close',clearHTMLImport);
$('html-import-dialog').addEventListener('cancel',clearHTMLImport);
