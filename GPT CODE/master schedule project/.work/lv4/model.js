// Levels are derived from parent links; existing IDs and task records stay intact.
function databaseLevel(record){
 if(!record||!isDatabaseGroup(databaseGroup(record)))return 0;
 if(state.groups.some(g=>g.id===record.id))return 1;
 let depth=2,item=record,seen=new Set();
 while(item.parentId){if(seen.has(item.id))return 0;seen.add(item.id);item=state.tasks.find(t=>t.id===item.parentId);if(!item||item.groupId!==record.groupId)return 0;depth++}
 return depth;
}
function databaseDescription(record){const level=databaseLevel(record);return level===3?record:level===4?state.tasks.find(t=>t.id===record.parentId)||null:null}
function databaseActivityName(record){return databaseLevel(record)===4?record.name||'':''}
function databaseLevelName(record){return({1:'LV1 · PJ / Project Works',2:'LV2 · Product / Group Drawing',3:'LV3 · Description',4:'LV4 · Activity'})[databaseLevel(record)]||''}
function databaseWork(record){return [3,4].includes(databaseLevel(record))&&!taskChildren(record.id).length}
function databaseIdentity(record){const core=drawingFieldsFor(record),description=databaseDescription(record);return[core.pjCode,core.projectWorks,core.drawingGroup,core.product,description?.name||record.name,databaseActivityName(record)].map(v=>String(v||'').normalize('NFC').trim())}
function databaseHeaders(){return [...EXCEL_HEADERS,'Node Type','Task ID','Project ID','Product ID','Activity','Description ID']}
function databaseCaption(record,main){if(main)return drawingFieldsFor(record).projectWorks;const level=databaseLevel(record);if(level===2)return 'LV2 · Product / Group Drawing';if(level===3){const count=taskChildren(record.id).length;return 'LV3 · Description'+(count?' · '+count+' Activity':'')}return level===4?'LV4 · Activity':''}
function preserveDescriptionDates(record){
 if(!record||databaseLevel(record)!==3||taskChildren(record.id).length)return;
 if(record.dateMode!=='manual'&&(record.start||record.end)){record.dateMode='manual';record.planStart=record.start||null;record.planEnd=record.end||null}
 if(record.actualDateMode!=='manual'&&(record.actualStart||record.actualEnd))record.actualDateMode='manual';
}
function databaseParentOptions(groupId,level){return state.tasks.filter(t=>t.groupId===groupId&&databaseLevel(t)===(level==='activity'?3:2))}
function setDatabaseFieldState(prefix,raw,group,level){
 const db=isDatabaseGroup(group);
 for(const key of ['pjCode','projectWorks','drawingGroup','product']){const input=$(prefix+'-'+key);input.readOnly=false;input.required=false;input.closest('label').hidden=false}
 $(prefix+'-name').closest('label').hidden=false;$(prefix+'-area').closest('label').hidden=false;
 if(prefix!=='f')return;
 $('f-area').required=!db;$('f-name').required=true;$('f-description-field').hidden=true;$('f-name-label').textContent='Description / ชื่องานย่อย';$('parent-field-label').textContent='อยู่ใต้งาน (เลือกได้หลายระดับ)';
 if(!db)return;
 for(const key of ['pjCode','projectWorks']){$('f-'+key).value=group[key]||'';$('f-'+key).readOnly=true}
 const parent=state.tasks.find(t=>t.id===$('f-parent').value),product=level==='product'?raw:databaseProduct(parent||{});
 for(const key of ['drawingGroup','product']){const input=$('f-'+key);input.readOnly=level!=='product';input.required=level==='product';if(level!=='product')input.value=product?.[key]||''}
 $('f-name').closest('label').hidden=level==='product';$('f-name').required=level!=='product';$('f-area').closest('label').hidden=true;
 $('f-name-label').textContent=level==='activity'?'Activity / ชื่อขั้นตอน':'Description / รายการงาน';
 $('parent-field-label').textContent=level==='activity'?'อยู่ใต้ Description':'อยู่ใต้ Product';
 if(level==='product'){$('f-name').value=$('f-product').value.trim();$('f-area').value=$('f-product').value.trim()}
 else $('f-area').value=product?.product||'';
 $('f-description-field').hidden=level!=='activity';$('f-description').value=level==='activity'?parent?.name||'':'';
}
function configureDatabaseTaskForm(raw=null){
 const group=state.groups.find(g=>g.id===$('f-group').value),db=isDatabaseGroup(group);$('f-db-level-field').hidden=!db;
 if(!db){setDatabaseFieldState('f',raw||{},group,null);$('parent-field').hidden=false;return}
 const existing=editingId?state.tasks.find(t=>t.id===editingId):null,record=existing||raw;
 const inferred=record?({2:'product',3:'work',4:'activity'})[databaseLevel(record)]:null,level=inferred||$('f-db-level').value||'product';
 $('f-db-level').value=level;$('f-db-level').disabled=Boolean(existing);
 if(level==='product'){$('f-parent').value='';$('parent-field').hidden=true;if(raw){$('f-product').value=raw.product||raw.name||'';$('f-drawingGroup').value=raw.drawingGroup||'กลุ่มงานฝ้า'}}
 else{const choices=databaseParentOptions(group.id,level);if(!choices.some(t=>t.id===$('f-parent').value))$('f-parent').value=choices[0]?.id||'';$('parent-field').hidden=false}
 setDatabaseFieldState('f',record||{},group,level);
 const labels={product:'LV2 · Product / Group Drawing',work:'LV3 · Description',activity:'LV4 · Activity'};
 $('dialog-title').textContent=(existing?'แก้ไข ':'เพิ่ม ')+labels[level]+(existing?' · '+(taskPaths().get(existing.id)||''):'');
 syncParentTrigger();updateTaskSummaryNote();updateTaskOutline();if(!$('parent-picker').hidden)renderDatabaseParentPicker();
}
function renderDatabaseParentPicker(){
 const group=state.groups.find(g=>g.id===$('f-group').value),level=$('f-db-level').value,query=$('parent-search').value.toLowerCase().trim(),paths=taskPaths(),excluded=editingId?descendantIds(editingId):new Set();if(editingId)excluded.add(editingId);
 const eligible=new Set(databaseParentOptions(group.id,level).filter(t=>!excluded.has(t.id)).map(t=>t.id));
 const matches=t=>!query||[t.name,t.product,t.drawingGroup,paths.get(t.id)].some(v=>String(v||'').toLowerCase().includes(query));
 const products=state.tasks.filter(t=>t.groupId===group.id&&databaseLevel(t)===2).map(t=>({record:t,children:level==='activity'?taskChildren(t.id).filter(c=>eligible.has(c.id)&&(matches(c)||matches(t))):[]})).filter(n=>level==='activity'?n.children.length:eligible.has(n.record.id)&&matches(n.record));
 let html='';
 function option(task,depth,ancestors,last,selectable,stem){const code=paths.get(task.id)||'',text=depth===1?task.product+' / '+task.drawingGroup:task.name,tag=selectable?'button':'div';html+='<'+tag+(selectable?' type="button" data-parent-pick="'+escapeHTML(task.id)+'" tabindex="-1"':' aria-disabled="true"')+' class="parent-option'+(selectable?'':' parent-option-context')+'" role="treeitem" aria-level="'+(depth+1)+'" aria-selected="'+($('f-parent').value===task.id)+'" style="--tree-depth:'+depth+'">'+treeGuides(depth,ancestors,last,stem,21)+'<span class="picker-code">'+escapeHTML(code)+'</span><span class="picker-name">'+escapeHTML(text)+'</span></'+tag+'>'}
 products.forEach((n,i)=>{const last=i===products.length-1;option(n.record,1,[],last,level!=='activity',n.children.length>0);n.children.forEach((t,j)=>option(t,2,[!last],j===n.children.length-1,true,false))});
 $('parent-options').innerHTML=html||'<p class="parent-picker-empty">'+(level==='activity'?'เพิ่ม Description ระดับ LV3 ก่อนเพิ่ม Activity':'เพิ่ม Product ระดับ LV2 ก่อนเพิ่ม Description')+'</p>';
}
function prepareDatabaseTaskValues(values){
 const group=state.groups.find(g=>g.id===values.groupId),current=editingId?state.tasks.find(t=>t.id===editingId):null;
 if(!isDatabaseGroup(group)){if(current&&isDatabaseGroup(databaseGroup(current)))throw Error('เลือกโครงการแบบ LV1–LV4 สำหรับงานนี้');return}
 if(current&&!isDatabaseGroup(databaseGroup(current)))throw Error('ย้ายงานเอกสารเดิมเข้าโครงการฐานข้อมูลไม่ได้ ให้เพิ่มหัวข้อใหม่');
 const level=current?({2:'product',3:'work',4:'activity'})[databaseLevel(current)]:$('f-db-level').value;
 if(!['product','work','activity'].includes(level))throw Error('ระดับงานไม่ถูกต้อง รองรับถึง LV4 · Activity');
 if(!group.pjCode||!group.projectWorks)throw Error('กรอก PJ และ Project Works ที่ LV1 ให้ครบก่อน');
 if(level==='product'){
  values.parentId=null;values.nodeType='section';values.drawingGroup=values.drawingGroup.trim();values.product=values.product.trim();
  if(!values.drawingGroup||!values.product)throw Error('LV2 ต้องมี Group Drawing และ Product');
  if(state.tasks.some(t=>t.id!==editingId&&t.groupId===group.id&&!t.parentId&&t.drawingGroup===values.drawingGroup&&t.product===values.product))throw Error('Product และ Group Drawing คู่นี้มีอยู่แล้ว');
  values.name=values.product;values.area=values.product;values.progress=current?summarizeTask(current).progress:null;
  if(!current){values.dateMode=values.start||values.end?'manual':'auto';values.planStart=nextWorkingDay(values.start)||null;values.planEnd=nextWorkingDay(values.end)||null}
 }else{
  const parent=state.tasks.find(t=>t.id===values.parentId&&t.groupId===group.id),expected=level==='activity'?3:2,product=databaseProduct(parent||{});
  if(!parent||databaseLevel(parent)!==expected||!product?.product||!product?.drawingGroup)throw Error(level==='activity'?'เลือก Description ระดับ LV3 ที่มีข้อมูลครบ':'เลือก Product ระดับ LV2 ที่มีข้อมูลครบ');
  if(!values.name)throw Error(level==='activity'?'LV4 ต้องมีชื่อ Activity':'LV3 ต้องมี Description');
  values.nodeType='task';values.area=product.product;delete values.product;delete values.drawingGroup;
 }
 delete values.pjCode;delete values.projectWorks;
}
