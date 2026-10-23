import {enableNumericExpressions} from './numeric-inputs.js';
import * as THREE from 'three';
import {selectionDimensions,panelEdgeLabels} from './dimensions.js';

export function setupSelectionDimensions(view){
 const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');svg.id='selection-dimensions';svg.setAttribute('aria-label','Selected object boundary edge lengths in millimetres');view.append(svg);
 const edgeSvg=document.createElementNS(ns,'svg');edgeSvg.id='panel-edge-labels';edgeSvg.setAttribute('aria-label','Selected panel edge numbers matching the fold table');view.append(edgeSvg);
 const toggleLabel=document.createElement('label');toggleLabel.className='check dimension-toggle';toggleLabel.innerHTML='<input id="dimensions-toggle" type="checkbox" checked>Dimensions';document.querySelector('.toolbar-end').prepend(toggleLabel);
 const toggle=toggleLabel.querySelector('input'),key='facade-studio-dimensions-v1';
 try{toggle.checked=localStorage.getItem(key)!=='off'}catch{}
 let items=[],edgeItems=[],editor=null;
 function closeEditor(){editor?.remove();editor=null}
 function visibility(){svg.style.display=toggle.checked?'':'none';try{localStorage.setItem(key,toggle.checked?'on':'off')}catch{}}
 toggle.onchange=visibility;visibility();
 const element=(tag,attributes={})=>{const node=document.createElementNS(ns,tag);for(const [key,value]of Object.entries(attributes))node.setAttribute(key,value);return node};
 function select(area,panel,options={}){
  closeEditor();edgeSvg.replaceChildren();edgeItems=(options.edgeSpecs??panelEdgeLabels(area,panel)).map(spec=>{const group=element('g',{'class':'panel-edge-main','data-edge-index':spec.edgeIndex,'data-panel-key':spec.panelKey,'data-area-id':spec.areaId,'data-start':spec.start.join(','),'data-end':spec.end.join(',')});const width=Math.max(25,spec.label.length*7+10),background=element('rect',{x:-width/2,y:-10,width,height:20,rx:3}),text=element('text',{'text-anchor':'middle','dominant-baseline':'central'}),title=element('title');text.textContent=spec.label;title.textContent=`${spec.label} · ขอบเดียวกับแถว ${spec.label} ในตารางพับ`;group.append(title,background,text);edgeSvg.append(group);const ends=[1,2].map(end=>{const node=element('g',{'class':'panel-edge-end','data-edge-index':spec.edgeIndex,'data-end-index':end,'data-area-id':spec.areaId,'data-panel-key':spec.panelKey}),label=spec.label+'-'+end,width=label.length*6+10,rect=element('rect',{x:-width/2,y:-8,width,height:16,rx:3}),value=element('text',{'text-anchor':'middle','dominant-baseline':'central'});value.textContent=label;node.append(rect,value);edgeSvg.append(node);return node});return {spec,group,ends}});
  svg.replaceChildren();items=selectionDimensions(area,panel).map(spec=>{
   const group=element('g',{'data-axis':spec.axis,'data-kind':spec.kind,'data-value':spec.value,'data-area-id':spec.areaId,'data-panel-key':spec.panelKey,'data-measurement':spec.measurement,'data-start':spec.start.join(','),'data-end':spec.end.join(',')});
   const title=element('title');title.textContent=`${spec.name} · ${spec.label} · actual boundary edge length`;
   const extensions=[element('line',{class:'dim-extension'}),element('line',{class:'dim-extension'})],line=element('line',{class:'dim-line'}),arrows=[element('path',{class:'dim-arrow'}),element('path',{class:'dim-arrow'})],label=element('g',{class:'dim-label'}),background=element('rect',{rx:3}),text=element('text',{'text-anchor':'middle','dominant-baseline':'central',class:'dim-value'});
   if(options.onEdit){text.setAttribute('role','button');text.setAttribute('tabindex','0');text.setAttribute('aria-label','Edit '+spec.label+' dimension');const edit=()=>openEditor(spec,options.onEdit);text.addEventListener('click',edit);text.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();e.stopPropagation();edit()}})}
   text.textContent=(spec.label+' ')+spec.value.toLocaleString('en-US',{maximumFractionDigits:2})+' mm';const width=text.textContent.length*6.6+14;background.setAttribute('x',-width/2);background.setAttribute('y',-10);background.setAttribute('width',width);background.setAttribute('height',20);
   label.append(background,text);group.append(title,...extensions,line,...arrows,label);svg.append(group);
   return {spec,group,extensions,line,arrows,label};
  });
 }
 function openEditor(spec,onEdit){
  closeEditor();const form=document.createElement('form');form.id='panel-dimension-editor';const label=document.createElement('label');label.textContent=`${spec.label} · mm`;const input=document.createElement('input');input.type='number';input.min='1';input.step='any';input.value=Number(spec.value.toFixed(3));input.setAttribute('aria-label','Panel dimension value');label.append(input);const apply=document.createElement('button');apply.type='submit';apply.textContent='Apply · Enter';form.append(label,apply);enableNumericExpressions(form);view.append(form);editor=form;
  const rect=svg.getBoundingClientRect(),target=items.find(i=>i.spec===spec)?.label.getBoundingClientRect();form.style.left=Math.max(8,Math.min(view.clientWidth-190,(target?.left||rect.left)-rect.left))+'px';form.style.top=Math.max(8,Math.min(view.clientHeight-110,(target?.top||rect.top)-rect.top+24))+'px';
  form.onsubmit=e=>{e.preventDefault();if(input.value.trim()&&onEdit(spec,Number(input.value)))closeEditor()};input.onkeydown=e=>{if(e.key==='Escape'){e.preventDefault();e.stopPropagation();closeEditor()}};input.focus();input.select();
 }
 const project=(p,camera,w,h)=>{const v=new THREE.Vector3(...p).project(camera);return {x:(v.x+1)*w/2,y:(1-v.y)*h/2,z:v.z}};
 const setLine=(node,a,b)=>{node.setAttribute('x1',a.x);node.setAttribute('y1',a.y);node.setAttribute('x2',b.x);node.setAttribute('y2',b.y)};
 function update(camera,w,h){
  if(!w||!h)return;
  edgeSvg.setAttribute('viewBox',`0 0 ${w} ${h}`);const endPlacements=[],obstacles=[];
  for(const {spec,group,ends}of edgeItems){const a=project(spec.start,camera,w,h),b=project(spec.end,camera,w,h),mid=project(spec.mid,camera,w,h),inside=project(spec.inward,camera,w,h),dx=b.x-a.x,dy=b.y-a.y,len=Math.hypot(dx,dy);const hidden=len<36||a.z< -1||a.z>1||b.z< -1||b.z>1||mid.x<0||mid.x>w||mid.y<0||mid.y>h;group.style.display=hidden?'none':'';ends.forEach(node=>node.style.display=hidden||len<130?'none':'');if(hidden)continue;let nx=-dy/len,ny=dx/len;if((inside.x-mid.x)*nx+(inside.y-mid.y)*ny<0){nx=-nx;ny=-ny}group.setAttribute('transform',`translate(${mid.x+nx*18},${mid.y+ny*18})`);obstacles.push({x:mid.x+nx*18,y:mid.y+ny*18,width:Math.max(25,spec.label.length*7+10),height:20});const inset=Math.min(45,len*.2);ends.forEach((node,index)=>{const atStart=spec.trimReversed?index===1:index===0,p=atStart?a:b,sign=atStart?1:-1;const x=p.x+dx/len*inset*sign+nx*30,y=p.y+dy/len*inset*sign+ny*30;node.setAttribute('transform',`translate(${x},${y})`);if(!hidden&&len>=130)endPlacements.push({node,x,y,tx:dx/len*sign,ty:dy/len*sign,width:(spec.label.length+2)*6+10,height:16,limit:Math.max(0,len*.38-inset)});node.setAttribute('data-point',(atStart?spec.start:spec.end).join(','))})}
  for(const placement of endPlacements){const {node,tx,ty,limit}=placement;let placed=false;for(let shift=0;shift<=limit;shift+=14){const box={...placement,x:placement.x+tx*shift,y:placement.y+ty*shift};if(obstacles.some(b=>Math.abs(box.x-b.x)<(box.width+b.width)/2+3&&Math.abs(box.y-b.y)<(box.height+b.height)/2+3))continue;node.setAttribute('transform',`translate(${box.x},${box.y})`);obstacles.push(box);placed=true;break}if(!placed)node.style.display='none'}
  if(!toggle.checked||!items.length)return;
  svg.setAttribute('viewBox',`0 0 ${w} ${h}`);
  for(const {spec,group,extensions,line,arrows,label}of items){
   const a=project(spec.start,camera,w,h),b=project(spec.end,camera,w,h),center=project(spec.center,camera,w,h),dx=b.x-a.x,dy=b.y-a.y,distance=Math.hypot(dx,dy);
   const hidden=distance<24||a.z< -1||a.z>1||b.z< -1||b.z>1;group.style.display=hidden?'none':'';if(hidden)continue;
   const direction={x:dx/distance,y:dy/distance};let normal={x:-direction.y,y:direction.x};
   const outside=project(spec.outside,camera,w,h),mid=project(spec.start.map((n,i)=>(n+spec.end[i])/2),camera,w,h),side=(outside.x-mid.x)*normal.x+(outside.y-mid.y)*normal.y;
   if(side<0||(Math.abs(side)<1e-8&&(center.x-(a.x+b.x)/2)*normal.x+(center.y-(a.y+b.y)/2)*normal.y>0))normal={x:-normal.x,y:-normal.y};
   const offset=spec.kind==='panel'?26:34,shift=(p,d)=>({x:p.x+normal.x*d,y:p.y+normal.y*d}),start=shift(a,offset),end=shift(b,offset);
   setLine(extensions[0],shift(a,4),shift(a,offset+7));setLine(extensions[1],shift(b,4),shift(b,offset+7));setLine(line,start,end);
   for(let i=0;i<2;i++){const p=i?end:start,sign=i?-1:1,back={x:p.x+direction.x*8*sign,y:p.y+direction.y*8*sign};arrows[i].setAttribute('d',`M ${p.x} ${p.y} L ${back.x+normal.x*3} ${back.y+normal.y*3} L ${back.x-normal.x*3} ${back.y-normal.y*3} Z`)}
   let angle=Math.atan2(dy,dx)*180/Math.PI;if(angle>90)angle-=180;if(angle< -90)angle+=180;
   label.setAttribute('transform',`translate(${(start.x+end.x)/2},${(start.y+end.y)/2}) rotate(${angle})`);
  }
 }
 return {select,update};
}
