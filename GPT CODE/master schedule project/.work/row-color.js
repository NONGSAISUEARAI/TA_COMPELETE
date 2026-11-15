let rowColorSelection=new Map();
function rowColorInk(color){const c=normalizeBarColor(color);if(!c)return '#d7e5ec';const rgb=[1,3,5].map(i=>parseInt(c.slice(i,i+2),16));return rgb[0]*.299+rgb[1]*.587+rgb[2]*.114>155?'#15272d':'#e3edf2'}
function clearRowColorSelection(){rowColorSelection.clear();refreshRowColors()}
function refreshRowColors(){
 if(!isEditor)rowColorSelection.clear();for(const [key,item]of rowColorSelection)if(!inlineRecord(item.kind,item.id))rowColorSelection.delete(key);
 $('row-color-panel').hidden=!rowColorSelection.size;$('row-color-title').textContent='สีพื้นหลังแถวงาน · '+rowColorSelection.size+' รายการ';
 document.querySelectorAll('#tasks>tr[data-task],#tasks>tr[data-group]').forEach(row=>{const kind=row.dataset.group?'group':'task',id=row.dataset.group||row.dataset.task;row.classList.toggle('row-color-selected',rowColorSelection.has(kind+':'+id))});
}
function chooseRowColor(kind,id,multiple=false){
 if(!requireEditor())return;
 if(inlineEditor){if(inlineEditor.input.value!==inlineEditor.initialValue){toast('บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อนเลือกสีแถว');return}cancelInlineEdit()}
 const record=inlineRecord(kind,id);if(!record)return;const had=rowColorSelection.size>0;if(!multiple)rowColorSelection.clear();const key=kind+':'+id;
 if(multiple&&rowColorSelection.has(key))rowColorSelection.delete(key);else rowColorSelection.set(key,{kind,id});
 if(!had||!multiple)$('row-color-value').value=normalizeBarColor(record.rowColor)||'#24464c';
 cancelBatchDates();clearTimelineColorSelection();$('row-color-error').textContent='';refreshRowColors();
}
function applyRowColor(reset=false){
 if(!requireEditor())return false;if(inlineEditor){$('row-color-error').textContent='บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อน';return false}
 const color=reset?null:normalizeBarColor($('row-color-value').value);if(!reset&&!color){$('row-color-error').textContent='กรุณาเลือกสีให้ถูกต้อง';return false}
 const items=[...rowColorSelection.values()],records=items.map(item=>inlineRecord(item.kind,item.id));if(!items.length)return false;if(records.some(record=>!record)){$('row-color-error').textContent='รายการเปลี่ยนไป กรุณาเลือกใหม่';return false}
 for(const record of records)if(reset)delete record.rowColor;else record.rowColor=color;
 const count=records.length;clearRowColorSelection();changed();toast((reset?'คืนสีพื้นหลังเดิมแล้ว ':'เปลี่ยนสีพื้นหลังแล้ว ')+count+' แถว · กดบันทึก HTML เพื่อเก็บลงไฟล์');return true;
}
$('tasks').addEventListener('click',event=>{
 const cell=event.target.closest('.col-name,.col-wbs');if(!cell)return;
 if(event.target.closest('[data-reorder-id],.group-arrow,.task-files-disclosure,.task-files-body,[data-task-files],a,input,select,textarea'))return;
 const button=event.target.closest('button');if(button&&!button.matches('[data-row-color-id]'))return;
 const row=cell.closest('tr[data-task],tr[data-group]');if(!row)return;event.preventDefault();event.stopImmediatePropagation();chooseRowColor(row.dataset.group?'group':'task',row.dataset.group||row.dataset.task,event.ctrlKey||event.metaKey);
},true);
$('tasks').addEventListener('keydown',event=>{const button=event.target.closest('[data-row-color-id]');if(button&&['Enter',' '].includes(event.key)){event.preventDefault();event.stopImmediatePropagation();chooseRowColor(button.dataset.rowColorKind,button.dataset.rowColorId,event.ctrlKey||event.metaKey)}},true);
$('row-color-apply').onclick=()=>applyRowColor();$('row-color-reset').onclick=()=>applyRowColor(true);$('row-color-cancel').onclick=clearRowColorSelection;
$('row-color-presets').onclick=event=>{const button=event.target.closest('[data-row-preset]');if(button)$('row-color-value').value=button.dataset.rowPreset};
document.addEventListener('keydown',event=>{if(event.key==='Escape'&&rowColorSelection.size&&!document.querySelector('dialog[open]')){event.preventDefault();clearRowColorSelection()}});
