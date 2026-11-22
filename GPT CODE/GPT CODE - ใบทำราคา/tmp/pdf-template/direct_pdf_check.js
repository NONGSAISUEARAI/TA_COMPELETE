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
    if(['documentNo','project'].includes(el.dataset.header))syncFileName();
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
document.getElementById('print').addEventListener('click',()=>{exportFileBase();window.print();});
document.getElementById('save').addEventListener('click',()=>{
  const saveBase=exportFileBase();
  for(const control of document.querySelectorAll('input[type=checkbox]'))control.toggleAttribute('checked',control.checked);
  document.getElementById('template-model').textContent=JSON.stringify(model).replaceAll('<','\\u003c');
  const saved=document.documentElement.cloneNode(true);
  saved.querySelectorAll('[contenteditable]').forEach(el=>el.setAttribute('contenteditable','false'));
  saved.querySelector('#pages').replaceChildren();saved.querySelector('#edit').setAttribute('aria-pressed','false');
  const blob=new Blob(['<!doctype html>\n'+saved.outerHTML],{type:'text/html;charset=utf-8'}),url=URL.createObjectURL(blob),a=document.createElement('a');
  a.href=url;a.download=saveBase+'.html';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
});
const fileNameInput=document.getElementById('file-name');
const fileMaterialInput=document.getElementById('file-material');
const fileSaveStatus=document.getElementById('file-save-status');
model.fileNaming=model.fileNaming||{materialName:'ถาดไฟ VA และ SOLID',baseName:'',manual:false};
function safeFileBase(value){
  return String(value||'').replace(/[<>:"/\\|?*\u0000-\u001f]/g,'-').replace(/\.(?:html?|pdf)$/i,'').replace(/\s+/g,' ').replace(/[. ]+$/g,'').trim();
}
function automaticFileBase(){
  const documentNo=String(model.headers.documentNo||'BU2-DE-26xxx').trim();
  const project=String(model.headers.project||'').replace(/^\s*โครงการ\s*/,'').trim();
  return safeFileBase(`${documentNo}_โครงการ ${project} ${model.fileNaming.materialName||''}`);
}
function syncFileName(forceAutomatic=false){
  if(forceAutomatic)model.fileNaming.manual=false;
  if(!model.fileNaming.manual||!model.fileNaming.baseName)model.fileNaming.baseName=automaticFileBase();
  fileNameInput.value=model.fileNaming.baseName;
  if(fileMaterialInput.value!==(model.fileNaming.materialName||''))fileMaterialInput.value=model.fileNaming.materialName||'';
  document.title=safeFileBase(model.fileNaming.baseName)||automaticFileBase();
  model.downloadFilename=document.title+'.html';
}
function exportFileBase(){
  const name=safeFileBase(fileNameInput.value)||automaticFileBase();
  fileNameInput.value=name;model.fileNaming.baseName=name;document.title=name;
  model.downloadFilename=name+'.html';return name;
}
fileMaterialInput.addEventListener('input',()=>{
  model.fileNaming.materialName=fileMaterialInput.value;
  if(!model.fileNaming.manual)syncFileName();
  fileSaveStatus.textContent='';
});
fileNameInput.addEventListener('input',()=>{
  model.fileNaming.manual=true;model.fileNaming.baseName=fileNameInput.value;
  document.title=safeFileBase(fileNameInput.value)||automaticFileBase();fileSaveStatus.textContent='';
});
fileNameInput.addEventListener('blur',()=>{exportFileBase();});
document.getElementById('auto-file-name').addEventListener('click',()=>{syncFileName(true);fileSaveStatus.textContent='ตั้งชื่อไฟล์ตามเลขที่ใบขอ โครงการ และชื่อวัสดุแล้ว';});
window.addEventListener('beforeprint',()=>{exportFileBase();calibrate();});
// Standalone PDF export. The fixed HTML design coordinates are PDF points.
// Text uses the same embedded fonts, with shaped Thai glyph positions.
const rfqPdfFontSources=new Map();
function rfqPdfFontKey(family,weight,style){
  return `${family.replace(/["']/g,'').split(',')[0].trim()}|${Number(weight)||400}|${style||'normal'}`;
}
function rfqPdfReadFonts(){
  if(rfqPdfFontSources.size)return;
  for(const sheet of document.styleSheets){
    for(const rule of sheet.cssRules){
      if(rule.type!==CSSRule.FONT_FACE_RULE)continue;
      const match=rule.style.getPropertyValue('src').match(/data:font\/ttf;base64,([A-Za-z0-9+/=]+)/);
      if(!match)continue;
      const key=rfqPdfFontKey(rule.style.fontFamily,rule.style.fontWeight,rule.style.fontStyle);
      rfqPdfFontSources.set(key,Uint8Array.from(atob(match[1]),c=>c.charCodeAt(0)));
    }
  }
}
function rfqPdfMatrix(el,paper){
  let result=new DOMMatrix();
  for(let node=el;node&&node!==paper;node=node.parentElement){
    const style=getComputedStyle(node);
    const transform=style.transform==='none'?new DOMMatrix():new DOMMatrix(style.transform);
    const position=new DOMMatrix().translate(parseFloat(style.left)||0,parseFloat(style.top)||0);
    result=position.multiply(transform).multiply(result);
  }
  return result;
}
function rfqPdfColor(value){
  if(!value||value==='none'||value==='transparent')return undefined;
  if(/^#[0-9a-f]{3}$/i.test(value))value='#'+value.slice(1).split('').map(v=>v+v).join('');
  const match=value.match(/^#([0-9a-f]{6})$/i);
  if(match)return PDFLib.rgb(...[0,2,4].map(i=>parseInt(match[1].slice(i,i+2),16)/255));
  if(value==='#000'||value==='black')return PDFLib.rgb(0,0,0);
  if(value==='#fff'||value==='white')return PDFLib.rgb(1,1,1);
  const rgb=value.match(/^rgba?\((\d+)[, ]+(\d+)[, ]+(\d+)/);
  if(rgb)return PDFLib.rgb(...rgb.slice(1,4).map(v=>Number(v)/255));
  throw new Error('Unsupported PDF color: '+value);
}
function rfqPdfDrawSvg(page,svg,paper){
  const origin=rfqPdfMatrix(svg,paper),height=612;
  for(const shape of svg.children){
    if(getComputedStyle(shape).display==='none')continue;
    const num=name=>Number(shape.getAttribute(name)||0);
    const fill=rfqPdfColor(shape.getAttribute('fill'));
    const stroke=rfqPdfColor(shape.getAttribute('stroke'));
    const borderWidth=num('stroke-width');
    if(shape.tagName.toLowerCase()==='rect'){
      if(!fill&&!stroke)continue;
      page.drawRectangle({x:origin.e+num('x'),y:height-origin.f-num('y')-num('height'),width:num('width'),height:num('height'),color:fill,borderColor:stroke,borderWidth:stroke?borderWidth:0});
    }else if(shape.tagName.toLowerCase()==='line'){
      if(!stroke)continue;
      page.drawLine({start:{x:origin.e+num('x1'),y:height-origin.f-num('y1')},end:{x:origin.e+num('x2'),y:height-origin.f-num('y2')},color:stroke,thickness:borderWidth});
    }else if(shape.tagName.toLowerCase()==='path'){
      if(!fill&&!stroke)continue;
      page.drawSvgPath(shape.getAttribute('d'),{x:origin.e,y:height-origin.f,color:fill,borderColor:stroke,borderWidth:stroke?borderWidth:0,borderLineCap:PDFLib.LineCapStyle.Round});
    }else{
      throw new Error('Unsupported PDF vector: '+shape.tagName);
    }
  }
}
async function rfqPdfDrawText(page,el,paper,fonts,doc){
  const text=el.textContent;if(!text)return;
  const s=getComputedStyle(el),key=rfqPdfFontKey(s.fontFamily,s.fontWeight,s.fontStyle);
  let face=fonts.get(key);
  if(!face){
    const bytes=rfqPdfFontSources.get(key);
    if(!bytes)throw new Error('Missing embedded PDF font: '+key);
    const embedded=await doc.embedFont(bytes,{subset:true});
    face={embedded,shaper:fontkit.create(bytes),pageKeys:new Map()};fonts.set(key,face);
  }
  let fontKey=face.pageKeys.get(page);
  if(!fontKey){fontKey=page.node.newFontDictionary(face.embedded.name,face.embedded.ref);face.pageKeys.set(page,fontKey);}
  const size=parseFloat(s.fontSize),unit=size/face.shaper.unitsPerEm;
  const matrix=rfqPdfMatrix(el,paper);
  const color=rfqPdfColor(s.color),stroke=parseFloat(s.webkitTextStrokeWidth)||0;
  const {pushGraphicsState,popGraphicsState,beginText,endText,setFontAndSize,setTextMatrix,showText,PDFHexString,setFillingRgbColor,setStrokingRgbColor,setTextRenderingMode,setLineWidth}=PDFLib;
  const paddingLeft=parseFloat(s.paddingLeft)||0,paddingRight=parseFloat(s.paddingRight)||0;
  const width=parseFloat(s.width)||0;
  measureContext.font=`${s.fontStyle} ${s.fontWeight} ${s.fontSize} ${s.fontFamily}`;
  const lines=text.replace(/\r/g,'').split('\n');
  for(let lineIndex=0;lineIndex<lines.length;lineIndex++){
    const line=lines[lineIndex];if(!line)continue;
    const layout=face.shaper.layout(line);
    if(layout.glyphs.some(g=>g.id===0))throw new Error('มีอักขระที่ฟอนต์ PDF ไม่รองรับ');
    const encoded=face.embedded.encodeText(line).asBytes();
    if(encoded.length!==layout.glyphs.length*2)throw new Error('PDF font shaping mismatch');
    const natural=measureContext.measureText(line).width;
    const advance=layout.positions.reduce((n,p)=>n+p.xAdvance,0)*unit;
    const horizontal=advance?natural/advance:1;
    let left=paddingLeft;
    if(s.textAlign==='center')left+=(width-paddingLeft-paddingRight-natural)/2;
    if(s.textAlign==='right')left=width-paddingRight-natural;
    const by=baseline(el)+lineIndex*(parseFloat(s.lineHeight)||size);
    // ActualText preserves the original Thai spelling when copied or searched,
    // even when the font's shaping engine reorders or decomposes vowel glyphs.
    const actualText=PDFLib.PDFOperator.of('BDC',[PDFLib.PDFName.of('Span'),doc.context.obj({ActualText:PDFHexString.fromText(line)})]);
    const ops=[pushGraphicsState(),actualText,setFillingRgbColor(color.red,color.green,color.blue),setStrokingRgbColor(color.red,color.green,color.blue),setLineWidth(stroke),beginText(),setFontAndSize(fontKey,size),setTextRenderingMode(stroke?2:0)];
    let penX=0,penY=0;
    for(let i=0;i<layout.glyphs.length;i++){
      const p=layout.positions[i];
      const x=left+(penX+p.xOffset)*unit*horizontal,y=by-(penY+p.yOffset)*unit;
      const point=matrix.transformPoint({x,y});
      const glyphId=(encoded[2*i]<<8)|encoded[2*i+1];
      ops.push(setTextMatrix(matrix.a*horizontal,-matrix.b*horizontal,-matrix.c,matrix.d,point.x,612-point.y),showText(PDFHexString.of(glyphId.toString(16).padStart(4,'0'))));
      penX+=p.xAdvance;penY+=p.yAdvance;
    }
    ops.push(endText(),PDFLib.endMarkedContent(),popGraphicsState());page.pushOperators(...ops);
  }
}
async function rfqCreatePdf(name){
  if(document.fonts)await document.fonts.ready;
  calibrate();rfqPdfReadFonts();
  const doc=await PDFLib.PDFDocument.create();doc.registerFontkit(fontkit);
  doc.setTitle(name);doc.setCreator('RFQ HTML');doc.setProducer('RFQ standalone vector PDF');
  doc.catalog.getOrCreateViewerPreferences().setPrintScaling(PDFLib.PrintScaling.None);
  const fonts=new Map(),images=new Map();
  for(const paper of pages.querySelectorAll('.paper')){
    const page=doc.addPage([792,612]);
    rfqPdfDrawSvg(page,paper.querySelector('.form-lines'),paper);
    for(const logo of paper.querySelectorAll('.logo')){
      let image=images.get(logo.src);
      if(!image){image=await doc.embedPng(logo.src);images.set(logo.src,image);}
      const s=getComputedStyle(logo),m=rfqPdfMatrix(logo,paper),w=parseFloat(s.width),h=parseFloat(s.height);
      page.drawImage(image,{x:m.e,y:612-m.f-h,width:w,height:h});
    }
    for(const svg of paper.querySelectorAll('.check-box'))rfqPdfDrawSvg(page,svg,paper);
    for(const el of paper.querySelectorAll('.ink'))await rfqPdfDrawText(page,el,paper,fonts,doc);
    // Yield between pages so the busy message can paint for longer documents.
    await new Promise(resolve=>setTimeout(resolve,0));
  }
  return doc.save();
}
document.getElementById('save-pdf').addEventListener('click',async event=>{
  const button=event.currentTarget;
  if(button.disabled)return;
  const name=exportFileBase();button.disabled=true;button.setAttribute('aria-busy','true');
  fileSaveStatus.textContent='กำลังสร้าง PDF…';
  try{
    await new Promise(resolve=>setTimeout(resolve,0));
    const bytes=await rfqCreatePdf(name);
    const blob=new Blob([bytes],{type:'application/pdf'}),url=URL.createObjectURL(blob),a=document.createElement('a');
    a.href=url;a.download=name+'.pdf';document.body.append(a);a.click();a.remove();
    setTimeout(()=>URL.revokeObjectURL(url),60000);
    fileSaveStatus.textContent=`ดาวน์โหลดแล้ว: ${name}.pdf`;
  }catch(error){
    console.error('RFQ PDF export:',error);
    fileSaveStatus.textContent='สร้าง PDF ไม่สำเร็จ กรุณาลองใหม่ หรือใช้ปุ่มพิมพ์';
  }finally{
    button.disabled=false;button.removeAttribute('aria-busy');
  }
});

syncFileName();

renderPages();resize();
document.fonts.ready.then(()=>{calibrate();resize();});
