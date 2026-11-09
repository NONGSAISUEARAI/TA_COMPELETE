const DATABASE_MODEL='project-product-work-v1';
function databaseHeaders(){return [...EXCEL_HEADERS,'Node Type','Task ID','Project ID','Product ID']}
function databaseGroup(record){return state.groups.find(g=>g.id===(record.groupId||record.id))||null}
function isDatabaseGroup(group){return group?.databaseModel===DATABASE_MODEL}
function databaseProduct(record){if(!isDatabaseGroup(databaseGroup(record))||state.groups.some(g=>g.id===record.id))return null;let task=state.tasks.find(t=>t.id===record.id)||record,seen=new Set();while(task.parentId){if(seen.has(task.id))return null;seen.add(task.id);task=state.tasks.find(t=>t.id===task.parentId);if(!task)return null}return task.nodeType==='section'?task:null}
function drawingFieldsFor(record){const group=databaseGroup(record),keys=['pjCode','projectWorks','drawingGroup','product'];if(isDatabaseGroup(group)){const product=databaseProduct(record);return{pjCode:group.pjCode||'',projectWorks:group.projectWorks||'',drawingGroup:product?.drawingGroup||'',product:product?.product||''}}
 const core={},chain=[],seen=new Set();let item=record;while(item&&!seen.has(item.id)){seen.add(item.id);chain.unshift(item);item=item.parentId?state.tasks.find(t=>t.id===item.parentId):null}if(group)chain.unshift(group);for(const r of chain){for(const k of keys)if(r[k])core[k]=r[k];if(!core.pjCode&&/^PJ\d{2}-\d+$/i.test(r.name||''))core.pjCode=r.name}return core;
}
function databaseWork(record){return isDatabaseGroup(databaseGroup(record))&&record.nodeType!=='section'&&Boolean(record.parentId)}
function databaseIdentity(record){const core=drawingFieldsFor(record);return[core.pjCode,core.projectWorks,core.drawingGroup,core.product,record.name].map(v=>String(v||'').normalize('NFC').trim())}
function excelExportRecords(groupId='all'){
 const all=scheduleTreeRecords(groupId);if(!state.groups.some(isDatabaseGroup))return all;
 const rows=all.filter(r=>!r.section);for(const r of rows)if(databaseIdentity(r.raw).some(v=>!v))throw Error('งาน '+r.raw.name+' ยังมีข้อมูล PJ / Project Works / Group Drawing / Product / Description ไม่ครบ');return rows;
}
function databaseCaption(record,main){const core=drawingFieldsFor(record);return main?core.projectWorks:record.nodeType==='section'?core.drawingGroup:''}
function setDatabaseFieldState(prefix,raw,group,level){
 const db=isDatabaseGroup(group);for(const key of ['pjCode','projectWorks','drawingGroup','product']){const input=$(prefix+'-'+key);input.readOnly=false;input.required=false;input.closest('label').hidden=false}
 $(prefix+'-name').closest('label').hidden=false;$(prefix+'-area').closest('label').hidden=false;if(prefix==='f')$('f-area').required=!db;
 if(!db)return;const core=drawingFieldsFor(raw);for(const key of ['pjCode','projectWorks']){const input=$(prefix+'-'+key);input.value=group[key]||'';input.readOnly=true}
 if(prefix==='f'){
  const product=level==='work'?state.tasks.find(t=>t.id===$('f-parent').value):raw;
  for(const key of ['drawingGroup','product']){const input=$('f-'+key);input.readOnly=level==='work';input.required=level==='product';if(level==='work')input.value=product?.[key]||''}
  $('f-name').closest('label').hidden=level==='product';$('f-name').required=level==='work';$('f-area').closest('label').hidden=true;
  if(level==='product'){$('f-name').value=$('f-product').value.trim();$('f-area').value=$('f-product').value.trim()}else $('f-area').value=product?.product||'';
 }
}
function configureDatabaseTaskForm(raw=null){
 const group=state.groups.find(g=>g.id===$('f-group').value),db=isDatabaseGroup(group);$('f-db-level-field').hidden=!db;if(!db){setDatabaseFieldState('f',raw||{},group,null);$('parent-field').hidden=false;return}
 const existing=editingId?state.tasks.find(t=>t.id===editingId):null,level=existing?(existing.parentId?'work':'product'):raw?(raw.parentId?'work':'product'):$('f-db-level').value||'product';$('f-db-level').value=level;$('f-db-level').disabled=Boolean(existing);
 if(level==='product'){$('f-parent').value='';$('parent-field').hidden=true;if(raw){$('f-product').value=raw.product||raw.name||'';$('f-drawingGroup').value=raw.drawingGroup||'กลุ่มงานฝ้า'}}else{const products=state.tasks.filter(t=>t.groupId===group.id&&!t.parentId&&t.nodeType==='section');if(!products.some(t=>t.id===$('f-parent').value))$('f-parent').value=products[0]?.id||'';$('parent-field').hidden=false}
 setDatabaseFieldState('f',existing||raw||{},group,level);$('dialog-title').textContent=(existing?'แก้ไข ':'เพิ่ม ')+(level==='product'?'LV2 · Product / Group Drawing':'LV3 · Description / PLAN–ACTUAL');syncParentTrigger();updateTaskOutline();
}
function renderDatabaseParentPicker(){const group=state.groups.find(g=>g.id===$('f-group').value),query=$('parent-search').value.toLowerCase().trim(),products=state.tasks.filter(t=>t.groupId===group.id&&!t.parentId&&t.nodeType==='section').filter(t=>!query||[t.product,t.drawingGroup,t.name].some(v=>String(v||'').toLowerCase().includes(query))),paths=taskPaths();$('parent-options').innerHTML=products.map((t,i)=>'<button type="button" class="parent-option" role="treeitem" aria-level="2" aria-selected="'+($('f-parent').value===t.id)+'" tabindex="-1" data-parent-pick="'+escapeHTML(t.id)+'" style="--tree-depth:1">'+treeGuides(1,[],i===products.length-1,false,21)+'<span class="picker-code">'+escapeHTML(paths.get(t.id)||'')+'</span><span class="picker-name">'+escapeHTML(t.product+' / '+t.drawingGroup)+'</span></button>').join('')||'<p class="parent-picker-empty">เพิ่ม Product ระดับ LV2 ก่อนเพิ่มงาน</p>'}
function prepareDatabaseTaskValues(values){const group=state.groups.find(g=>g.id===values.groupId);if(!isDatabaseGroup(group))return;const current=editingId?state.tasks.find(t=>t.id===editingId):null,level=current?(current.parentId?'work':'product'):$('f-db-level').value;
 if(!group.pjCode||!group.projectWorks)throw Error('กรอก PJ และ Project Works ที่ LV1 ให้ครบก่อน');
 if(level==='product'){values.parentId=null;values.nodeType='section';values.drawingGroup=values.drawingGroup.trim();values.product=values.product.trim();if(!values.drawingGroup||!values.product)throw Error('LV2 ต้องมี Group Drawing และ Product');if(state.tasks.some(t=>t.id!==editingId&&t.groupId===group.id&&!t.parentId&&t.drawingGroup===values.drawingGroup&&t.product===values.product))throw Error('Product และ Group Drawing คู่นี้มีอยู่แล้ว');values.name=values.product;values.area=values.product;values.progress=current?summarizeTask(current).progress:null;if(!current){values.dateMode=values.start||values.end?'manual':'auto';values.planStart=nextWorkingDay(values.start)||null;values.planEnd=nextWorkingDay(values.end)||null}}
 else{const product=state.tasks.find(t=>t.id===values.parentId&&t.groupId===group.id&&!t.parentId&&t.nodeType==='section');if(!product||!product.product||!product.drawingGroup)throw Error('เลือก Product ระดับ LV2 ที่มีข้อมูลครบ');if(!values.name)throw Error('LV3 ต้องมี Description');values.nodeType='task';values.area=product.product;delete values.product;delete values.drawingGroup}
 delete values.pjCode;delete values.projectWorks;
}
function configureDatabaseGroupForm(raw){const db=!editingGroupId||isDatabaseGroup(raw);$('group-parent-field').hidden=db;for(const key of ['drawingGroup','product'])$('g-'+key).closest('label').hidden=db;$('g-name').closest('label').hidden=db;$('g-area').closest('label').hidden=db;for(const key of ['pjCode','projectWorks']){$('g-'+key).readOnly=false;$('g-'+key).required=db}if(db){$('g-parent-target').value='';$('g-name').value=$('g-pjCode').value;$('group-dialog-title').textContent=editingGroupId?'แก้ไข LV1 · PJ / Project Works':'เพิ่ม LV1 · PJ / Project Works'}}
function prepareDatabaseGroupValues(values){const old=state.groups.find(g=>g.id===editingGroupId);if(old&&!isDatabaseGroup(old))return;if($('g-parent-target').value)throw Error('โครงการ LV1 ต้องอยู่ระดับบนสุด');if(!values.pjCode||!values.projectWorks)throw Error('LV1 ต้องมี PJ และ Project Works');if(state.groups.some(g=>g.id!==editingGroupId&&isDatabaseGroup(g)&&g.pjCode===values.pjCode))throw Error('รหัส PJ นี้มีอยู่แล้ว');values.name=values.pjCode;values.databaseModel=DATABASE_MODEL;delete values.drawingGroup;delete values.product}
