const fs=require('fs'),assert=require('assert/strict');const file='Master_Schedule.html';let html=fs.readFileSync(file,'utf8');
const data=html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1];
const old="function summarizeTask(task){if(taskChildren(task.id).length||task.nodeType==='section')return summarizeRecord(task,taskLeaves(task));return databaseLevel(task)===3&&task.dateMode==='manual'?{...task,start:task.planStart||null,end:task.planEnd||null}:task}";
assert(html.includes(old));
html=html.replace(old,`function lv4Activities(task){return databaseLevel(task)===3?taskChildren(task.id).filter(child=>databaseLevel(child)===4):[]}
function lv3ActivityProgress(task){const activities=lv4Activities(task);if(!activities.length)return task.progress??null;if(activities.every(hasProgress)&&activities.every(t=>t.progress===100))return 100;return Math.min(99,Math.round(activities.reduce((sum,t)=>sum+(hasProgress(t)?t.progress:0),0)/activities.length))}
function summarizeTask(task){if(taskChildren(task.id).length||task.nodeType==='section'){const view=summarizeRecord(task,taskLeaves(task));if(lv4Activities(task).length)view.progress=lv3ActivityProgress(task);return view}return databaseLevel(task)===3&&task.dateMode==='manual'?{...task,start:task.planStart||null,end:task.planEnd||null}:task}`);
const note="updateDatePlanStatus();refreshRev03Dates('f')}";assert(html.includes(note));
html=html.replace(note,`if(current&&lv4Activities(current).length){const count=lv4Activities(current).length;$('f-summary-note').textContent='LV3 นี้มี LV4 '+count+' รายการ · ผลงานเฉลี่ยจาก % ของแต่ละรายการโดยให้น้ำหนักเท่ากัน · รายการที่ยังไม่กรอกคิดเป็น 0% · วันที่ Plan/Actual กำหนดเองได้'}updateDatePlanStatus();refreshRev03Dates('f')}`);
assert.equal(html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1],data);fs.writeFileSync(file,html);console.log('LV3 progress now averages direct LV4 activities equally; embedded data unchanged.');
