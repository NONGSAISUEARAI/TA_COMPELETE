import * as THREE from 'three';
import {boxHitsPolygon} from './selection-box-hit.js';
function projectRing(points,camera,width,height){
 let vertices=points.map(p=>new THREE.Vector4(...p,1).applyMatrix4(camera.matrixWorldInverse).applyMatrix4(camera.projectionMatrix));
 for(const distance of [v=>v.w+v.z,v=>v.w-v.z,v=>v.w-1e-6]){const out=[];for(let i=0;i<vertices.length;i++){const a=vertices[i],b=vertices[(i+1)%vertices.length],da=distance(a),db=distance(b);if(da>=0)out.push(a);if((da>=0)!==(db>=0))out.push(a.clone().lerp(b,da/(da-db)))}vertices=out;if(!out.length)return []}
 return vertices.map(v=>[(v.x/v.w+1)*width/2,(1-v.y/v.w)*height/2]);
}
export function selectProjectedItems(items,camera,width,height,rect,crossing){
 camera.updateMatrixWorld();const selected=[];for(const item of items){const parts=(item.parts??[item.rings]).map(rings=>rings.map(ring=>projectRing(ring,camera,width,height))).filter(rings=>rings[0].length);if(parts.length&&(crossing?parts.some(rings=>boxHitsPolygon(rings,rect,true)):parts.every(rings=>boxHitsPolygon(rings,rect,false))))selected.push(item)}return selected;
}
export function setupBoxSelection(view,canvas,api){
 const box=document.createElement('div');box.id='selection-box';box.hidden=true;box.setAttribute('aria-hidden','true');view.append(box);let drag=null;
 function finish(cancelled,e){if(!drag)return;const state=drag;drag=null;box.hidden=true;if(canvas.hasPointerCapture(state.id))canvas.releasePointerCapture(state.id);if(state.active){api.end();if(!cancelled){const rect=view.getBoundingClientRect(),x=e.clientX-rect.left,y=e.clientY-rect.top,r=[Math.min(state.x,x),Math.min(state.y,y),Math.max(state.x,x),Math.max(state.y,y)];api.apply(selectProjectedItems(api.items(),api.camera(),rect.width,rect.height,r,x<state.x),state.add,state.remove)}else api.cancelled()}else if(cancelled)api.cancelled()}
 canvas.addEventListener('pointerdown',e=>{if(e.button!==0||!api.canStart())return;const r=view.getBoundingClientRect();drag={id:e.pointerId,x:e.clientX-r.left,y:e.clientY-r.top,add:e.shiftKey||e.ctrlKey||e.metaKey,remove:e.ctrlKey||e.metaKey,active:false}},true);
 canvas.addEventListener('pointermove',e=>{if(!drag||drag.id!==e.pointerId)return;const r=view.getBoundingClientRect(),x=e.clientX-r.left,y=e.clientY-r.top;if(!drag.active&&Math.hypot(x-drag.x,y-drag.y)<6)return;if(!drag.active){drag.active=true;canvas.setPointerCapture(e.pointerId);api.start()}e.preventDefault();e.stopImmediatePropagation();box.hidden=false;box.classList.toggle('crossing',x<drag.x);box.style.left=Math.min(x,drag.x)+'px';box.style.top=Math.min(y,drag.y)+'px';box.style.width=Math.abs(x-drag.x)+'px';box.style.height=Math.abs(y-drag.y)+'px'},true);
 canvas.addEventListener('pointerup',e=>{if(drag&&drag.id!==e.pointerId)return;if(drag?.active){e.preventDefault();e.stopImmediatePropagation();finish(false,e)}else drag=null},true);
 const cancel=()=>finish(true);canvas.addEventListener('pointercancel',cancel);canvas.addEventListener('lostpointercapture',cancel);window.addEventListener('blur',cancel);document.addEventListener('keydown',e=>{if(drag?.active&&e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();cancel()}},true);
 return {cancel,get active(){return !!drag?.active}};
}
