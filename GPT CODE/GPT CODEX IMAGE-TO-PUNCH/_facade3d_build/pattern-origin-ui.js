import {enableNumericExpressions} from './numeric-inputs.js';
import * as THREE from 'three';
import {worldPoint,localPoint,cross} from './geometry.js';
import {createOriginSnap} from './origin-snap.js';
import {originSnapScreen} from './origin-snap-screen.js';
import {patternOriginMeasurements,originAtEdgeDistance} from './pattern-origin.js';

export function setupPatternOrigin(view,api){
 const ns='http://www.w3.org/2000/svg',host=document.createElement('div');host.id='pattern-origin-overlay';
 const svg=document.createElementNS(ns,'svg');svg.setAttribute('aria-label','Pattern Origin distances to Area boundary');
 const grip=document.createElement('button');grip.id='pattern-origin-handle';grip.type='button';grip.setAttribute('aria-label','Drag Pattern Origin on selected Area');grip.innerHTML='<span class="origin-cross">⊕</span><span class="origin-caption"></span>';host.append(svg,grip);view.append(host);
 let area=null,preview=null,drag=null,items=[],measurements=null,editor=null;
 const fmt=n=>n.toLocaleString('en-US',{maximumFractionDigits:2});
 function setPoint(point){
  preview=[...point];measurements=patternOriginMeasurements(area,preview);svg.replaceChildren();items=[];if(!measurements)return;
  grip.dataset.localPoint=preview.join(',');grip.dataset.worldPoint=measurements.world.join(',');
  grip.querySelector('.origin-caption').textContent=`Pattern Origin · Local ${fmt(preview[0])}, ${fmt(preview[1])} mm`;
  grip.title=`คลิกเพื่อกรอก X/Y · ลากเพื่อย้ายและ Snap มุม/กึ่งกลางแผ่น · Esc ยกเลิก · World XYZ: ${measurements.world.map(fmt).join(' / ')} mm`;
  for(const [index,d] of measurements.dimensions.entries()){
   const group=document.createElementNS(ns,'g'),line=document.createElementNS(ns,'line'),label=document.createElementNS(ns,'text');group.dataset.edge=d.edge;group.dataset.value=d.value;group.dataset.start=d.start.join(',');group.dataset.end=d.end.join(',');label.textContent=`E${d.edge} · ${fmt(d.value)} mm`;label.setAttribute('role','button');label.setAttribute('tabindex','0');label.setAttribute('aria-label',`Edit distance to E${d.edge}`);label.addEventListener('click',()=>openEditor(d));label.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();e.stopPropagation();openEditor(d)}});group.append(line,label);svg.append(group);items.push({d,group,line,label,index});
  }
  update(api.camera(),view.clientWidth,view.clientHeight);
 }
 function select(next){closeEditor();if(drag)cancel();area=next?.visible===false?null:next;host.hidden=!area;if(area){setPoint(area.pattern.origin);api.preview(area.pattern.origin,area.id)}}
 function finish(cancelled=false){
  if(!drag)return;const state=drag,point=[...preview];drag=null;grip.classList.remove('dragging');grip.removeAttribute('data-dragging');if(grip.hasPointerCapture(state.pointerId))grip.releasePointerCapture(state.pointerId);
  api.end();api.feedback(null);
  if(cancelled){setPoint(state.origin);api.preview(state.origin,state.areaId);api.notify('Pattern Origin move cancelled');return}
  if(Math.hypot(point[0]-state.origin[0],point[1]-state.origin[1])<1e-6){api.preview(state.origin,state.areaId);if(!state.moved)openEditor();return}
  if(!api.commit(state.areaId,point)){setPoint(state.origin);api.preview(state.origin,state.areaId)}
 }
 function closeEditor(){if(editor){editor.form.remove();editor=null}}
 function openEditor(d=null){
  if(!area||drag||api.canDrag&&!api.canDrag())return;closeEditor();
  const form=document.createElement('form');form.id='pattern-origin-editor';const title=document.createElement('strong');title.textContent=d?`Distance to E${d.edge} · mm`:'Pattern Origin · Local X/Y · mm';form.append(title);
  const values=d?[d.value]:[...preview],inputs=values.map((value,i)=>{const label=document.createElement('label');label.textContent=d?'Distance':i?'Local Y':'Local X';const input=document.createElement('input');input.type='number';input.step='any';if(d)input.min='0';input.value=Number(value.toFixed(3));input.setAttribute('aria-label',d?`Distance to E${d.edge}`:i?'Pattern Origin Local Y':'Pattern Origin Local X');label.append(input);form.append(label);return input});
  const apply=document.createElement('button');apply.type='submit';apply.textContent='Apply · Enter';const dismiss=document.createElement('button');dismiss.type='button';dismiss.textContent='Cancel';dismiss.onclick=closeEditor;form.append(apply,dismiss);enableNumericExpressions(form);host.append(form);
  const state=editor={form,areaId:area.id,origin:[...preview],edge:d?.edge,anchor:d?d.start.map((n,i)=>(n+d.end[i])/2):worldPoint(area,preview)};
  form.onsubmit=e=>{e.preventDefault();if(editor!==state||area?.id!==state.areaId)return;try{const numbers=inputs.map(input=>input.value.trim()===''?NaN:Number(input.value));if(numbers.some(n=>!Number.isFinite(n)||Math.abs(n)>1e9))throw Error('กรอกตัวเลขไม่เกิน 1,000,000,000 mm');const point=state.edge?originAtEdgeDistance(area,state.origin,state.edge,numbers[0]):numbers;if(Math.hypot(...point.map((n,i)=>n-state.origin[i]))<1e-7){closeEditor();return}api.commit(state.areaId,point)}catch(error){inputs[0].setCustomValidity(error.message);inputs[0].reportValidity()}};
  inputs.forEach(input=>input.addEventListener('input',()=>input.setCustomValidity('')));update(api.camera(),view.clientWidth,view.clientHeight);inputs[0].focus();inputs[0].select();
 }
 const cancel=()=>finish(true);
 grip.addEventListener('pointerdown',e=>{
  if(api.canDrag&&!api.canDrag())return;
  if(e.button!==0||e.shiftKey||e.ctrlKey||e.metaKey||!area||document.querySelector('dialog[open]'))return;
  e.preventDefault();e.stopPropagation();closeEditor();grip.focus({preventScroll:true});api.start();drag={pointerId:e.pointerId,areaId:area.id,origin:[...area.pattern.origin],area:structuredClone(area),snap:createOriginSnap(area,api.panels?.(area.id)??[]),x:e.clientX,y:e.clientY,moved:false};grip.setPointerCapture(e.pointerId);grip.classList.add('dragging');grip.dataset.dragging='true';
 });
 grip.addEventListener('pointermove',e=>{
  if(!drag||e.pointerId!==drag.pointerId)return;e.preventDefault();if(Math.hypot(e.clientX-drag.x,e.clientY-drag.y)>3)drag.moved=true;if(!drag.moved)return;
  const camera=api.camera(),rect=view.getBoundingClientRect(),ray=new THREE.Raycaster();camera.updateMatrixWorld();ray.setFromCamera(new THREE.Vector2((e.clientX-rect.left)/rect.width*2-1,1-(e.clientY-rect.top)/rect.height*2),camera);
  const plane=new THREE.Plane().setFromNormalAndCoplanarPoint(new THREE.Vector3(...cross(drag.area.u,drag.area.v)),new THREE.Vector3(...drag.area.base)),hit=ray.ray.intersectPlane(plane,new THREE.Vector3());if(!hit)return;
  const distance=camera.position.distanceTo(hit),tolerance=api.pixelWorldSize(distance,rect.height)*14,result=drag.snap(localPoint(drag.area,hit.toArray()),tolerance,api.osmode(),drag.origin,originSnapScreen(drag.area,camera,rect,e.clientX,e.clientY)),point=result.point.map(n=>Math.round(n*1000)/1000);
  setPoint(point);api.preview(point,drag.areaId);api.feedback(result.type);
 });
 grip.addEventListener('pointerup',e=>{if(drag&&e.pointerId===drag.pointerId){e.preventDefault();finish()}});
 grip.addEventListener('pointercancel',cancel);grip.addEventListener('lostpointercapture',cancel);
 document.addEventListener('keydown',e=>{if((drag||editor)&&e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();closeEditor();cancel()}},true);
 window.addEventListener('blur',cancel);
 const project=(p,camera,w,h)=>{const v=new THREE.Vector3(...p).project(camera);return {x:(v.x+1)*w/2,y:(1-v.y)*h/2,z:v.z}};
 function update(camera,w,h){
  if(!area||!measurements)return;if(editor){const e=project(editor.anchor,camera,w,h);editor.form.style.left=Math.max(8,Math.min(w-230,e.x+18))+'px';editor.form.style.top=Math.max(8,Math.min(h-220,e.y+18))+'px'}grip.style.pointerEvents=api.canDrag&&!api.canDrag()?'none':'auto';const p=project(measurements.world,camera,w,h);grip.hidden=p.z< -1||p.z>1||p.x<0||p.x>w||p.y<0||p.y>h;grip.style.left=p.x+'px';grip.style.top=p.y+'px';svg.setAttribute('viewBox',`0 0 ${w} ${h}`);svg.style.display=document.querySelector('#dimensions-toggle')?.checked?'':'none';
  for(const {d,group,line,label,index}of items){const a=project(d.start,camera,w,h),b=project(d.end,camera,w,h),dx=b.x-a.x,dy=b.y-a.y,len=Math.hypot(dx,dy);group.style.display=a.z< -1||a.z>1||b.z< -1||b.z>1?'none':'';line.setAttribute('x1',a.x);line.setAttribute('y1',a.y);line.setAttribute('x2',b.x);line.setAttribute('y2',b.y);label.setAttribute('x',(a.x+b.x)/2+(len<24?26:0));label.setAttribute('y',(a.y+b.y)/2+(len<24?(index?22:-16):-8));}
 }
 return {select,update,cancel,get dragging(){return !!drag}};
}
