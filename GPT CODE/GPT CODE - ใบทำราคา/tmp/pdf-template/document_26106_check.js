
const model=JSON.parse(document.getElementById('template-model').textContent);
const pages=document.getElementById('pages'),pageTemplate=document.getElementById('page-template');
const dataset=document.getElementById('dataset'),zoom=document.getElementById('zoom');
model.pageCount=Math.max(model.pageCount||1,Math.ceil(model.current.length/20));
model.secondary=model.secondary||[];model.pageChecks=model.pageChecks||[];
let editing=false,scale=1,calibrated=false;
const metrics=new Map();
const measureContext=document.createElement('canvas').getContext('2d');
function baseline(el){
  const s=getComputedStyle(el),key=[s.fontFamily,s.fontSize,s.fontWeight,s.fontStyle].join('|');
  if(metrics.has(key))return metrics.get(key);
  const probe=document.createElement('div');probe.style.cssText=`position:fixed;left:-10000px;top:0;white-space:nowrap;line-height:1;padding:0;margin:0;font-family:${s.fontFamily};font-size:${s.fontSize};font-weight:${s.fontWeight};font-style:${s.fontStyle}`;
  const sample=document.createElement('span');sample.textContent='Agกี่';
  const marker=document.createElement('i');marker.style.cssText='display:inline-block;width:0;height:0;padding:0;margin:0;vertical-align:baseline';
  probe.append(sample,marker);document.body.append(probe);
  const offset=marker.getBoundingClientRect().top-probe.getBoundingClientRect().top;probe.remove();metrics.set(key,offset);return offset;
}
function calibrate(root=pages){
  for(const el of root.querySelectorAll('.ink')){
    const by=baseline(el);el.style.transform=`translateY(${-by}px)`;
    if(el.dataset.fitWidth){
      el.style.transform=`translateY(${-by}px)`;
      const available=Number(el.dataset.fitWidth),style=getComputedStyle(el);
      measureContext.font=`${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
      const natural=measureContext.measureText(el.textContent).width;
      if(natural>available)el.style.transform+=` scaleX(${available/natural})`;
    }
  }
  calibrated=true;
}
function resize(){
  scale=zoom.value==='fit'?Math.max(.25,(document.querySelector('.workspace').clientWidth-40)/792):Number(zoom.value)*4/3;
  for(const slot of pages.querySelectorAll('.page-slot')){
    slot.firstElementChild.style.transform=`scale(${scale})`;slot.style.width=`${792*scale}px`;slot.style.height=`${612*scale}px`;
  }
}
function hasData(row){return ['description','materialCode','qty'].some(key=>String(row[key]??'').trim());}
function updateSummary(){
  const rows=[...model.current,...model.secondary.flat()].filter(r=>r&&hasData(r));
  const sum=rows.reduce((n,r)=>n+(Number(String(r.qty||0).replaceAll(',',''))||0),0);
  document.getElementById('summary').textContent=`${model.pageCount} หน้า · ${rows.length} รายการ · ${sum.toLocaleString('en-US')} ชิ้น`;
}
function materialName(code){return model.materials[String(code??'').trim()]||'';}
function getRow(page,section,row,create=false){
  if(section==='primary'){
    const index=page*20+row;
    if(create)while(model.current.length<=index)model.current.push({});
    return model.current[index]||{};
  }
  if(create&&!model.secondary[page])model.secondary[page]=[];
  const data=model.secondary[page]||[];
  if(create)while(data.length<=row)data.push({});
  return data[row]||{};
}
function renderRows(paper,page,section){
  const cells=paper.querySelector(`[data-section="${section}"]`),tops=section==='primary'?model.rowTops:model.secondaryRowTops;
  for(let row=0;row<tops.length-1;row++){
    const data=getRow(page,section,row),y=tops[row],height=tops[row+1]-y;
    data.material=materialName(data.materialCode);
    const rowEl=document.createElement('div');rowEl.setAttribute('role','row');
    for(let j=0;j<model.columns.length;j++){
      const key=model.columns[j],x=model.edges[j],width=model.edges[j+1]-x;
      const box=document.createElement('div');box.className='data-cell';box.style.cssText=`left:${x}px;top:${y}px;width:${width}px;height:${height}px`;box.setAttribute('role','cell');
      const text=document.createElement('span');text.className='ink';text.dataset.page=page;text.dataset.section=section;text.dataset.row=row;text.dataset.column=key;text.setAttribute('aria-label',`หน้า ${page+1} ${section==='primary'?'รายการ':'รายการเส้น'} ${row+1} ${model.columnNames[j]}`);
      let family=['description','width','length','qty'].includes(key)?'RFQUPC':'RFQCordia';
      const fontSize=key==='description'?4.68:6.36;
      const base=key==='description'?5.46:key==='material'?5.82:['no','materialCode','thickness','special','height'].includes(key)?6.42:6.30;
      text.style.cssText=`top:${base}px;font-family:${family};font-size:${fontSize}px;font-weight:${key==='material'?700:400}`;
      const left=['description','material','remark'].includes(key),right=key==='qty';
      text.style.textAlign=left?'left':right?'right':'center';text.style.left=left?'0.9px':'0px';text.style.width=`${width-(left?1.8:0)}px`;
      if(right)text.style.paddingRight='2px';
      if(['description','remark','material','specialColor','paintType','brand'].includes(key)){text.dataset.fitWidth=String(width-1.8);}
      const value=data[key]??'';text.textContent=key==='qty'&&value!==''?Number(value).toLocaleString('en-US'):String(value);
      text.contentEditable=String(editing&&!['material','no'].includes(key));text.spellcheck=false;
      if(key==='material')text.setAttribute('aria-readonly','true');
      if(key==='materialCode')text.setAttribute('aria-invalid',String(Boolean(String(value).trim())&&!materialName(value)));
      box.append(text);rowEl.append(box);
    }
    cells.append(rowEl);
  }
}
function syncHeaders(){
  for(const el of pages.querySelectorAll('[data-header]')){
    const page=Number(el.closest('.paper').dataset.page),key=el.dataset.header;
    el.textContent=key==='pageNumber'?`${page+1}/${model.pageCount}`:(model.headers[key]||'');
  }
}
function renderPages(){
  pages.replaceChildren();
  for(let page=0;page<model.pageCount;page++){
    const slot=document.createElement('div');slot.className='page-slot';
    const paper=pageTemplate.content.firstElementChild.cloneNode(true);paper.dataset.page=page;paper.setAttribute('aria-label',`ฟอร์มใบขอราคา หน้า ${page+1}`);
    paper.classList.toggle('strong-text',document.getElementById('strong-text').checked);paper.classList.toggle('editing',editing);
    model.pageChecks[page]=model.pageChecks[page]||structuredClone(model.defaultChecks);
    for(const control of paper.querySelectorAll('.check-field input'))control.checked=Boolean(model.pageChecks[page][control.name]);
    renderRows(paper,page,'primary');renderRows(paper,page,'secondary');
    for(const el of paper.querySelectorAll('[data-header]'))el.contentEditable=String(editing&&el.dataset.header!=='pageNumber');
    slot.append(paper);pages.append(slot);
  }
  syncHeaders();resize();if(calibrated)calibrate();updateSummary();
}
pages.addEventListener('input',event=>{
  const el=event.target.closest('.ink');if(!el)return;
  if(el.dataset.header){
    model.headers[el.dataset.header]=el.textContent;
    for(const other of pages.querySelectorAll(`[data-header="${el.dataset.header}"]`))if(other!==el)other.textContent=el.textContent;
    return;
  }
  const page=Number(el.dataset.page),section=el.dataset.section,r=Number(el.dataset.row),key=el.dataset.column;
  if(!section)return;
  const row=getRow(page,section,r,true);row[key]=el.textContent;
  if(key==='materialCode'){
    row.material=materialName(row.materialCode);
    el.setAttribute('aria-invalid',String(Boolean(el.textContent.trim())&&!row.material));
    const rowEl=el.closest('[role=row]');rowEl.querySelector('[data-column=material]').textContent=row.material;calibrate(rowEl);
  }
  if(hasData(row)){
    row.no=String(section==='primary'?page*20+r+1:r+1);
    el.closest('[role=row]').querySelector('[data-column=no]').textContent=row.no;
  }else{
    row.no='';el.closest('[role=row]').querySelector('[data-column=no]').textContent='';
  }
  updateSummary();
});
pages.addEventListener('change',event=>{
  const control=event.target.closest('.check-field input');if(!control)return;
  const page=Number(control.closest('.paper').dataset.page);model.pageChecks[page][control.name]=control.checked;
});
pages.addEventListener('focusout',event=>{const row=event.target.closest('[role=row]');if(row)calibrate(row);});
pages.addEventListener('paste',event=>{
  if(!editing)return;event.preventDefault();const text=event.clipboardData.getData('text/plain').replace(/[\r\n\t]+/g,' ');document.execCommand('insertText',false,text);
});
dataset.value=model.mode;
dataset.addEventListener('change',()=>{model.mode=dataset.value;model.current=dataset.value==='blank'?[]:structuredClone(model[dataset.value]);model.pageCount=Math.max(1,Math.ceil(model.current.length/20));model.secondary=[];model.pageChecks=[];renderPages();});
document.getElementById('add-page').addEventListener('click',()=>{
  model.pageChecks.push(structuredClone(model.pageChecks[0]||model.defaultChecks));model.pageCount++;renderPages();
  pages.lastElementChild.scrollIntoView({behavior:'smooth',block:'start'});
});
zoom.addEventListener('change',resize);window.addEventListener('resize',resize);
document.getElementById('edit').addEventListener('click',event=>{
  editing=!editing;event.currentTarget.setAttribute('aria-pressed',String(editing));
  for(const paper of pages.querySelectorAll('.paper')){
    paper.classList.toggle('editing',editing);
    for(const el of paper.querySelectorAll('.ink')){el.contentEditable=String(Boolean(editing&&((el.dataset.column&&!['material','no'].includes(el.dataset.column))||(el.dataset.header&&el.dataset.header!=='pageNumber'))));el.spellcheck=false;}
  }
});
document.getElementById('strong-text').addEventListener('change',event=>{for(const paper of pages.querySelectorAll('.paper'))paper.classList.toggle('strong-text',event.target.checked);});
document.getElementById('print').addEventListener('click',()=>window.print());
document.getElementById('save').addEventListener('click',()=>{
  for(const control of document.querySelectorAll('input[type=checkbox]'))control.toggleAttribute('checked',control.checked);
  document.getElementById('template-model').textContent=JSON.stringify(model).replaceAll('<','\\u003c');
  const saved=document.documentElement.cloneNode(true);
  saved.querySelectorAll('[contenteditable]').forEach(el=>el.setAttribute('contenteditable','false'));
  saved.querySelector('#pages').replaceChildren();saved.querySelector('#edit').setAttribute('aria-pressed','false');
  const blob=new Blob(['<!doctype html>\n'+saved.outerHTML],{type:'text/html;charset=utf-8'}),url=URL.createObjectURL(blob),a=document.createElement('a');
  a.href=url;a.download='BU2-DE-26106.html';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
});
renderPages();resize();
document.fonts.ready.then(()=>{calibrate();resize();});
