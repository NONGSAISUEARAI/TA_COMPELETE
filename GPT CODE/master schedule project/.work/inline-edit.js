// Inline editing uses the same state, draft, summary and save pipeline as forms.
const INLINE_FIELDS={currentInfo:['ข้อมูลปัจจุบัน','text'],owner:['ผู้รับผิดชอบ','text'],unit:['Unit','text'],quantity:['Quantity','number'],workStatus:['สถานะที่ระบุ','text'],action:['Action','text'],approvedDate:['วันที่อนุมัติ','date'],remark:['Remark','text'],progress:['ผลงาน (%)','number'],start:['Plan · วันเริ่ม','date'],end:['Plan · วันจบ','date'],actualStart:['Actual · วันเริ่ม','date'],actualEnd:['Actual · วันจบ','date']};
let inlineEditor=null;
function inlineRecord(kind,id){return(kind==='group'?state.groups:state.tasks).find(t=>t.id===id)}
function inlineSummary(kind,record){return kind==='group'||record.nodeType==='section'||taskChildren(record.id).length>0}
function inlineAttributes(kind,id,field){return ' data-inline-kind="'+kind+'" data-inline-id="'+escapeHTML(id)+'" data-inline-field="'+field+'" tabindex="-1" title="แตะเพื่อแก้ไข '+INLINE_FIELDS[field][0]+'"'}
function inlineRowMarkup(html,record,main){
 const kind=main?'group':'task';
 for(const field of ['currentInfo','owner','unit','quantity','workStatus','action','approvedDate','remark','progress']){
  if(field==='progress'&&inlineSummary(kind,record))continue;
  html=html.replace(new RegExp('<td class="([^"]*\\bcol-'+field+'\\b[^"]*)">'),(_,classes)=>'<td class="'+classes+' inline-cell"'+inlineAttributes(kind,record.id,field)+'>');
 }
 for(const [column,fields]of [['startDates',['start','actualStart']],['endDates',['end','actualEnd']]]){
  const pattern=new RegExp('(<td class="[^"]*col-'+column+'[^>]*>)([\\s\\S]*?)(</td>)');
  html=html.replace(pattern,(_,open,body,close)=>open+body.replace(/<div class="date-line date-line-(plan|actual)"/g,(_,type)=>'<div class="date-line date-line-'+type+' inline-cell"'+inlineAttributes(kind,record.id,fields[type==='plan'?0:1]))+close);
 }
 return html;
}
function refreshInlineRole(){document.querySelectorAll('[data-inline-field]').forEach(cell=>{cell.tabIndex=isEditor?0:-1;cell.setAttribute('role',isEditor?'button':'cell')})}
function cancelInlineEdit(restore=true){const active=inlineEditor;inlineEditor=null;if(active)active.cell.closest('.date-stack')?.classList.remove('inline-date-stack');if(active&&restore){active.cell.innerHTML=active.html;active.cell.classList.remove('inline-editing');active.cell.focus({preventScroll:true})}}
function inlineUpdate(kind,id,field,text){
 if(!isEditor)throw Error('กรุณาปลดล็อก Editor ก่อนแก้ไข');
 const record=inlineRecord(kind,id);if(!record||!INLINE_FIELDS[field])throw Error('ไม่พบช่องข้อมูล');
 const summary=inlineSummary(kind,record),view=kind==='group'?summarizeGroup(record):summarizeTask(record),next={};
 text=String(text).trim();
 if(field==='progress'){
  if(summary)throw Error('ผลงานหัวข้อแม่คำนวณจากงานย่อย');
  if(text!==''&&(!Number.isInteger(Number(text))||Number(text)<0||Number(text)>100))throw Error('ผลงานต้องเป็นจำนวนเต็มระหว่าง 0–100');
  next.progress=text===''?null:Number(text);
 }else if(field==='quantity'){
  if(text!==''&&(!Number.isFinite(Number(text))||Number(text)<0))throw Error('Quantity ต้องเป็นจำนวนตั้งแต่ 0 ขึ้นไป');
  next.quantity=text===''?null:Number(text);
 }else if(INLINE_FIELDS[field][1]==='date'){
  let value=text||null;if(!validRecordDate(value))throw Error('วันที่ไม่ถูกต้อง');
  if(field==='approvedDate')next[field]=value;
  else{
   value=nextWorkingDay(value);const actual=field.startsWith('actual'),first=actual?'actualStart':'start',last=actual?'actualEnd':'end';
   const start=field===first?value:view[first]||null,end=field===last?value:view[last]||null;
   if(start&&end&&end<start)throw Error('วันจบต้องไม่อยู่ก่อนวันเริ่ม');
   if(start&&end&&dateNumber(end)-dateNumber(start)>DAY*366*10)throw Error('ช่วงวันต้องไม่เกิน 10 ปี');
   if(summary&&!actual)Object.assign(next,{dateMode:'manual',planStart:start,planEnd:end});
   else if(summary&&actual)Object.assign(next,{actualDateMode:'manual',actualStart:start,actualEnd:end});
   else next[field]=value;
  }
 }else{
  if(text.length>(field==='owner'?80:2000))throw Error('ข้อความยาวเกินกำหนด');next[field]=text;
 }
 Object.assign(record,next);return next;
}
function commitInlineEdit(){
 const active=inlineEditor;if(!active)return true;
 try{inlineUpdate(active.kind,active.id,active.field,active.input.value)}catch(error){active.error.textContent=error.message;active.input.setAttribute('aria-invalid','true');active.input.focus();return false}
 cancelInlineEdit(false);changed();toast('บันทึกช่องข้อมูลแล้ว · กดบันทึก HTML เพื่อเก็บลงไฟล์');return true;
}
function openInlineEdit(cell){
 if(!isEditor)return;if(inlineEditor?.cell===cell)return;
 // Keep the current draft visible until saved or explicitly cancelled.
 if(inlineEditor){inlineEditor.error.textContent='บันทึกหรือยกเลิกช่องนี้ก่อนแก้ช่องอื่น';inlineEditor.input.focus();return}
 const {inlineKind:kind,inlineId:id,inlineField:field}=cell.dataset,record=inlineRecord(kind,id);if(!record||!INLINE_FIELDS[field])return;
 const view=kind==='group'?summarizeGroup(record):summarizeTask(record),[label,type]=INLINE_FIELDS[field],value=type==='date'?view[field]:record[field];
 const html=cell.innerHTML;cell.classList.add('inline-editing');cell.closest('.date-stack')?.classList.add('inline-date-stack');
 cell.innerHTML='<div class="inline-editor"><input aria-label="'+label+'" type="'+type+'" '+(field==='progress'?'min="0" max="100" step="1"':field==='quantity'?'min="0" step="any"':'')+'><div class="inline-editor-actions"><button type="button" data-inline-save aria-label="บันทึก '+label+'">✓</button><button type="button" data-inline-cancel aria-label="ยกเลิกแก้ไข">×</button></div><small class="inline-error" role="alert"></small></div>';
 const input=cell.querySelector('input');input.value=value??'';inlineEditor={cell,html,kind,id,field,input,error:cell.querySelector('.inline-error')};input.focus({preventScroll:true});if(type==='text')input.select();
}
$('tasks').addEventListener('click',event=>{
 const cell=event.target.closest('[data-inline-field]');if(!cell)return;
 if(event.target.closest('[data-inline-save]')){commitInlineEdit();return}
 if(event.target.closest('[data-inline-cancel]')){cancelInlineEdit();return}
 openInlineEdit(cell);
});
$('tasks').addEventListener('keydown',event=>{
 if(inlineEditor&&inlineEditor.cell.contains(event.target)){
  if(event.key==='Escape'){event.preventDefault();event.stopPropagation();cancelInlineEdit()}
  else if(event.key==='Enter'&&event.target===inlineEditor.input){event.preventDefault();commitInlineEdit()}return;
 }
 if((event.key==='Enter'||event.key===' ')&&event.target.matches('[data-inline-field]')){event.preventDefault();openInlineEdit(event.target)}
});

