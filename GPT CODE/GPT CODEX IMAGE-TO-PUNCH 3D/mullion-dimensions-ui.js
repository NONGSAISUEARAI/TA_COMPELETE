import * as THREE from 'three';
import {mullionMeasurement} from './mullion-measurement.js';
export function setupMullionDimensions(view,getSelection){
 const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');svg.id='mullion-property-dimensions';svg.setAttribute('aria-label','Dimensions of focused Mullion property');svg.setAttribute('hidden','');view.append(svg);let previous=[],previousKind=null,items=[];
 const el=(tag,attributes={})=>{const node=document.createElementNS(ns,tag);for(const [k,v]of Object.entries(attributes))node.setAttribute(k,v);return node};
 const project=(p,camera,w,h)=>{const v=new THREE.Vector3(...p).project(camera);return {x:(v.x+1)*w/2,y:(1-v.y)*h/2,z:v.z}};
 const line=(node,a,b)=>{for(const [k,v]of Object.entries({x1:a.x,y1:a.y,x2:b.x,y2:b.y}))node.setAttribute(k,v)};
 function rebuild(entries,kind){svg.replaceChildren();items=entries.map(({area,layout})=>mullionMeasurement(area,layout,kind)).filter(Boolean).map(spec=>{
 const group=el('g',{'data-kind':kind,'data-area-id':spec.areaId,'data-value':spec.value,'data-start':spec.start.join(','),'data-end':spec.end.join(',')}),title=el('title');title.textContent=`${spec.areaName} · ${spec.label}`;
 const outline=el('path',{class:'mullion-measure-section'}),extensions=[el('line',{class:'mullion-measure-extension'}),el('line',{class:'mullion-measure-extension'})],dim=el('line',{class:'mullion-measure-line'}),arrows=[el('path',{class:'mullion-measure-arrow'}),el('path',{class:'mullion-measure-arrow'})],ends=[el('circle',{r:3}),el('circle',{r:3})],label=el('g',{class:'mullion-measure-label'}),text=el('text',{'text-anchor':'middle','dominant-baseline':'central'});text.textContent=`${spec.label} · ${Number(spec.value.toFixed(3)).toLocaleString('en-US')} mm`;const width=Math.max(90,text.textContent.length*6.5+16);label.append(el('rect',{x:-width/2,y:-12,width,height:24,rx:4}),text);group.append(title,outline,...extensions,dim,...arrows,...ends,label);svg.append(group);return {spec,group,outline,extensions,dim,arrows,ends,label};});}
 function update(camera,w,h){const input=document.activeElement,kind=input?.dataset?.cw,active=['mullionWidth','mullionDepth','mullionOffset'].includes(kind)&&!input.disabled&&input.offsetParent!==null;if(!active||!w||!h){svg.setAttribute('hidden','');return}const entries=getSelection();if(kind!==previousKind||entries.length!==previous.length||entries.some((e,i)=>e.area!==previous[i].area||e.layout!==previous[i].layout)){rebuild(entries,kind);previous=entries;previousKind=kind}
 svg.toggleAttribute('hidden',!items.length);if(!items.length)return;svg.setAttribute('viewBox',`0 0 ${w} ${h}`);
 for(const {spec,group,outline,extensions,dim,arrows,ends,label}of items){const a=project(spec.start,camera,w,h),b=project(spec.end,camera,w,h),mid={x:(a.x+b.x)/2,y:(a.y+b.y)/2},distance=Math.hypot(b.x-a.x,b.y-a.y),hidden=[a,b].some(p=>p.z< -1||p.z>1)||mid.x< -30||mid.x>w+30||mid.y< -30||mid.y>h+30;group.style.display=hidden?'none':'';if(hidden)continue;
 const section=spec.section.map(p=>project(p,camera,w,h));outline.setAttribute('d',section.map((p,i)=>`${i?'L':'M'} ${p.x} ${p.y}`).join(' ')+' Z');for(let i=0;i<2;i++){ends[i].setAttribute('cx',(i?b:a).x);ends[i].setAttribute('cy',(i?b:a).y)}
 if(distance<6){group.dataset.projection='end-on';line(extensions[0],a,{x:a.x+55,y:a.y-38});extensions[1].style.display='none';dim.style.display='none';arrows.forEach(node=>node.style.display='none');label.setAttribute('transform',`translate(${Math.max(100,Math.min(w-100,a.x+70))},${Math.max(18,a.y-52)})`);continue}
 group.dataset.projection='measurable';extensions[1].style.display='';dim.style.display='';arrows.forEach(node=>node.style.display='');const d={x:(b.x-a.x)/distance,y:(b.y-a.y)/distance},normal={x:-d.y,y:d.x},shift=p=>({x:p.x+normal.x*28,y:p.y+normal.y*28}),p=shift(a),q=shift(b);line(extensions[0],a,p);line(extensions[1],b,q);line(dim,p,q);
 for(let i=0;i<2;i++){const tip=i?q:p,sign=(i?-1:1)*(distance<30?-1:1),base={x:tip.x+d.x*7*sign,y:tip.y+d.y*7*sign};arrows[i].setAttribute('d',`M ${tip.x} ${tip.y} L ${base.x+normal.x*3} ${base.y+normal.y*3} L ${base.x-normal.x*3} ${base.y-normal.y*3} Z`)}
 label.setAttribute('transform',`translate(${Math.max(100,Math.min(w-100,mid.x+normal.x*48))},${Math.max(18,Math.min(h-18,mid.y+normal.y*48))})`);
 }
 }
 return {update};
}
