function readScheduleCSV(text){
 let normalized=text,header=[],transientCodes=new Set();
 for(const delimiter of [',',';']){
  let rows;try{rows=parseCSVRecords(String(text).replace(/^\ufeff/,''),delimiter)}catch{continue}
  const at=[0,3].find(i=>rows[i]&&EXCEL_HEADERS.every((h,c)=>csvHeader(rows[i][c])===csvHeader(h)));if(at===undefined)continue;
  header=rows[at];if(csvHeader(header[16])!=='wbs'||csvHeader(header[17])!=='plan/actual')throw Error('หัวคอลัมน์ Q ต้องเป็น WBS และ R ต้องเป็น Plan / Actual');
  const dataRows=rows.slice(at+1).filter(r=>r.slice(0,15).some(v=>csvName(v))),flat=dataRows.length&&dataRows.every(r=>r.slice(0,5).length===5&&r.slice(0,5).every(v=>csvName(csvUnescape(String(v)))));
  if(flat){const aliases=new Map(),used=new Set(dataRows.map(r=>csvName(csvUnescape(String(r[16]||'')))));let counter=1000000;
   for(const row of dataRows){if(csvName(row[16]))continue;const activity=csvHeader(header[22])==='activity'?csvName(csvUnescape(String(row[22]||''))):'',key=csvHeader(header[19])==='taskid'&&csvName(row[19])?'id:'+csvUnescape(row[19]):JSON.stringify([...row.slice(0,5).map(v=>csvName(csvUnescape(v))),activity]);
    if(!aliases.has(key)){while(used.has(String(++counter))){}aliases.set(key,String(counter));used.add(String(counter));transientCodes.add(String(counter))}row[16]=aliases.get(key)}
   normalized=rows.map(r=>r.map(v=>'"'+String(v??'').replace(/"/g,'""')+'"').join(',')).join('\r\n');
  }break;
 }
 const source=readLegacyScheduleCSV(normalized);
 for(const r of source.records){
  r.taskId=csvHeader(header[19])==='taskid'?csvName(r.plan[19]):'';r.projectId=csvHeader(header[20])==='projectid'?csvName(r.plan[20]):'';r.productId=csvHeader(header[21])==='productid'?csvName(r.plan[21]):'';
  r.activity=csvHeader(header[22])==='activity'?csvName(r.plan[22]):'';r.descriptionId=csvHeader(header[23])==='descriptionid'?csvName(r.plan[23]):'';r.isActivity=Boolean(r.activity)||r.type==='activity';r.transientCode=transientCodes.has(r.code);
  if(r.isActivity&&!r.activity)throw Error('WBS '+r.code+': Activity ว่าง');if(!r.isActivity&&r.descriptionId)throw Error('WBS '+r.code+': Description ID ใช้กับ Activity เท่านั้น');
  if(r.actual)for(const c of [0,1,2,3,19,20,21,22,23])if(csvName(r.actual[c])!==csvName(r.plan[c]))throw Error('WBS '+r.code+': ข้อมูลโครงการ / Product / Activity / รหัสงานของ Plan และ Actual ไม่ตรงกัน');
 }
 source.database=source.records.every(r=>r.plan.slice(0,5).every(v=>csvName(v))&&!r.hasChildren&&(!r.type||['task','activity'].includes(r.type)));return source;
}
function buildDatabaseCSVPlan(source,mode='update',clearBlanks=false){
 const next=structuredClone(state),preview=[],issues=[],warnings=[...source.warnings],current=scheduleTreeRecords().filter(r=>[3,4].includes(databaseLevel(r.raw))),used=new Set(),ids=new Set([...state.groups,...state.tasks].map(r=>r.id));let sequence=0,changedCount=0,createdCount=0;
 const uid=kind=>{let id;do{id='db-'+kind+'-'+Date.now().toString(36)+'-'+(++sequence).toString(36)}while(ids.has(id));ids.add(id);return id},norm=v=>csvName(v),key=values=>JSON.stringify(values.map(norm));
 const validateDates=task=>{const a=task.dateMode==='manual'?task.planStart:task.start,b=task.dateMode==='manual'?task.planEnd:task.end;if(a&&b&&b<a)throw Error('วันจบ Plan ก่อนวันเริ่ม');if(task.actualStart&&task.actualEnd&&task.actualEnd<task.actualStart)throw Error('วันจบ Actual ก่อนวันเริ่ม')};
 const preserve=task=>{if(next.tasks.some(t=>t.parentId===task.id))return;if(task.dateMode!=='manual'&&(task.start||task.end)){task.dateMode='manual';task.planStart=task.start||null;task.planEnd=task.end||null}if(task.actualDateMode!=='manual'&&(task.actualStart||task.actualEnd))task.actualDateMode='manual'};
 for(const row of source.records){try{
  const business=[...row.plan.slice(0,5).map(norm),row.activity||''];if(business.slice(0,5).some(v=>!v))throw Error('ข้อมูล 5 ช่องแรกต้องครบ');const values=csvValues(row,warnings),idMatch=row.taskId?current.find(r=>r.raw.id===row.taskId):null,tupleMatches=current.filter(r=>key(databaseIdentity(r.raw))===key(business));let item=null;
  if(mode==='update'&&row.taskId){if(!idMatch)throw Error('ไม่พบ Task ID นี้ในโครงการปัจจุบัน');item=idMatch}else if(tupleMatches.length>1)throw Error('มีหลายงานที่ข้อมูลซ้ำกัน ให้ใช้ Task ID');else if(tupleMatches.length===1){if(mode!=='update')throw Error('งานนี้มีอยู่แล้ว ให้ใช้โหมดอัปเดต');item=tupleMatches[0]}
  if(item){
   if(used.has(item.raw.id))throw Error('Task ID เดียวกันปรากฏหลายรายการ');used.add(item.raw.id);const core=drawingFieldsFor(item.raw),product=databaseProduct(item.raw),description=databaseDescription(item.raw),isActivity=databaseLevel(item.raw)===4;
   if(row.isActivity!==isActivity)throw Error('ระดับ Description / Activity ไม่ตรงกับ Task ID');
   if(key(business.slice(0,4))!==key([core.pjCode,core.projectWorks,core.drawingGroup,core.product]))throw Error('ข้อมูลโครงการหรือ Product ไม่ตรงกับ Task ID ให้แก้หัวข้อใน HTML หรือดาวน์โหลด CSV ล่าสุด');
   if(row.projectId&&row.projectId!==item.raw.groupId)throw Error('Project ID ไม่ตรง');if(row.productId&&row.productId!==product?.id)throw Error('Product ID ไม่ตรง งานอาจถูกย้ายหลังส่งออก');
   if(isActivity&&(business[4]!==norm(description?.name)||row.descriptionId&&row.descriptionId!==description?.id))throw Error('Description / Description ID ไม่ตรงกับหัวข้อแม่ของ Activity');
   const target=next.tasks.find(t=>t.id===item.raw.id),changes=[],summary=next.tasks.some(t=>t.parentId===target.id);const assign=(k,v)=>{if((target[k]??null)!==(v??null)){changes.push((CSV_LABELS[k]||k)+': '+csvDisplay(target[k])+' → '+csvDisplay(v));target[k]=v}};
   if(row.taskId)assign('name',isActivity?row.activity:row.name);
   for(const k of ['currentInfo','owner','unit','quantity','workStatus','action','approvedDate','remark']){if((values[k]===null||values[k]==='')&&!clearBlanks)continue;assign(k,values[k])}
   let planChanged=false,actualChanged=false;
   for(const k of ['start','end','actualStart','actualEnd']){if(!(k in values)||values[k]===null&&!clearBlanks)continue;const actual=k.startsWith('actual'),field=summary&&!actual?(k==='start'?'planStart':'planEnd'):k,before=changes.length;assign(field,values[k]);if(changes.length!==before){if(actual)actualChanged=true;else planChanged=true}}
   if(summary&&planChanged)target.dateMode='manual';if(actualChanged)target.actualDateMode='manual';validateDates(target);if(changes.length)changedCount++;preview.push({code:item.code,name:isActivity?description.name+' / '+target.name:target.name,action:changes.length?'อัปเดต '+changes.length+' ช่อง':'ไม่เปลี่ยน',changes});continue;
  }
  const [pjCode,projectWorks,drawingGroup,productName,descriptionName]=business;let group=null;
  if(row.projectId){group=next.groups.find(g=>g.id===row.projectId);if(!group||!isDatabaseGroup(group)||group.pjCode!==pjCode||group.projectWorks!==projectWorks)throw Error('Project ID ไม่ตรงกับ PJ / Project Works')}
  else{const matches=next.groups.filter(g=>isDatabaseGroup(g)&&g.pjCode===pjCode);if(matches.length>1)throw Error('PJ ซ้ำในระบบ');group=matches[0];if(group&&group.projectWorks!==projectWorks)throw Error('PJ เดิมมี Project Works ต่างกัน')}
  if(!group){group={id:uid('project'),name:pjCode,pjCode,projectWorks,databaseModel:DATABASE_MODEL,area:'',owner:'',note:''};next.groups.push(group)}
  let product=null;if(row.productId){product=next.tasks.find(t=>t.id===row.productId);if(!product||product.groupId!==group.id||product.parentId||product.nodeType!=='section'||product.product!==productName||product.drawingGroup!==drawingGroup)throw Error('Product ID ไม่ตรงกับ Group Drawing / Product')}
  else product=next.tasks.find(t=>t.groupId===group.id&&!t.parentId&&t.nodeType==='section'&&t.product===productName&&t.drawingGroup===drawingGroup);
  if(!product){product={id:uid('product'),name:productName,groupId:group.id,parentId:null,nodeType:'section',product:productName,drawingGroup,area:productName,owner:'',start:null,end:null,progress:null,dateMode:'auto',planStart:null,planEnd:null,category:'งานแบบและเอกสาร'};next.tasks.push(product)}
  let parent=product;
  if(row.isActivity){
   let description;if(row.descriptionId){description=next.tasks.find(t=>t.id===row.descriptionId);if(!description||description.parentId!==product.id||norm(description.name)!==descriptionName)throw Error('Description ID ไม่ตรงกับ Description / Product')}
   else{const matches=next.tasks.filter(t=>t.parentId===product.id&&norm(t.name)===descriptionName);if(matches.length>1)throw Error('Description ซ้ำ ให้ใช้ Description ID');description=matches[0]}
   if(!description){description={id:uid('description'),name:descriptionName,groupId:group.id,parentId:product.id,nodeType:'task',area:productName,owner:'',start:null,end:null,actualStart:null,actualEnd:null,progress:null,barColor:null,category:'งานแบบและเอกสาร'};next.tasks.push(description)}
   preserve(description);parent=description;
  }
  const name=row.isActivity?row.activity:descriptionName;if(next.tasks.some(t=>t.parentId===parent.id&&norm(t.name)===name))throw Error(row.isActivity?'มี Activity นี้อยู่ใน Description เดียวกันแล้ว':'มี Description นี้อยู่ใน Product เดียวกันแล้ว');
  const task={id:uid(row.isActivity?'activity':'work'),name,groupId:group.id,parentId:parent.id,nodeType:'task',area:productName,owner:values.owner||'',start:values.start,end:values.end,actualStart:values.actualStart??null,actualEnd:values.actualEnd??null,progress:null,category:'งานแบบและเอกสาร',barColor:null};
  for(const k of ['currentInfo','unit','quantity','workStatus','action','approvedDate','remark'])task[k]=values[k];task.actualDateMode=task.actualStart||task.actualEnd?'manual':'auto';validateDates(task);next.tasks.push(task);createdCount++;preview.push({code:row.transientCode?'ใหม่':row.code,name:row.isActivity?descriptionName+' / '+name:name,action:row.isActivity?'เพิ่ม LV4 · Activity':'เพิ่ม LV3 · Description',changes:business.filter(Boolean)});
 }catch(error){issues.push('WBS '+(row.transientCode?'ใหม่':row.code)+' · '+row.name+(row.activity?' / '+row.activity:'')+': '+error.message)}}
 return{next,preview,issues,warnings:[...new Set(warnings)],changedCount,createdCount,revision,mode,database:true};
}
function makeScheduleCSV(groupId='all'){
 if(!state.groups.some(isDatabaseGroup))return makeLegacyScheduleCSV(groupId);
 const escape=(value,c)=>{let s=String(value??'');if(/^[=+\-@']/.test(s)||[16,19,20,21,23].includes(c)&&/^\d[\d.]*$/.test(s))s="'"+s;return '"'+s.replace(/"/g,'""')+'"'},lines=[databaseHeaders()];
 for(const r of excelExportRecords(groupId))for(const actual of [false,true]){const t=r.view,c=r.core,description=databaseDescription(r.raw),activity=databaseActivityName(r.raw);lines.push([c.pjCode,c.projectWorks,c.drawingGroup,c.product,description?.name||t.name,t.currentInfo,t.owner==='—'?'':t.owner,t.unit,t.quantity,t.workStatus,t.action,actual?t.actualStart:t.start,actual?t.actualEnd:t.end,t.approvedDate,t.remark,null,r.code,actual?'Actual':'Plan',activity?'Activity':'Task',t.id,t.groupId,databaseProduct(r.raw)?.id||'',activity,activity?description.id:''])}
 return '\ufeff'+lines.map(r=>r.map(escape).join(',')).join('\r\n')+'\r\n';
}
