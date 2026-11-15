const fs=require('fs'),p='Master_Schedule.html';let s=fs.readFileSync(p,'utf8');fs.copyFileSync(p,'backups/Master_Schedule_before_lv2_progress_mode_'+Date.now()+'.html');function r(a,b){if(!s.includes(a))throw Error('Missing '+a.slice(0,80));s=s.replace(a,b)}
r('<label class="field">ผลงานจริง (%)<input id="f-progress"','<label class="field" id="f-progress-mode-field" hidden>วิธีระบุผลงาน LV2<select id="f-progress-mode"><option value="auto">อ้างอิงผลงานย่อย</option><option value="manual">ใส่เปอร์เซ็นต์เอง</option></select></label><label class="field">ผลงานจริง (%)<input id="f-progress"');
r('function summarizeTask(task){',"function lv2ManualProgress(task){return databaseLevel(task)===2&&task.progressMode==='manual'}\nfunction summarizeTask(task){");
r('if(lv4Activities(task).length)view.progress=lv3ActivityProgress(task);return view',"if(lv4Activities(task).length)view.progress=lv3ActivityProgress(task);if(lv2ManualProgress(task)){view.progress=task.progress??null;view.summaryStatus=status({...view,summaryStatus:null})}return view");
r("updateDatePlanStatus();refreshRev03Dates('f')}\n", "updateDatePlanStatus();refreshRev03Dates('f');refreshLV2ProgressMode()}\n");
r("datePlanDraft={mode:raw.dateMode==='manual'", "$('f-progress-mode').value=raw.progressMode==='manual'?'manual':'auto';datePlanDraft={mode:raw.dateMode==='manual'");
r("values.name=values.product;values.area=values.product;values.progress=current?summarizeTask(current).progress:null;", "values.name=values.product;values.area=values.product;values.progressMode=$('f-progress-mode').value==='manual'?'manual':'auto';if(values.progressMode!=='manual')values.progress=current?summarizeTask({...current,progressMode:'auto'}).progress:null;");
r("if(!pendingPlanPaste&&editingId&&(taskChildren(editingId).length", "if(!pendingPlanPaste&&values.progressMode!=='manual'&&editingId&&(taskChildren(editingId).length");
r("if(field==='progress'&&inlineSummary(kind,record))continue;", "if(field==='progress'&&inlineSummary(kind,record)&&!lv2ManualProgress(record))continue;");
r("if(summary)throw Error('ผลงานหัวข้อแม่คำนวณจากงานย่อย');", "if(summary&&!lv2ManualProgress(record))throw Error('ผลงานหัวข้อแม่คำนวณจากงานย่อย');");
r("for(const key of ['dateMode','actualDateMode'])", "for(const key of ['dateMode','actualDateMode','progressMode'])");
r("const TASK_PLAN_KEYS=['name'", "const TASK_PLAN_KEYS=['progressMode','name'");
r("root.progress=progress===''?null:Number(progress);", "root.progress=progress===''?null:Number(progress);if(planFormLevel()===2)root.progressMode=$('f-progress-mode').value==='manual'?'manual':'auto';");
r('const root=pendingPlanPaste.root;\n', "const root=pendingPlanPaste.root;\n  $('f-progress-mode').value=root.progressMode==='manual'?'manual':'auto';\n");
const js=`
function refreshLV2ProgressMode(){
 const raw=state.tasks.find(t=>t.id===editingId),group=state.groups.find(g=>g.id===$('f-group').value),lv2=raw?databaseLevel(raw)===2:isDatabaseGroup(group)&&$('f-db-level').value==='product';
 $('f-progress-mode-field').hidden=!lv2;
 if(!lv2)return;
 const manual=$('f-progress-mode').value==='manual';$('f-progress').readOnly=!manual;
 if(!manual)$('f-progress').value=raw?summarizeTask({...raw,progressMode:'auto'}).progress??'':'';
 $('f-summary-note').hidden=false;$('f-summary-note').textContent=manual?'LV2 · ใส่ผลงานเอง 0–100% · แตะช่องผลงานในตารางเพื่อแก้ไขได้':'LV2 · ผลงานอ้างอิงจากงานย่อย · เลือก “ใส่เปอร์เซ็นต์เอง” เพื่อกำหนดผลงานของหัวข้อนี้';
}
$('f-progress-mode').onchange=refreshLV2ProgressMode;
`;
const at=s.lastIndexOf('render();saveStatus();');s=s.slice(0,at)+js+s.slice(at);fs.writeFileSync(p,s);console.log('LV2 progress mode added');
