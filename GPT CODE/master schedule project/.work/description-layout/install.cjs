const fs=require('fs'),assert=require('assert/strict'),vm=require('vm'),crypto=require('crypto');
const file='Master_Schedule.html',backup=fs.readFileSync('.work/description-layout/baseline-path.txt','utf8'),base=fs.readFileSync(backup+'/'+file,'utf8'),live=fs.readFileSync(file,'utf8'),hash=s=>crypto.createHash('sha256').update(s).digest('hex'),hashFile='.work/description-layout/installed-hash.txt';
assert.equal(hash(live),fs.existsSync(hashFile)?fs.readFileSync(hashFile,'utf8'):hash(base),'HTML changed elsewhere; merge latest data first');
const pattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/;JSON.parse(live.match(pattern)[1]);let h=base;
function once(a,b){assert.equal(h.split(a).length,2,'Patch not unique '+a.slice(0,80));h=h.replace(a,()=>b)}
once('<th class="col-name">Description / รายการงาน</th>','<th class="col-name">Description / Activity<span id="description-resize" class="description-resize-handle" role="separator" aria-orientation="vertical" aria-label="ปรับความกว้าง Description" aria-valuemin="280" aria-valuemax="1200" aria-valuenow="360" tabindex="0" title="ลากเพื่อยืด–หดช่อง Description · ดับเบิลคลิกคืนค่าเริ่มต้น · ใช้ปุ่มลูกศรซ้าย/ขวาได้"></span></th>');
once('const DRAWING_COLUMNS=',fs.readFileSync('.work/description-layout/resize.js','utf8')+'\nconst DRAWING_COLUMNS=');
once('nameWidth=Math.max(360,240+(maxDepth+1)*22)','nameWidth=descriptionColumnWidth??Math.max(360,240+(maxDepth+1)*22)');
once("$('schedule').style.setProperty('--week-count',numberOfWeeks);", "$('schedule').style.setProperty('--week-count',numberOfWeeks);syncDescriptionResizeHandle();");
once("const headingBlock=db?'<div class=\"db-title-line\">'+heading+(!main?taskFilesBadge(t):'')+'</div>':name;", "const headingBlock='<div class=\"db-title-line\">'+heading+(!main?taskFilesBadge(t):'')+'</div>';");
once("+(!db&&!main?taskFilesBadge(t):'')",'');
const css=`
/* File controls share the right edge at every tree level. */
.db-title-line{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:7px 12px;align-items:start;min-width:0}
.db-title-line>.group-toggle,.db-title-line>.taskname{width:auto;min-width:0;margin:0;overflow-wrap:anywhere}
.db-title-line>.group-toggle>span:last-child,.db-title-line>.taskname>span:last-child{min-width:0;overflow-wrap:anywhere;white-space:normal}
.db-title-line>.task-files-disclosure{margin:0;max-width:100%;min-width:0;align-self:start;justify-self:end}
.db-title-line>.task-files-disclosure>summary{margin-left:auto;white-space:nowrap}
.db-title-line>.task-files-disclosure[open]{grid-column:1/-1;justify-self:stretch;width:auto;max-width:none;flex-basis:auto}
.db-title-line>.task-files-disclosure[open] .task-files-body{min-width:0;overflow-wrap:anywhere}
.schedule th.col-name{padding-right:18px}
.description-resize-handle{position:absolute;top:0;right:-4px;width:10px;height:100%;cursor:col-resize;touch-action:none;z-index:8;user-select:none}
.description-resize-handle::after{content:'';position:absolute;top:0;bottom:0;left:4px;width:2px;background:#52707f;transition:background .12s}
.description-resize-handle:hover::after,.description-resize-handle:focus-visible::after{background:#72cdae;width:3px}
.description-resize-handle:focus-visible{outline:2px solid #72cdae;outline-offset:-2px}
body.resizing-description,body.resizing-description *{cursor:col-resize!important;user-select:none!important}
@media screen and (max-width:600px){.schedule th.col-name,.schedule td.col-name{left:auto}}
@media print{.description-resize-handle{display:none!important}.db-title-line{grid-template-columns:minmax(0,1fr)}.db-title-line>.task-files-disclosure{justify-self:end}}
`;
once('</head>','<style id="description-layout-style">'+css+'</style>\n</head>');
assert.equal(h.match(pattern)[1],base.match(pattern)[1],'User data must not change');
for(const m of h.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g))if(!m[1].includes('application/json'))new vm.Script(m[2]);
fs.writeFileSync(file,h);fs.writeFileSync(hashFile,hash(h));console.log(JSON.stringify({result:'installed',backup,sha256:hash(h),data:'unchanged'}));
