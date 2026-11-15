let timelineColorSelection=new Map();
function timelineColorKey(item){return item.kind+':'+item.id+':'+item.phase}
function clearTimelineColorSelection(){timelineColorSelection.clear();refreshTimelineColors()}
function refreshTimelineColors(){
 if(!isEditor)timelineColorSelection.clear();
 for(const [key,item]of timelineColorSelection)if(!inlineRecord(item.kind,item.id))timelineColorSelection.delete(key);
 $('timeline-color-panel').hidden=!timelineColorSelection.size;
 $('timeline-color-title').textContent='เปลี่ยนสี '+timelineColorSelection.size+' แถบ Plan / Actual';
 document.querySelectorAll('[data-bar-color-id]').forEach(bar=>{const item={kind:bar.dataset.barColorKind,id:bar.dataset.barColorId,phase:bar.dataset.dateKind};bar.tabIndex=isEditor?0:-1;bar.setAttribute('aria-disabled',String(!isEditor));bar.setAttribute('aria-pressed',String(timelineColorSelection.has(timelineColorKey(item))));bar.classList.toggle('timeline-color-selected',timelineColorSelection.has(timelineColorKey(item)))});
}
function chooseTimelineColorBar(bar,multiple=false){
 if(!requireEditor())return;
 if(inlineEditor){if(inlineEditor.input.value!==inlineEditor.initialValue){toast('บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อนเลือกสี');return}cancelInlineEdit()}
 const item={kind:bar.dataset.barColorKind,id:bar.dataset.barColorId,phase:bar.dataset.dateKind},record=inlineRecord(item.kind,item.id);if(!record)return;
 const had=timelineColorSelection.size>0;if(!multiple)timelineColorSelection.clear();
 const key=timelineColorKey(item);if(multiple&&timelineColorSelection.has(key))timelineColorSelection.delete(key);else timelineColorSelection.set(key,item);
 if(!had||!multiple){const paint=barColorPaint(record.barColor)||defaultBarPaint(item.kind==='group'?'group':inlineSummary(item.kind,record)?'summary':'task');$('timeline-color-value').value=normalizeBarColor(record[item.phase==='plan'?'planBarColor':'actualBarColor'])||(item.phase==='plan'?paint.plan:paint.done)}
 cancelBatchDates();$('timeline-color-error').textContent='';refreshTimelineColors();
}
function applyTimelineColor(reset=false){
 if(!requireEditor())return false;
 if(inlineEditor){$('timeline-color-error').textContent='บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อนเปลี่ยนสี';return false}
 const color=reset?null:normalizeBarColor($('timeline-color-value').value);
 if(!reset&&!color){$('timeline-color-error').textContent='กรุณาเลือกสีให้ถูกต้อง';return false}
 const items=Array.from(timelineColorSelection.values());if(!items.length)return false;
 const records=items.map(item=>inlineRecord(item.kind,item.id));if(records.some(record=>!record)){$('timeline-color-error').textContent='รายการเปลี่ยนไป กรุณาเลือกแถบใหม่';return false}
 items.forEach((item,index)=>{const field=item.phase==='plan'?'planBarColor':'actualBarColor';if(reset)delete records[index][field];else records[index][field]=color});
 const count=items.length;clearTimelineColorSelection();changed();toast((reset?'คืนสีเริ่มต้นแล้ว ':'เปลี่ยนสีแล้ว ')+count+' แถบ · กดบันทึก HTML เพื่อเก็บลงไฟล์');return true;
}
$('tasks').addEventListener('click',event=>{const bar=event.target.closest('[data-bar-color-id]');if(!bar)return;event.preventDefault();event.stopImmediatePropagation();chooseTimelineColorBar(bar,event.ctrlKey||event.metaKey)},true);
$('tasks').addEventListener('keydown',event=>{const bar=event.target.closest('[data-bar-color-id]');if(bar&&['Enter',' '].includes(event.key)){event.preventDefault();event.stopImmediatePropagation();chooseTimelineColorBar(bar,event.ctrlKey||event.metaKey)}},true);
$('timeline-color-apply').onclick=()=>applyTimelineColor();$('timeline-color-reset').onclick=()=>applyTimelineColor(true);$('timeline-color-cancel').onclick=clearTimelineColorSelection;
$('timeline-color-presets').onclick=event=>{const button=event.target.closest('[data-timeline-color]');if(button)$('timeline-color-value').value=button.dataset.timelineColor};
document.addEventListener('keydown',event=>{if(event.key==='Escape'&&timelineColorSelection.size&&!document.querySelector('dialog[open]')){event.preventDefault();clearTimelineColorSelection()}});
