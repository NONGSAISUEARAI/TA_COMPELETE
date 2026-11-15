function clipboardDateValue(value){
 const text=String(value).trim();if(!text||text==='—'||text==='-')return null;
 let iso=text,match=text.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$/);
 if(match){let year=Number(match[3]);if(year>=2400)year-=543;iso=String(year).padStart(4,'0')+'-'+match[2].padStart(2,'0')+'-'+match[1].padStart(2,'0')}
 if(!validRecordDate(iso))throw Error('วันที่ไม่ถูกต้อง: '+text+' · ใช้ YYYY-MM-DD หรือ DD/MM/YYYY');return iso;
}
function readDateClipboard(text){
 if(typeof text!=='string'||!text.trim())throw Error('ไม่มีวันที่ให้วาง');
 const lines=text.replace(/^\uFEFF/,'').replace(/\r\n?/g,'\n').replace(/\n+$/,'').split('\n');
 if(lines.length>2000)throw Error('วางวันที่ได้ครั้งละไม่เกิน 2,000 แถว');
 const rows=lines.map(line=>line.split('\t').map(clipboardDateValue)),columns=rows[0].length;
 if(columns>2||rows.some(row=>row.length!==columns))throw Error('วางได้ 1 คอลัมน์วันที่ หรือ 2 คอลัมน์ Start / End ที่มีจำนวนช่องเท่ากัน');
 return rows;
}
function orderedDateItems(items){const paths=taskPaths(),code=item=>item.kind==='group'?String(state.groups.findIndex(g=>g.id===item.id)+1):paths.get(item.id)||'';return [...items].sort((a,b)=>code(a).localeCompare(code(b),undefined,{numeric:true}))}
function dateClipboardSelection(target,field){
 const kind=field.startsWith('actual')?'actual':'plan';
 return batchDateKind===kind&&batchDateSelection.has(batchDateKey(target.kind,target.id))?orderedDateItems(batchDateItems()):[];
}
function visibleDateTargets(target,count){
 const rows=Array.from($('tasks').querySelectorAll('tr[data-task],tr[data-group]')).map(row=>({kind:row.dataset.group?'group':'task',id:row.dataset.group||row.dataset.task})),level=batchDateLevel(target),index=rows.findIndex(item=>item.kind===target.kind&&item.id===target.id);
 if(index<0)throw Error('ไม่พบแถวปลายทาง');return rows.slice(index).filter(item=>batchDateLevel(item)===level).slice(0,count);
}
function dateCopyText(target,field){
 if(!BATCH_DATE_FIELDS.includes(field))throw Error('เลือกช่อง Start หรือ End ก่อน');
 const selected=dateClipboardSelection(target,field),actual=field.startsWith('actual'),fields=selected.length?[$('batch-date-use-start').checked?(actual?'actualStart':'start'):null,$('batch-date-use-end').checked?(actual?'actualEnd':'end'):null].filter(Boolean):[field];
 if(!fields.length)throw Error('เลือกวันเริ่มหรือวันจบที่จะคัดลอก');
 return (selected.length?selected:[target]).map(item=>{const record=inlineRecord(item.kind,item.id);if(!record)throw Error('ไม่พบรายการที่เลือก');const view=item.kind==='group'?summarizeGroup(record):summarizeTask(record);return fields.map(key=>!selected.length&&inlineEditor?.cell.dataset.inlineField===key&&inlineEditor.id===item.id?inlineEditor.input.value:view[key]||'').join('\t')}).join('\n');
}
function datePastePlan(target,field,text,explicitTargets=null){
 if(!isEditor)throw Error('กรุณาปลดล็อก Editor ก่อนวางวันที่');
 if(!BATCH_DATE_FIELDS.includes(field))throw Error('เลือกช่อง Start หรือ End ก่อน');
 const rows=readDateClipboard(text),columns=rows[0].length,actual=field.startsWith('actual'),selected=explicitTargets||dateClipboardSelection(target,field);
 if(columns===2&&(field==='end'||field==='actualEnd')&&!(selected.length&&$('batch-date-use-start').checked&&$('batch-date-use-end').checked))throw Error('วางวันที่ 2 คอลัมน์ที่ช่อง Start เพื่อใช้ Start / End พร้อมกัน');
 const targets=selected.length?selected:rows.length===1?[target]:visibleDateTargets(target,rows.length);
 if(rows.length!==1&&rows.length!==targets.length)throw Error('จำนวนแถววันที่ไม่ตรงกับรายการปลายทาง ('+rows.length+' / '+targets.length+')');
 return targets.map((item,index)=>{
  const record=inlineRecord(item.kind,item.id);if(!record)throw Error('ไม่พบรายการปลายทาง');
  const view=item.kind==='group'?summarizeGroup(record):summarizeTask(record),row=rows[rows.length===1?0:index],useStart=columns===2||field==='start'||field==='actualStart',useEnd=columns===2||!useStart,first=actual?'actualStart':'start',last=actual?'actualEnd':'end';
  const start=useStart?nextWorkingDay(row[0]):view[first]||null,end=useEnd?nextWorkingDay(row[columns===2?1:0]):view[last]||null;
  if(start&&end&&end<start)throw Error(record.name+': วันจบต้องไม่อยู่ก่อนวันเริ่ม');
  if(start&&end&&dateNumber(end)-dateNumber(start)>DAY*366*10)throw Error(record.name+': ช่วงวันต้องไม่เกิน 10 ปี');
  let values={};if(inlineSummary(item.kind,record))values=actual?{actualDateMode:'manual',actualStart:start,actualEnd:end}:{dateMode:'manual',planStart:start,planEnd:end};else{if(useStart)values[first]=start;if(useEnd)values[last]=end}
  return {record,values};
 });
}
function pasteScheduleDates(target,field,text){
 try{
  if(inlineEditor&&inlineEditor.input.value!==inlineEditor.initialValue)throw Error('บันทึกหรือยกเลิกช่องที่กำลังแก้ก่อนวางวันที่');
  const updates=datePastePlan(target,field,text);
  cancelInlineEdit();for(const update of updates)Object.assign(update.record,update.values);
  cancelBatchDates();changed();toast('วางวันที่แล้ว '+updates.length+' รายการ · กดบันทึก HTML เพื่อเก็บลงไฟล์');return true;
 }catch(error){if(batchDateSelection.size)$('batch-date-error').textContent=error.message;else if(inlineEditor)inlineEditor.error.textContent=error.message;toast(error.message);return false}
}
for(const action of ['copy','paste'])$('tasks').addEventListener(action,event=>{
 const cell=event.target.closest('[data-inline-field]');if(!cell||!BATCH_DATE_FIELDS.includes(cell.dataset.inlineField)||!event.clipboardData)return;
 const target={kind:cell.dataset.inlineKind,id:cell.dataset.inlineId},field=cell.dataset.inlineField;
 event.preventDefault();event.stopPropagation();
 if(action==='copy'){try{event.clipboardData.setData('text/plain',dateCopyText(target,field));toast('คัดลอกวันที่แล้ว · เลือก Start/End ปลายทางแล้วกด Ctrl+V')}catch(error){toast(error.message)}}
 else pasteScheduleDates(target,field,event.clipboardData.getData('text/plain'));
},true);
