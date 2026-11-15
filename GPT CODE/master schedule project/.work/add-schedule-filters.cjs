const fs=require('fs'),p='Master_Schedule.html';let s=fs.readFileSync(p,'utf8');fs.copyFileSync(p,'backups/Master_Schedule_before_search_filter_'+Date.now()+'.html');
function replace(a,b){if(!s.includes(a))throw Error('missing '+a.slice(0,100));s=s.replace(a,b)}
replace("const RIBBON_TABS=['overview','schedule','view','calendar','format','files'];","const RIBBON_TABS=['overview','schedule','filter','view','calendar','format','files'];");
replace('<button type="button" id="ribbon-tab-view"','<button type="button" id="ribbon-tab-filter" role="tab" aria-controls="ribbon-panel-filter" aria-selected="false" tabindex="-1">ค้นหา / กรอง</button><button type="button" id="ribbon-tab-view"');
const start=s.indexOf('<div class="ribbon-group"><div class="ribbon-tools"><input id="search"'),end=s.indexOf('<div class="ribbon-group"><div class="ribbon-tools"><button id="toggle-drawing-core"',start),old=s.slice(start,end),area=old.match(/<select id="area-filter"[\s\S]*?<\/select>/)[0],statusSelect=old.match(/<select id="status-filter"[\s\S]*?<\/select>/)[0];s=s.slice(0,start)+s.slice(end);
const panel=`<div id="ribbon-panel-filter" class="ribbon-panel" role="tabpanel" aria-labelledby="ribbon-tab-filter" hidden>
<div class="schedule-filter-grid">
<label class="filter-query">คำค้น<input id="search" type="search" placeholder="WBS / ชื่องาน / รายละเอียด / ผู้รับผิดชอบ" aria-label="ค้นหา WBS ชื่องาน รายละเอียด และผู้รับผิดชอบ"></label>
<label>โครงการ<select id="filter-project"><option value="all">ทุกโครงการ</option></select></label>
<label>หมวดงาน<select id="filter-branch"><option value="all">ทุกหมวดงาน</option></select></label>
<div class="filter-owner-field"><span>ผู้รับผิดชอบ (เลือกหลายคน)</span><button id="filter-owner-toggle" type="button" aria-expanded="false" aria-controls="filter-owner-options">ทุกคน ▾</button><div id="filter-owner-options" hidden role="group" aria-label="เลือกผู้รับผิดชอบ"></div></div>
<label>ความก้าวหน้า<select id="filter-progress"><option value="all">ทุกความก้าวหน้า</option><option value="not-started">ยังไม่เริ่ม (0% / ยังไม่กรอก)</option><option value="in-progress">กำลังทำ (1–99%)</option><option value="complete">ครบ 100%</option><option value="incomplete">ยังไม่ครบ 100%</option></select></label>
<label>กำหนดเวลา<select id="filter-deadline"><option value="all">ทุกกำหนดเวลา</option><option value="late">เลยกำหนด / ยังไม่ครบ 100%</option><option value="soon">ครบกำหนดภายใน 7 วัน / ยังไม่ครบ 100%</option><option value="range">ช่วงวันที่ Plan</option></select></label>
<label>ตั้งแต่วันที่<input id="filter-from" type="date" disabled></label><label>ถึงวันที่<input id="filter-to" type="date" disabled></label>
<label>ระดับงาน<select id="filter-level"><option value="all">ทุกระดับ</option><option value="1">LV1</option><option value="2">LV2</option><option value="3">LV3</option><option value="4">LV4</option></select></label>
<label>พื้นที่${area}</label><label>สถานะตามแผน${statusSelect}</label>
</div><div class="schedule-filter-footer"><button id="filter-clear" type="button">ล้างตัวกรอง</button><strong id="filter-count" role="status" aria-live="polite"></strong><span id="filter-hint">แสดงแถวแม่ของรายการที่พบ · กำหนดเวลาอ้างอิงวันรายงาน · ช่วงวันที่ใช้ Plan ที่ทับซ้อน</span><span id="filter-error" role="alert"></span></div></div>`;
replace('<div id="ribbon-panel-view"',panel+'<div id="ribbon-panel-view"');
replace(" const query=$('search').value.toLowerCase().trim(),area=$('area-filter').value,filter=$('status-filter').value;\n", " refreshScheduleFilterOptions();\n const criteria=scheduleFilterCriteria(),query=criteria.query,area=criteria.area,filter=criteria.status;\n");
replace(" const hasFilters=Boolean(query||area!=='all'||filter!=='all'),filterKey=JSON.stringify([query,area,filter]);", " const hasFilters=scheduleFiltersActive(criteria),filterKey=JSON.stringify(criteria);");
replace(" const matches=(t,terms)=>(area==='all'||t.area===area)&&(filter==='all'||status(t)===filter)&&(!query||[t.name,t.area,t.owner||'',t.category||'',t.note||'',...terms].some(x=>String(x).toLowerCase().includes(query)));", " let matchedCount=0;const matches=(t,terms,code)=>{const matched=matchesScheduleFilter(t,terms,code,criteria);if(matched)matchedCount++;return matched};");
replace("match:!hasFilters||matches(view,terms)||children.some(c=>c.match)","match:matches(view,terms,code)||children.some(c=>c.match)");
replace("if(hasFilters&&!matches(view,[group.note||''])&&!nodes.some(n=>n.match))return;", "const groupMatches=matches(view,[group.note||''],String(gi+1));if(hasFilters&&!groupMatches&&!nodes.some(n=>n.match))return;");
replace(" refreshRibbonContext();\n $('row-count')", " refreshRibbonContext();\n $('filter-count').textContent='พบ '+matchedCount+' / '+(state.groups.length+state.tasks.length)+' รายการ'+(hasFilters?' · รวมแถวแม่ที่แสดง '+(shownGroups+shownChildren)+' แถว':'');\n $('row-count')");
replace(" if(calendarRange)parts.push", " if(scheduleFiltersActive(scheduleFilterCriteria()))parts.push($('filter-count').textContent||'กำลังกรองรายการ');\n if(calendarRange)parts.push");
// Update the result count before the shared context text.
replace(" refreshRibbonContext();\n $('filter-count').textContent=", " $('filter-count').textContent=");
replace("+(hasFilters?' · รวมแถวแม่ที่แสดง '+(shownGroups+shownChildren)+' แถว':'');\n $('row-count')", "+(hasFilters?' · รวมแถวแม่ที่แสดง '+(shownGroups+shownChildren)+' แถว':'');\n refreshRibbonContext();\n $('row-count')");
const js=`
// Filtering changes only the view; no task data, drafts or revisions are written.
let scheduleOwnerFilters=new Set();
function filterSelectOptions(id,items,allLabel){const el=$(id),previous=el.value||'all';el.innerHTML='<option value="all">'+allLabel+'</option>'+items.map(([value,label])=>'<option value="'+escapeHTML(value)+'">'+escapeHTML(label)+'</option>').join('');el.value=items.some(([value])=>value===previous)?previous:'all'}
function refreshScheduleFilterOptions(){
 filterSelectOptions('filter-project',state.groups.map(g=>[g.id,g.pjCode?g.pjCode+' / '+(g.projectWorks||g.name):g.name]),'ทุกโครงการ');
 const group=$('filter-project').value,paths=taskPaths();
 filterSelectOptions('filter-branch',state.tasks.filter(t=>!t.parentId&&(group==='all'||t.groupId===group)).map(t=>[t.id,(paths.get(t.id)||'')+' · '+(t.product||t.name)]),'ทุกหมวดงาน');
 const owners=[...new Set([...state.groups,...state.tasks].map(r=>r.owner).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'th'));scheduleOwnerFilters=new Set([...scheduleOwnerFilters].filter(owner=>owners.includes(owner)||owner==='__unassigned__'));
 $('filter-owner-options').innerHTML=[...owners.map(owner=>[owner,owner]),['__unassigned__','ยังไม่ระบุผู้รับผิดชอบ']].map(([value,label])=>'<label><input type="checkbox" data-filter-owner="'+escapeHTML(value)+'" '+(scheduleOwnerFilters.has(value)?'checked':'')+'>'+escapeHTML(label)+'</label>').join('');
 $('filter-owner-toggle').textContent=scheduleOwnerFilters.size?'เลือก '+scheduleOwnerFilters.size+' คน ▾':'ทุกคน ▾';
 const range=$('filter-deadline').value==='range';$('filter-from').disabled=!range;$('filter-to').disabled=!range;
}
function scheduleFilterCriteria(){return {query:$('search').value.toLowerCase().trim(),area:$('area-filter').value||'all',status:$('status-filter').value||'all',project:$('filter-project').value||'all',branch:$('filter-branch').value||'all',owners:[...scheduleOwnerFilters].sort(),progress:$('filter-progress').value||'all',deadline:$('filter-deadline').value||'all',from:$('filter-from').value,to:$('filter-to').value,level:$('filter-level').value||'all'}}
function scheduleFiltersActive(c){return Boolean(c.query||c.owners.length||['area','status','project','branch','progress','deadline','level'].some(k=>c[k]!=='all'))}
function matchesScheduleFilter(t,terms,code,c){
 const group=databaseGroup(t),level=String(code.split('.').length),root=c.branch&&(c.branch===t.id||descendantIds(c.branch).has(t.id));
 if(c.project!=='all'&&group?.id!==c.project||c.branch!=='all'&&!root||c.level!=='all'&&level!==c.level||c.area!=='all'&&t.area!==c.area||c.status!=='all'&&status(t)!==c.status)return false;
 if(c.owners.length&&!c.owners.includes(t.owner)&&!(c.owners.includes('__unassigned__')&&(!t.owner||t.owner==='—')))return false;
 const progress=t.progress??0;if(c.progress==='not-started'&&progress!==0||c.progress==='in-progress'&&!(progress>0&&progress<100)||c.progress==='complete'&&progress!==100||c.progress==='incomplete'&&progress===100)return false;
 const ref=state.project.reportDate,end=t.end,start=t.start;
 if(c.deadline==='late'&&(!end||!validRecordDate(end)||end>=ref||progress===100))return false;
 if(c.deadline==='soon'&&(!end||!validRecordDate(end)||end<ref||end>dateISO(dateNumber(ref)+7*DAY)||progress===100))return false;
 if(c.deadline==='range'){
  if(c.from&&c.to&&c.from>c.to)return false;
  if(!start||!end||!validRecordDate(start)||!validRecordDate(end)||(c.from&&end<c.from)||(c.to&&start>c.to))return false;
 }
 const core=drawingFieldsFor(t),text=[code,t.name,t.area,t.owner,t.category,t.note,t.currentInfo,t.remark,t.action,...Object.values(core),...terms].join(' ').toLowerCase();
 return !c.query||c.query.split(/\\s+/).every(word=>text.includes(word));
}
function closeScheduleOwnerPicker(){$('filter-owner-options').hidden=true;$('filter-owner-toggle').setAttribute('aria-expanded','false')}
$('filter-owner-toggle').onclick=()=>{const el=$('filter-owner-options'),show=el.hidden;closeScheduleOwnerPicker();if(show){const rect=$('filter-owner-toggle').getBoundingClientRect();el.style.left=Math.max(8,Math.min(rect.left,window.innerWidth-260))+'px';el.style.top=Math.min(rect.bottom+4,Math.max(8,window.innerHeight-250))+'px';el.hidden=false;$('filter-owner-toggle').setAttribute('aria-expanded','true')}};
$('filter-owner-options').addEventListener('change',event=>{const el=event.target;if(!el.hasAttribute('data-filter-owner'))return;const value=el.getAttribute('data-filter-owner');if(el.checked)scheduleOwnerFilters.add(value);else scheduleOwnerFilters.delete(value);render()});
document.addEventListener('click',event=>{if(!event.target.closest('.filter-owner-field'))closeScheduleOwnerPicker()});
document.addEventListener('keydown',event=>{if(event.key==='Escape')closeScheduleOwnerPicker()});
window.addEventListener('resize',closeScheduleOwnerPicker);
for(const id of ['filter-project','filter-branch','filter-progress','filter-deadline','filter-from','filter-to','filter-level'])$(id).addEventListener('change',()=>{if(id==='filter-project')$('filter-branch').value='all';render()});
$('filter-clear').onclick=()=>{scheduleOwnerFilters.clear();$('search').value='';for(const id of ['area-filter','status-filter','filter-project','filter-branch','filter-progress','filter-deadline','filter-level'])$(id).value='all';$('filter-from').value='';$('filter-to').value='';closeScheduleOwnerPicker();render()};
`;
replace('render();saveStatus();',js+'\nrender();saveStatus();');
replace(" const range=$('filter-deadline').value==='range';", " const range=$('filter-deadline').value==='range';$('filter-error').textContent=range&&$('filter-from').value&&$('filter-to').value&&$('filter-from').value>$('filter-to').value?'วันเริ่มต้องไม่เกินวันสิ้นสุด':'';");
const css=`<style id="schedule-filters-style">
#ribbon-panel-filter:not([hidden]){display:block}
.schedule-filter-grid{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:5px 10px}
.schedule-filter-grid>label,.filter-owner-field{display:flex;flex-direction:column;gap:2px;min-width:0;font-size:10px;color:#bfd0da;margin:0}
.schedule-filter-grid .filter-query{grid-column:span 2}
.schedule-filter-grid input,.schedule-filter-grid select,.schedule-filter-grid button{box-sizing:border-box;width:100%;min-width:0;height:27px;padding:3px 7px;font-size:11px;border:1px solid #415b69;border-radius:5px;background:#10212d;color:#d7e8ed}
.schedule-filter-grid input:disabled{opacity:.4}
#filter-owner-toggle{text-align:left}
#filter-owner-options{position:fixed;z-index:1000;width:250px;max-height:230px;overflow:auto;padding:7px;border:1px solid #6c978e;border-radius:6px;background:#172d38;box-shadow:0 6px 20px #0008}
#filter-owner-options label{display:flex;align-items:center;gap:6px;padding:5px;font-size:12px;cursor:pointer}
#filter-owner-options input{width:15px;height:15px;margin:0;accent-color:#72cdae}
.schedule-filter-footer{display:flex;align-items:center;flex-wrap:wrap;gap:5px 10px;margin-top:5px;font-size:10px;color:#9fb9c4}
.schedule-filter-footer button{padding:4px 8px;font-size:10px}.schedule-filter-footer strong{color:#c5dcd7}#filter-error{color:#ff8b7d}
@media(max-width:1100px){.schedule-filter-grid{grid-template-columns:repeat(4,minmax(0,1fr))}.schedule-filter-footer #filter-hint{display:none}}
@media(max-width:650px){.schedule-filter-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.schedule-filter-footer{padding-bottom:4px}}
@media print{#filter-owner-options{display:none!important}}
</style>\n`;
replace('</head>',css+'</head>');fs.writeFileSync(p,s);console.log('Search/filter panel and combined hierarchy-aware filtering added.');
