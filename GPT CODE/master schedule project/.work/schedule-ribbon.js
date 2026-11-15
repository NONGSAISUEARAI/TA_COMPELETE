// Ribbon tabs change tools only; the table, filters and data stay in place.
let activeRibbonTab='schedule',ribbonCollapsed=false;
const RIBBON_TABS=['overview','schedule','view','calendar','files'];
function selectRibbonTab(key,focus=false){
 if(!RIBBON_TABS.includes(key))return;
 activeRibbonTab=key;ribbonCollapsed=false;
 for(const tab of RIBBON_TABS){const selected=tab===key;$('ribbon-tab-'+tab).setAttribute('aria-selected',String(selected));$('ribbon-tab-'+tab).setAttribute('tabindex',selected?'0':'-1');$('ribbon-panel-'+tab).hidden=!selected}
 $('ribbon-panels').hidden=false;$('ribbon-collapse').setAttribute('aria-expanded','true');$('ribbon-collapse').textContent='⌃';$('ribbon-collapse').setAttribute('aria-label','ย่อแถบเครื่องมือ');
 if(focus)$('ribbon-tab-'+key).focus({preventScroll:true});
}
function refreshRibbonContext(){
 const parts=['วันรายงาน '+dayFormat(state.project.reportDate,true)],search=$('search').value.trim(),area=$('area-filter').value,status=$('status-filter').value;
 if(search)parts.push('ค้นหา: '+search);if(area&&area!=='all')parts.push('พื้นที่: '+area);if(status&&status!=='all')parts.push('สถานะ: '+statusNames[status]);
 if(calendarRange)parts.push(dayFormat(calendarRange.start,true)+' – '+dayFormat(calendarRange.end,true));
 $('ribbon-context').textContent=parts.join(' · ');
}
for(const key of RIBBON_TABS){
 $('ribbon-tab-'+key).onclick=()=>selectRibbonTab(key);
 $('ribbon-tab-'+key).addEventListener('keydown',event=>{
  const index=RIBBON_TABS.indexOf(key);let next=null;
  if(event.key==='ArrowRight')next=(index+1)%RIBBON_TABS.length;else if(event.key==='ArrowLeft')next=(index+RIBBON_TABS.length-1)%RIBBON_TABS.length;else if(event.key==='Home')next=0;else if(event.key==='End')next=RIBBON_TABS.length-1;
  if(next!==null){event.preventDefault();selectRibbonTab(RIBBON_TABS[next],true)}
 });
}
$('ribbon-collapse').onclick=()=>{ribbonCollapsed=!ribbonCollapsed;$('ribbon-panels').hidden=ribbonCollapsed;$('ribbon-collapse').setAttribute('aria-expanded',String(!ribbonCollapsed));$('ribbon-collapse').setAttribute('aria-label',ribbonCollapsed?'ขยายแถบเครื่องมือ':'ย่อแถบเครื่องมือ');$('ribbon-collapse').textContent=ribbonCollapsed?'⌄':'⌃'};
selectRibbonTab('schedule');
