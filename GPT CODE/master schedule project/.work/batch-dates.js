const BATCH_DATE_FIELDS=['start','end','actualStart','actualEnd'];
let batchDateSelection=new Map(),batchDateAnchor=null,batchDateKind=null;
function batchDateKey(kind,id){return kind+':'+id}
function batchDateLevel(item){const record=inlineRecord(item.kind,item.id);return item.kind==='group'?1:databaseLevel(record)||taskPaths().get(item.id)?.split('.').length||0}
function batchDateItems(){return Array.from(batchDateSelection.values()).filter(item=>inlineRecord(item.kind,item.id))}
function cancelBatchDates(){batchDateSelection.clear();batchDateAnchor=null;batchDateKind=null;$('batch-date-error').textContent='';refreshBatchDateUI()}
function refreshBatchDateUI(rebuildList=true){
 if(!isEditor){batchDateSelection.clear();batchDateAnchor=null;batchDateKind=null}
 for(const [key,item]of batchDateSelection)if(!inlineRecord(item.kind,item.id))batchDateSelection.delete(key);
 const items=batchDateItems(),keys=new Set(items.map(item=>batchDateKey(item.kind,item.id)));
 $('batch-date-panel').hidden=!items.length;
 document.querySelectorAll('[data-inline-field]').forEach(cell=>{
  const field=cell.dataset.inlineField,selected=keys.has(batchDateKey(cell.dataset.inlineKind,cell.dataset.inlineId))&&BATCH_DATE_FIELDS.includes(field)&&(field.startsWith('actual')?'actual':'plan')===batchDateKind;
  cell.classList.toggle('batch-date-selected',selected);
 });
 if(!items.length)return;
 $('batch-date-title').textContent='แก้วันที่ '+(batchDateKind==='actual'?'Actual':'Plan')+' พร้อมกัน · '+items.length+' รายการ';
 const paths=taskPaths();if(rebuildList)$('batch-date-list').innerHTML=items.map(item=>{const record=inlineRecord(item.kind,item.id),code=item.kind==='group'?String(state.groups.findIndex(g=>g.id===item.id)+1):paths.get(item.id)||'';return '<label><input type="checkbox" checked data-batch-key="'+escapeHTML(batchDateKey(item.kind,item.id))+'">'+escapeHTML(code+' · '+record.name)+'</label>'}).join('');
}
function selectBatchDateCell(cell){
 if(!requireEditor())return;
 const field=cell.dataset.inlineField;if(!BATCH_DATE_FIELDS.includes(field))return;
 const kind=field.startsWith('actual')?'actual':'plan',target={kind:cell.dataset.inlineKind,id:cell.dataset.inlineId};
 if(batchDateKind&&batchDateKind!==kind){toast('เลือก Plan หรือ Actual เป็นชุดเดียวกัน · ยกเลิกชุดเดิมก่อนเปลี่ยน');return}
 if(inlineEditor){if(inlineEditor.input.value!==inlineEditor.initialValue){toast('บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อนเลือกหลายแถว');return}cancelInlineEdit()}
 const first=!batchDateSelection.size;
 if(first){batchDateKind=kind;$('batch-date-use-start').checked=field==='start'||field==='actualStart';$('batch-date-use-end').checked=!$('batch-date-use-start').checked;
  const record=inlineRecord(target.kind,target.id),view=target.kind==='group'?summarizeGroup(record):summarizeTask(record);$('batch-date-start').value=view[kind==='actual'?'actualStart':'start']||'';$('batch-date-end').value=view[kind==='actual'?'actualEnd':'end']||'';
 }
 const anchor=batchDateAnchor&&batchDateAnchor.dateKind===kind?batchDateAnchor:target,level=batchDateLevel(anchor),targetLevel=batchDateLevel(target);
 const visible=Array.from($('tasks').querySelectorAll('tr[data-task],tr[data-group]')).map(row=>({kind:row.dataset.group?'group':'task',id:row.dataset.group||row.dataset.task}));
 const a=visible.findIndex(item=>item.kind===anchor.kind&&item.id===anchor.id),b=visible.findIndex(item=>item.kind===target.kind&&item.id===target.id);
 if(a>=0&&b>=0&&level===targetLevel){for(const item of visible.slice(Math.min(a,b),Math.max(a,b)+1))if(batchDateLevel(item)===level)batchDateSelection.set(batchDateKey(item.kind,item.id),item)}
 else batchDateSelection.set(batchDateKey(target.kind,target.id),target);
 batchDateAnchor={...target,dateKind:kind};
 if(field==='start'||field==='actualStart')$('batch-date-use-start').checked=true;else $('batch-date-use-end').checked=true;
 $('batch-date-error').textContent='';refreshBatchDateUI();
}
function prepareBatchDateUpdate(item,useStart,startText,useEnd,endText){
 const record=inlineRecord(item.kind,item.id);if(!record)throw Error('ไม่พบรายการที่เลือก');
 const actual=batchDateKind==='actual',view=item.kind==='group'?summarizeGroup(record):summarizeTask(record),first=actual?'actualStart':'start',last=actual?'actualEnd':'end';
 const start=useStart?nextWorkingDay(startText):view[first]||null,end=useEnd?nextWorkingDay(endText):view[last]||null;
 if(start&&end&&end<start)throw Error(record.name+': วันจบต้องไม่อยู่ก่อนวันเริ่ม');
 if(start&&end&&dateNumber(end)-dateNumber(start)>DAY*366*10)throw Error(record.name+': ช่วงวันต้องไม่เกิน 10 ปี');
 let values={};
 if(inlineSummary(item.kind,record))values=actual?{actualDateMode:'manual',actualStart:start,actualEnd:end}:{dateMode:'manual',planStart:start,planEnd:end};
 else{if(useStart)values[first]=start;if(useEnd)values[last]=end}
 return {record,values};
}
function applyBatchDates(){
 if(!requireEditor())return false;
 const useStart=$('batch-date-use-start').checked,useEnd=$('batch-date-use-end').checked,start=$('batch-date-start').value,end=$('batch-date-end').value,items=batchDateItems();
 try{
  if(inlineEditor)throw Error('บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อน');
  if(!items.length)throw Error('กรุณาเลือกรายการก่อน');
  if(!useStart&&!useEnd)throw Error('เลือกวันเริ่มหรือวันจบที่ต้องการแก้');
  if((useStart&&(!start||!validRecordDate(start)))||(useEnd&&(!end||!validRecordDate(end))))throw Error('กรอกวันที่ที่เลือกให้ครบและถูกต้อง');
  // Validate the entire set before changing any record, including both dates at once.
  const updates=items.map(item=>prepareBatchDateUpdate(item,useStart,start,useEnd,end));
  for(const update of updates)Object.assign(update.record,update.values);
  const count=updates.length;cancelBatchDates();changed();toast('แก้วันที่แล้ว '+count+' รายการ · กดบันทึก HTML เพื่อเก็บลงไฟล์');return true;
 }catch(error){$('batch-date-error').textContent=error.message;return false}
}
$('tasks').addEventListener('mousedown',event=>{const cell=event.target.closest('[data-inline-field]');if(event.shiftKey&&cell&&BATCH_DATE_FIELDS.includes(cell.dataset.inlineField)&&!event.target.closest('input,button'))event.preventDefault()},true);
$('tasks').addEventListener('click',event=>{
 const cell=event.target.closest('[data-inline-field]');if(!cell||!BATCH_DATE_FIELDS.includes(cell.dataset.inlineField)||event.target.closest('input,button'))return;
 if(event.shiftKey){event.preventDefault();event.stopImmediatePropagation();window.getSelection?.()?.removeAllRanges();selectBatchDateCell(cell)}
 else if(isEditor&&!batchDateSelection.size)batchDateAnchor={kind:cell.dataset.inlineKind,id:cell.dataset.inlineId,dateKind:cell.dataset.inlineField.startsWith('actual')?'actual':'plan'};
},true);
$('tasks').addEventListener('keydown',event=>{const cell=event.target.closest('[data-inline-field]');if(event.shiftKey&&['Enter',' '].includes(event.key)&&cell&&BATCH_DATE_FIELDS.includes(cell.dataset.inlineField)&&!event.target.matches('input,button')){event.preventDefault();event.stopImmediatePropagation();selectBatchDateCell(cell)}},true);
$('batch-date-list').addEventListener('change',event=>{const input=event.target.closest('[data-batch-key]');if(!input)return;const key=input.dataset.batchKey,separator=key.indexOf(':'),item={kind:key.slice(0,separator),id:key.slice(separator+1)};if(input.checked&&inlineRecord(item.kind,item.id))batchDateSelection.set(key,item);else batchDateSelection.delete(key);if(!batchDateSelection.size){cancelBatchDates();return}refreshBatchDateUI(false)});
$('batch-date-apply').onclick=applyBatchDates;$('batch-date-cancel').onclick=cancelBatchDates;
document.addEventListener('keydown',event=>{if(event.key==='Escape'&&batchDateSelection.size&&!inlineEditor&&!document.querySelector('dialog[open]')){event.preventDefault();cancelBatchDates()}});
