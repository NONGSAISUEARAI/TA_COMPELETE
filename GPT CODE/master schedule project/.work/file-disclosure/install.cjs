const fs=require('fs'),assert=require('assert/strict'),vm=require('vm');
const file='Master_Schedule.html',before=fs.readFileSync(file,'utf8'),pattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/,data=JSON.parse(before.match(pattern)[1]);
const backup=fs.readFileSync('.work/file-disclosure/backup-path.txt','utf8');assert.equal(before,fs.readFileSync(backup+'/'+file,'utf8'),'Read latest data and back up again');
let h=before;function once(a,b){assert.equal(h.split(a).length,2,'Non-unique patch '+a.slice(0,100));h=h.replace(a,()=>b)}
once(fs.readFileSync('.work/file-disclosure/old-taskFilesBadge.txt','utf8'),fs.readFileSync('.work/file-disclosure/markup.js','utf8'));
once("const headingBlock='<div class=\"db-title-line\">'+heading+(!main?taskFilesBadge(t):'')+'</div>';","const headingBlock='<div class=\"db-title-line\">'+heading+(!main?taskFilesBadge(t):'')+'</div>'+(!main?taskFilesBody(t):'');");
once("const id=details.dataset.filesTask;if(!state.tasks.some(t=>t.id===id))return;if(details.open)expandedFileLists.add(id);else expandedFileLists.delete(id)","syncTaskFilesDisclosure(details)");
once('.db-title-line>.task-files-disclosure[open]{grid-column:1/-1;justify-self:stretch;width:auto;max-width:none;flex-basis:auto}\n.db-title-line>.task-files-disclosure[open] .task-files-body{min-width:0;overflow-wrap:anywhere}',
`/* Keep the native disclosure control in the header; its associated region follows the header. */
.db-title-line>.group-toggle,.db-title-line>.taskname{grid-column:1;grid-row:1}
.db-title-line>.task-files-disclosure,.db-title-line>.task-files-disclosure[open]{grid-column:2;grid-row:1;justify-self:end;align-self:start;flex-basis:auto}
.tree-content>.task-files-body{min-width:0;max-width:100%;margin-top:7px;padding:3px 0 2px 24px;overflow-wrap:anywhere}
.tree-content>.task-files-body[hidden]{display:none!important}
.tree-content>.task-files-body .task-file-preview{margin-top:3px}`);
assert.equal(h.match(pattern)[1],before.match(pattern)[1]);for(const m of h.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g))if(!m[1].includes('application/json'))new vm.Script(m[2]);
fs.writeFileSync(file,h);console.log(JSON.stringify({backup,groups:data.groups.length,tasks:data.tasks.length,dataUnchanged:true}));
