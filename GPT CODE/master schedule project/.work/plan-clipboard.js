// Plan templates stay in this page; pasting stages changes until Save task.
let taskPlanClipboard=null,pendingPlanPaste=null,taskPlanClipboardHandles={root:null,children:[]},pendingPlanPasteHandles=[];
const TASK_PLAN_KEYS=['name','note','owner','category','start','end','barColor','dateMode','planStart','planEnd','actualStart','actualEnd','actualDateMode','progress','currentInfo','unit','quantity','workStatus','action','approvedDate','remark','fileCatalog','rowColor','planBarColor','actualBarColor'];
const TASK_COPY_DOCUMENT_KEYS=['currentInfo','unit','quantity','workStatus','action','approvedDate','remark'];
function planFormLevel(){const group=state.groups.find(g=>g.id===$('f-group').value);return isDatabaseGroup(group)?({product:2,work:3,activity:4})[$('f-db-level').value]:0}
function resetPlanPaste(){pendingPlanPaste=null;pendingPlanPasteHandles=[];$('plan-clipboard-note').hidden=true}
function refreshPlanClipboard(){
 $('copy-task-plan').disabled=!isEditor;
 $('paste-task-plan').disabled=!isEditor||!taskPlanClipboard;
 $('paste-task-plan').title=taskPlanClipboard?'วางจาก '+taskPlanClipboard.label+' · รวมงานย่อย '+taskPlanClipboard.children.length+' รายการ':'คัดลอกแผนงานต้นทางก่อน';
}
function pickTaskPlan(record){const result={};for(const key of TASK_PLAN_KEYS)if(record[key]!==undefined)result[key]=structuredClone(record[key]);return result}
function copyTaskPlan(){
 if(!requireEditor()||!$('task-dialog').open)return false;
 try{
  const dates=datePairInput('f','start','end','Plan'),actual=readActualFields('f'),drawing=readDrawingFields('f'),raw=state.tasks.find(t=>t.id===editingId);
  const root=pickTaskPlan({...raw,...pendingPlanPaste?.root});for(const key of ['name','note','owner','category'])root[key]=$('f-'+key).value.trim();
  if(!root.name)throw Error('กรอกชื่อรายการก่อนคัดลอกแผนงาน');
  Object.assign(root,{start:dates.start,end:dates.end,dateMode:'manual',planStart:dates.start,planEnd:dates.end,barColor:normalizeBarColor(colorDrafts.task?.value)});
  Object.assign(root,actual,{actualDateMode:'manual'});
  for(const key of TASK_COPY_DOCUMENT_KEYS)root[key]=drawing[key];
  const progress=$('f-progress').value.trim();root.progress=progress===''?null:Number(progress);
  if(root.progress!==null&&(!Number.isInteger(root.progress)||root.progress<0||root.progress>100))throw Error('ผลงานต้องเป็นจำนวนเต็มระหว่าง 0–100');
  if(colorDrafts.task?.changed){root.planBarColor=null;root.actualBarColor=null}
  root.fileCatalog=cleanFileCatalog(taskFileDraft);
  if(root.fileCatalog)root.fileCatalog.address=$('task-file-address').value.trim();
  const children=[],handles=[];
  function visit(id,parentIndex){for(const task of taskChildren(id)){const index=children.length;children.push({parentIndex,plan:pickTaskPlan(task),nodeType:task.nodeType});handles.push(taskFileHandles.get(task.id)||null);visit(task.id,index)}}
  if(pendingPlanPaste){children.push(...structuredClone(pendingPlanPaste.children));handles.push(...pendingPlanPasteHandles)}
  if(raw)visit(raw.id,-1);
  taskPlanClipboardHandles={root:taskFileHandle,children:handles};taskPlanClipboard={root,children,level:planFormLevel(),sourceId:editingId,label:root.name};refreshPlanClipboard();
  $('task-error').textContent='';$('plan-clipboard-note').hidden=false;$('plan-clipboard-note').textContent='คัดลอก “'+root.name+'” แล้ว · รวมงานย่อย '+children.length+' รายการ · เปิดงานปลายทางแล้วกดวางแผนงาน';
  return true;
 }catch(error){$('task-error').textContent=error.message;return false}
}
function validatePlanPaste(){
 if(!pendingPlanPaste)return;
 if(planFormLevel()!==pendingPlanPaste.level)throw Error('วางแผนในระดับเดียวกับต้นทาง เช่น LV3 ไป LV3');
}
function pasteTaskPlan(){
 if(!requireEditor()||!$('task-dialog').open||!taskPlanClipboard)return false;
 try{
  if(planFormLevel()!==taskPlanClipboard.level)throw Error('วางแผนในระดับเดียวกับต้นทาง เช่น LV3 ไป LV3');
  if(editingId&&editingId===taskPlanClipboard.sourceId)throw Error('เลือกงานปลายทางอื่นก่อนวางแผนงาน');
  pendingPlanPaste=structuredClone(taskPlanClipboard);
  pendingPlanPasteHandles=[...taskPlanClipboardHandles.children];
  const root=pendingPlanPaste.root;
  for(const key of ['name','note','owner','category','start','end','actualStart','actualEnd','progress',...TASK_COPY_DOCUMENT_KEYS])if(key!=='name'||planFormLevel()!==2)$('f-'+key).value=root[key]??'';
  datePlanDraft={mode:'manual',start:root.start,end:root.end};
  rev02Drafts.fActual={mode:'manual',start:root.actualStart||null,end:root.actualEnd||null};
  taskFileDraft=cleanFileCatalog(root.fileCatalog);taskFileHandle=taskPlanClipboardHandles.root;taskFileDirty=true;$('task-file-address').value=taskFileDraft?.address||'';renderTaskFiles();
  colorDrafts.task.value=root.barColor;colorDrafts.task.changed=true;renderBarColorEditor('task');
  updateTaskSummaryNote();updateDurationPreview();$('task-error').textContent='';
  const count=pendingPlanPaste.children.length,existing=editingId?descendantIds(editingId).size:0;
  $('plan-clipboard-note').hidden=false;$('plan-clipboard-note').textContent='วางข้อมูลทุกช่องจาก “'+pendingPlanPaste.label+'” แล้ว รวม Actual, % ผลงาน และไฟล์อ้างอิง'+(count?' · จะเพิ่มงานย่อย '+count+' รายการ'+(existing?' ต่อจากงานย่อยเดิม '+existing+' รายการ':''):'')+' · กดบันทึกงานเพื่อยืนยัน หรือยกเลิกเพื่อทิ้ง · คงโครงการ/Product/ตำแหน่งของปลายทาง';
  return true;
 }catch(error){$('task-error').textContent=error.message;return false}
}
function commitPlanPaste(target){
 if(!pendingPlanPaste||!target)return;
 for(const key of ['rowColor','planBarColor','actualBarColor'])target[key]=pendingPlanPaste.root[key]??null;
 const existing=taskChildren(target.id).length;
 if(pendingPlanPaste.children.length&&!existing)preserveDescriptionDates(target);
 // The visible copied dates are an explicit plan for this heading.
 if(taskChildren(target.id).length||pendingPlanPaste.children.length||databaseLevel(target)===3||target.nodeType==='section')Object.assign(target,{dateMode:'manual',planStart:target.start||null,planEnd:target.end||null});
 const ids=[],used=new Set(state.tasks.map(t=>t.id));let sequence=0;
 for(const entry of pendingPlanPaste.children){
  let id;do{id='plan-'+Date.now().toString(36)+'-'+(++sequence).toString(36)}while(used.has(id));used.add(id);ids.push(id);
  state.tasks.push({...structuredClone(entry.plan),id,groupId:target.groupId,parentId:entry.parentIndex<0?target.id:ids[entry.parentIndex],nodeType:entry.nodeType||'task',area:target.area});
  const handle=pendingPlanPasteHandles[ids.length-1];if(handle&&entry.plan.fileCatalog)taskFileHandles.set(id,handle);
 }
}
$('copy-task-plan').onclick=copyTaskPlan;
$('paste-task-plan').onclick=pasteTaskPlan;
$('task-dialog').addEventListener('close',resetPlanPaste);
