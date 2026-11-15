function overdueTextSettings(){const saved=state.project.overdueTextRule;return {enabled:saved?.enabled===true,color:normalizeBarColor(saved?.color)||'#ff8b7d',reference:saved?.reference==='today'?'today':'report'}}
function overdueTodayISO(){const parts=new Intl.DateTimeFormat('en-US',{timeZone:'Asia/Bangkok',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(new Date()),value=type=>parts.find(part=>part.type===type).value;return value('year')+'-'+value('month')+'-'+value('day')}
function overdueReferenceDate(){return overdueTextSettings().reference==='today'?overdueTodayISO():state.project.reportDate}
function isOverdueTextRow(record){const settings=overdueTextSettings(),reference=overdueReferenceDate();return Boolean(settings.enabled&&reference&&validRecordDate(reference)&&record.end&&validRecordDate(record.end)&&record.end<reference&&record.progress!==100)}
function refreshOverdueTextControls(){
 const settings=overdueTextSettings();$('overdue-text-enabled').checked=settings.enabled;$('overdue-text-color').value=settings.color;$('overdue-text-reference').value=settings.reference;
 for(const id of ['overdue-text-enabled','overdue-text-color','overdue-text-reference','overdue-text-apply'])$(id).disabled=!isEditor;
 $('schedule').style.setProperty('--overdue-text-color',settings.color);
 $('overdue-text-note').textContent=(settings.enabled?'เปิดใช้งาน':'ปิดใช้งาน')+' · อ้างอิง'+(settings.reference==='today'?'วันที่ปัจจุบัน':'วันรายงาน')+' '+dayFormat(overdueReferenceDate(),true)+' · End ก่อนวันอ้างอิง และผลงานยังไม่ครบ 100% (ยังไม่กรอก % ถือว่ายังไม่เสร็จ)';
}
function applyOverdueTextSettings(){
 if(!requireEditor())return false;
 const color=normalizeBarColor($('overdue-text-color').value),reference=$('overdue-text-reference').value;
 if(!color||!['report','today'].includes(reference)){toast('กรุณาเลือกสีและวันอ้างอิงให้ถูกต้อง');return false}
 if(inlineEditor){toast('บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อน');return false}
 state.project.overdueTextRule={enabled:$('overdue-text-enabled').checked,color,reference};changed();toast('ปรับโหมดสีตัวอักษรแล้ว · กดบันทึก HTML เพื่อเก็บการตั้งค่า');return true;
}
$('overdue-text-apply').onclick=applyOverdueTextSettings;
