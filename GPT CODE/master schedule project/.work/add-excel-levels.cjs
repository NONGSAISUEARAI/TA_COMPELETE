const fs=require('fs'),p='Master_Schedule.html';let s=fs.readFileSync(p,'utf8');fs.copyFileSync(p,'backups/Master_Schedule_before_excel_levels_'+Date.now()+'.html');function r(a,b){if(!s.includes(a))throw Error('missing '+a.slice(0,70));s=s.replace(a,b)}
r('ส่งออกงานระดับสุดท้าย Description / Activity พร้อมข้อมูลโครงการครบทุกแถว', 'เลือกระดับ LV3 / LV4 หรือส่งออกงานระดับสุดท้ายแบบเดิม พร้อมข้อมูลโครงการกำกับทุกแถว');
r('<label class="field full" style="display:flex;flex-direction:row;align-items:center;gap:8px"><input id="excel-calendar"', '<label class="field full">ระดับข้อมูลที่จะส่งออก<select id="excel-level"><option value="leaf">งานระดับสุดท้าย (แบบเดิม)</option><option value="3">LV3 เท่านั้น · Description</option><option value="4">LV4 เท่านั้น · Activity</option></select></label><label class="field full" style="display:flex;flex-direction:row;align-items:center;gap:8px"><input id="excel-calendar"');
const start=s.indexOf("function excelExportRecords(groupId='all')"),end=s.indexOf('\n}',start)+2;
s=s.slice(0,start)+`function excelExportRecords(groupId='all',level='leaf'){
 if(!['leaf','3','4'].includes(level))throw Error('ระดับข้อมูล Excel ไม่ถูกต้อง');
 const all=scheduleTreeRecords(groupId),database=state.groups.some(isDatabaseGroup);
 const rows=level==='leaf'?(database?all.filter(r=>!r.section):all):all.filter(r=>(databaseLevel(r.raw)||r.depth+1)===Number(level));
 for(const r of rows)if(database&&databaseIdentity(r.raw).slice(0,5).some(v=>!v))throw Error('งาน '+r.raw.name+' ยังมีข้อมูล PJ / Project Works / Group Drawing / Product / Description ไม่ครบ');return rows;
}`+s.slice(end);
const a=s.indexOf('function refreshExcelExport('),b=s.indexOf('\nfunction openExcelExport',a);
s=s.slice(0,a)+`function refreshExcelExport(resetDates=false){try{const level=$('excel-level').value||'leaf',rows=excelExportRecords($('excel-group').value||'all',level);if(resetDates){const bounds=excelCalendarBounds(rows);$('excel-start').value=bounds.start;$('excel-end').value=bounds.end}const calendar=$('excel-calendar').checked;$('excel-start').disabled=!calendar;$('excel-end').disabled=!calendar;$('excel-summary').textContent=rows.length+' รายการ · '+(level==='leaf'?'งานระดับสุดท้าย (แบบเดิม)':'LV'+level+' เท่านั้น')+' · '+rows.length*2+' แถว PLAN / ACTUAL'+(level==='3'?' · รวม LV3 ที่มี LV4 โดยใช้วันที่สรุปของ LV3':'');$('excel-error').textContent=rows.length?'':'ไม่พบรายการในระดับที่เลือก กรุณาเปลี่ยนระดับหรือหมวดงาน';$('excel-submit').disabled=!rows.length}catch(error){$('excel-summary').textContent='';$('excel-submit').disabled=true;$('excel-error').textContent=error.message}}
`+s.slice(b);
r("$('excel-group').value='all';$('excel-calendar').checked=true;refreshExcelExport(true);", "$('excel-group').value='all';$('excel-level').value='leaf';$('excel-calendar').checked=true;refreshExcelExport(true);");
r("function buildExcelWorkbook({groupId='all',calendar=true,start,end}={})", "function buildExcelWorkbook({groupId='all',level='leaf',calendar=true,start,end}={})");
r('const records=excelExportRecords(groupId);', 'const records=excelExportRecords(groupId,level);');
r("'Master_Schedule_Rev04_'+label+'_'", "'Master_Schedule_Rev04_'+label+(level==='leaf'?'':'_LV'+level)+'_'");
r("buildExcelWorkbook({groupId:$('excel-group').value||'all',calendar:", "buildExcelWorkbook({groupId:$('excel-group').value||'all',level:$('excel-level').value||'leaf',calendar:");
r("$('excel-group').onchange=()=>refreshExcelExport(true);", "$('excel-group').onchange=()=>refreshExcelExport(true);\n$('excel-level').onchange=()=>refreshExcelExport(true);");fs.writeFileSync(p,s);
