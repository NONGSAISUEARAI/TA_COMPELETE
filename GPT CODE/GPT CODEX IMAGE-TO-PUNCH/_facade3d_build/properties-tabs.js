import {curtainFrame} from './curtain.js';
import {foldedPanelSize} from './folded-panel-size.js';
export function setupPropertiesTabs(){
 const panel=document.querySelector('.right-panel'),heading=panel.querySelector('.panel-heading'),key='facade-studio-properties-tabs-v1',main=document.createElement('div');main.id='properties-tabpanel';main.setAttribute('role','tabpanel');main.setAttribute('aria-labelledby','properties-tab');
 for(const child of [...panel.children])if(child!==heading)main.append(child);panel.append(main);
 heading.querySelector('span').textContent='PROPERTIES';
 const tabs=document.createElement('div');tabs.className='properties-tabs';tabs.setAttribute('role','tablist');tabs.setAttribute('aria-label','Properties workspace');
 tabs.innerHTML='<button id="properties-tab" role="tab" type="button" aria-controls="properties-tabpanel">Properties</button><button id="unfold-tab" role="tab" type="button" aria-controls="unfold-tabpanel">Unfold / Blank Size</button><button id="export-tab" role="tab" type="button" aria-controls="export-tabpanel">Export</button>';
 heading.after(tabs);
 const unfold=document.createElement('div');unfold.id='unfold-tabpanel';unfold.setAttribute('role','tabpanel');unfold.setAttribute('aria-labelledby','unfold-tab');unfold.innerHTML='<div class="unfold-heading"><span class="eyebrow">UNFOLD / BLANK SIZE</span><h2>แผ่นคลี่</h2><p id="unfold-selection" class="helper"></p></div><p id="unfold-empty" class="helper">เลือก Panel หรือชิ้นงานที่ Join ในฉาก เพื่อดูรูปคลี่</p><div id="unfold-content" hidden><svg id="unfold-face-preview" role="img" aria-label="Selected panel face layout before flange and bend allowance calculations"></svg><div class="unfold-metrics"><div><small>Face width · mm</small><strong id="unfold-face-width"></strong></div><div><small>Face height · mm</small><strong id="unfold-face-height"></strong></div></div><p id="unfold-faces" class="helper"></p><div class="unfold-blank-status"><b>Blank Size</b><p class="helper">ภาพและขนาดนี้เป็นผิวแผ่น ยังไม่รวมปีกพับและระยะเผื่อพับ จึงยังไม่ใช่ขนาด Blank สำหรับตัดผลิต</p></div></div>';
 panel.append(unfold);
 let saved={};try{saved=JSON.parse(localStorage.getItem(key)||'{}')||{}}catch{}
 let legacyScroll=0;try{legacyScroll=JSON.parse(localStorage.getItem('facade-studio-properties-ui-v1')||'{}').scrollTop||0}catch{}
 let initialized=false,restoring=true;let active=['unfold','export'].includes(saved.tab)?saved.tab:'properties',scrolls={properties:legacyScroll,unfold:0,...saved.scrolls};
 const persist=()=>{try{localStorage.setItem(key,JSON.stringify({tab:active,scrolls}))}catch{}};
 function show(tab,focus=false){if(!['properties','unfold','export'].includes(tab))return;if(initialized)scrolls[active]=panel.scrollTop;initialized=true;active=tab;main.hidden=tab!=='properties';unfold.hidden=tab!=='unfold';const exp=document.querySelector('#export-tabpanel');if(exp)exp.hidden=tab!=='export';for(const button of tabs.children){const selected=button.id===tab+'-tab';button.setAttribute('aria-selected',String(selected));button.tabIndex=selected?0:-1;if(selected&&focus)button.focus()}panel.scrollTop=scrolls[active]||0;persist()}
 for(const [index,button]of [...tabs.children].entries()){const names=['properties','unfold','export'];button.onclick=()=>show(names[index]);button.onkeydown=e=>{let next;if(e.key==='ArrowLeft')next=names[(names.indexOf(active)+2)%3];if(e.key==='ArrowRight')next=names[(names.indexOf(active)+1)%3];if(e.key==='Home')next='properties';if(e.key==='End')next='export';if(next){e.preventDefault();show(next,true)}}}
 panel.addEventListener('scroll',()=>{if(restoring)return;scrolls[active]=panel.scrollTop;persist()},{passive:true});
 const restoredScroll=scrolls[active]||0;show(active);requestAnimationFrame(()=>requestAnimationFrame(()=>requestAnimationFrame(()=>{panel.scrollTop=restoredScroll;restoring=false})));
 const $=id=>unfold.querySelector('#'+id),fmt=n=>n.toLocaleString('en-US',{maximumFractionDigits:2}),ns='http://www.w3.org/2000/svg';
 function update(items,assembly){
  const content=$('unfold-content'),empty=$('unfold-empty'),svg=$('unfold-face-preview');content.hidden=true;empty.hidden=false;svg.replaceChildren();$('unfold-selection').textContent='';
  if(!items.length){empty.textContent='เลือก Panel หรือชิ้นงานที่ Join ในฉาก เพื่อดูรูปคลี่';return}
  if(assembly&&items.some(({p})=>p.foldGroup!==assembly.group))assembly=null;
  if(!assembly&&(items.length!==1||items[0].p.foldGroup)){empty.textContent='เลือก Panel หนึ่งแผ่น หรือชิ้นงาน Join หนึ่งชิ้น เพื่อดูรูปคลี่';return}
  try{
   let faces,width,height;if(assembly){const layout=foldedPanelSize(assembly);faces=layout.faces;width=layout.width;height=layout.height;$('unfold-selection').textContent=`แผ่น Join · ${assembly.members.length} ด้าน`}else{const {a,p}=items[0],frame=curtainFrame(a);faces=[{rings:p.rings.map(r=>r.map(frame.to))}];const xs=faces[0].rings[0].map(p=>p[0]),ys=faces[0].rings[0].map(p=>p[1]);width=Math.max(...xs)-Math.min(...xs);height=Math.max(...ys)-Math.min(...ys);$('unfold-selection').textContent=p.name+' · '+a.name}
   const points=faces.flatMap(f=>f.rings[0]),xs=points.map(p=>p[0]),ys=points.map(p=>p[1]),minX=Math.min(...xs),maxY=Math.max(...ys),pad=Math.max(width,height)*.08||1;svg.setAttribute('viewBox',`${-pad} ${-pad} ${width+pad*2} ${height+pad*2}`);
   for(const [index,face]of faces.entries()){const path=document.createElementNS(ns,'path');path.setAttribute('d',face.rings.map(r=>'M'+r.map(p=>`${p[0]-minX},${maxY-p[1]}`).join(' L')+' Z').join(' '));path.setAttribute('fill-rule','evenodd');path.setAttribute('vector-effect','non-scaling-stroke');const title=document.createElementNS(ns,'title');title.textContent='Face '+(index+1);path.append(title);svg.append(path)}
   $('unfold-face-width').textContent=fmt(width);$('unfold-face-height').textContent=fmt(height);$('unfold-faces').textContent=`${faces.length} face${faces.length>1?'s':''} · ผิวแผ่นคลี่`;empty.hidden=true;content.hidden=false;
  }catch(e){empty.textContent=e.message}
 }
 return {show,update,get active(){return active}};
}
