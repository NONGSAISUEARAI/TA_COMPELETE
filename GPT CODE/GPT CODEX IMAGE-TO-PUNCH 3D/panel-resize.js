import {curtainSettings} from './curtain-settings.js';
import {curtainFrame,buildCurtainLayout} from './curtain.js';
import {validateFoldedSheetLimits} from './folded-panel-resize.js';
import {resizedStrip,cellKey} from './panel-tiling.js';
import {foldedAssemblies} from './panel-folds.js';
import {boundaryCorners} from './dimensions.js';
import {length,sub} from './geometry.js';
const eps=.02,rounded=n=>Number(n.toFixed(3));

export function panelDimensions(area,panel){
 if(!panel||panel.rings.length!==1||panel.rings[0].length!==4)throw Error('แก้ Width / Height ได้เมื่อ Panel เป็นแผ่นสี่เหลี่ยม');
 const frame=curtainFrame(area),points=panel.rings[0].map(frame.to),low=[0,1].map(k=>Math.min(...points.map(p=>p[k]))),high=[0,1].map(k=>Math.max(...points.map(p=>p[k])));
 if(!points.every(p=>[0,1].every(k=>Math.min(Math.abs(p[k]-low[k]),Math.abs(p[k]-high[k]))<eps)))throw Error('ขอบ Panel ต้องขนานกับแกนกริด');
 return {width:high[0]-low[0],height:high[1]-low[1],low,high,frame};
}

export function resizePanel(areas,areaId,key,property,value){
 if(!['width','height'].includes(property)||!Number.isFinite(value)||value<1||value>1e6)throw Error('กรอกขนาดตั้งแต่ 1 ถึง 1,000,000 mm');
 const old=areas.find(a=>a.id===areaId),oldLayout=old&&buildCurtainLayout(old),panel=oldLayout?.panels.find(p=>p.key===key);if(!panel)throw Error('เลือก Panel ก่อน');if(panel.foldGroup)throw Error('แผ่นพับต้องแก้ขนาดทั้งชิ้นร่วมกัน');
 const m=panelDimensions(old,panel),axis=property==='width'?0:1,origin=m.frame.to(old.pattern.origin),pivot=Math.max(m.low[axis],Math.min(m.high[axis],origin[axis])),fraction=(pivot-m.low[axis])/(m.high[axis]-m.low[axis]),low=pivot-fraction*value,high=low+value;
 if(Math.abs(m[property]-value)<eps)return {areas,key};
 const a=structuredClone(old),c=curtainSettings(a),saved=c.panelSizes?.[key]?.patchReset,before=saved?.before??structuredClone(c.panelPatches||[]),extent=oldLayout.bounds,margin=c.gapAtBoundary?c.gap/2:0;
 if(low<extent[axis]+margin-eps||high>extent[axis+2]-margin+eps)throw Error('ขนาดที่กรอกเกินขอบ Area');
 const rawLow=Math.abs(low-(extent[axis]+margin))<eps?extent[axis]:low-c.gap/2,rawHigh=Math.abs(high-(extent[axis+2]-margin))<eps?extent[axis+2]:high+c.gap/2;
 const selected=oldLayout.cells.find(cell=>cell.bounds.every((v,i)=>Math.abs(v-panel.cell[i])<eps));
 const patch=resizedStrip(oldLayout.cells,selected,axis,rawLow,rawHigh,extent,c[axis?'spacingY':'spacingX']),mapping=new Map(patch.cells.filter(cell=>cell.source).map(cell=>[cell.source,cellKey(cell.bounds)]));
 for(const cell of patch.cells){if(cell.source&&c.overrides[cell.source])cell.override=c.overrides[cell.source];delete cell.source}
 for(const field of ['panelJoins','overrides','panelSizes','panelBends']){const out={};for(const [key,v]of Object.entries(c[field]||{})){const source=oldLayout.cells.find(cell=>cellKey(cell.bounds)===key),other=1-axis;if(field==='overrides'&&source&&(source.bounds[other]<patch.bounds[other]-.001||source.bounds[other+2]>patch.bounds[other+2]+.001))out[key]=v;out[mapping.get(key)??key]=v}c[field]=out}
 c.panelPatches=[...(c.panelPatches||[]),patch];
 a.curtain=c;const sample=[(m.low[0]+m.high[0])/2,(m.low[1]+m.high[1])/2];sample[axis]=(low+high)/2;
 const desired=m.frame.from(sample),layout=buildCurtainLayout(a),pointInside=(p,ring)=>{let result=false;for(let i=0,j=ring.length-1;i<ring.length;j=i++){const q=ring[i],r=ring[j];if((q[1]>p[1])!==(r[1]>p[1])&&p[0]<(r[0]-q[0])*(p[1]-q[1])/(r[1]-q[1])+q[0])result=!result}return result};
 const selectedPanel=layout.panels.find(p=>pointInside(desired,p.rings[0]));if(!selectedPanel)throw Error('ขนาดที่กรอกไม่อยู่ใน Area');const actual=panelDimensions(a,selectedPanel);
 if(Math.abs(actual[property]-value)>eps)throw Error('ขนาดที่กรอกเกินขอบ Area หรือช่องเปิด');
 c.panelSizes[selectedPanel.key]={patchReset:{before,after:structuredClone(c.panelPatches),key:saved?.key??key,mapBack:{...saved?.mapBack,...Object.fromEntries([...mapping].map(([from,to])=>[to,saved?.mapBack?.[from]??from]))}}};
 const next=areas.map(item=>item.id===areaId?a:item);validateFoldedSheetLimits(foldedAssemblies(next));return {areas:next,key:selectedPanel.key};
}

export function resizePanelEdge(areas,areaId,key,edgeIndex,value){
 if(!Number.isFinite(value)||value<1||value>1e6)throw Error('กรอกระยะตั้งแต่ 1 ถึง 1,000,000 mm');
 const old=areas.find(a=>a.id===areaId),oldLayout=old&&buildCurtainLayout(old),panel=oldLayout?.panels.find(p=>p.key===key);if(!panel)throw Error('เลือก Panel ก่อน');if(panel.foldGroup)throw Error('แผ่นพับต้องแก้ขนาดทั้งชิ้นร่วมกัน');
 const corners=boundaryCorners(panel.rings[0]),p=corners[edgeIndex],q=corners[(edgeIndex+1)%corners.length];if(!p||!q)throw Error('ไม่พบขอบแผ่นที่เลือก');const oldLength=length(sub(q,p));if(Math.abs(oldLength-value)<eps)return {areas,key};
 const frame=curtainFrame(old),origin=frame.to(old.pattern.origin),ends=[frame.to(p),frame.to(q)].sort((a,b)=>length(sub(a,origin))-length(sub(b,origin))),fixed=ends[0],delta=sub(ends[1],fixed),direction=delta.map(n=>n/oldLength),target=fixed.map((n,i)=>n+direction[i]*value),extent=oldLayout.bounds;
 const selected=oldLayout.cells.find(cell=>cell.bounds.every((v,i)=>Math.abs(v-panel.cell[i])<eps));let failure=null;
 for(const axis of [0,1].sort((a,b)=>Math.abs(direction[b])-Math.abs(direction[a]))){
  if(Math.abs(direction[axis])<1e-7)continue;
  try{
   const a=structuredClone(old),c=curtainSettings(a),saved=c.panelSizes?.[key]?.patchReset,before=saved?.before??structuredClone(c.panelPatches||[]),sign=Math.sign(direction[axis]),margin=c.gapAtBoundary?c.gap/2:0;
   const finished=sign>0?extent[axis+2]-margin:extent[axis]+margin;if(sign*(target[axis]-finished)>eps)throw Error('ระยะที่กรอกเกินขอบ Area');
   const raw=Math.abs(target[axis]-finished)<eps?(sign>0?extent[axis+2]:extent[axis]):target[axis]+sign*c.gap/2,low=sign<0?raw:panel.cell[axis],high=sign>0?raw:panel.cell[axis+2];if(high-low<c.gap+.001)continue;
   const patch=resizedStrip(oldLayout.cells,selected,axis,low,high,extent,c[axis?'spacingY':'spacingX']),mapping=new Map(patch.cells.filter(cell=>cell.source).map(cell=>[cell.source,cellKey(cell.bounds)]));
   for(const cell of patch.cells){if(cell.source&&c.overrides[cell.source])cell.override=c.overrides[cell.source];delete cell.source}
   for(const field of ['panelJoins','overrides','panelSizes','panelBends']){const out={};for(const [oldKey,v]of Object.entries(c[field]||{})){const source=oldLayout.cells.find(cell=>cellKey(cell.bounds)===oldKey),other=1-axis;if(field==='overrides'&&source&&(source.bounds[other]<patch.bounds[other]-.001||source.bounds[other+2]>patch.bounds[other+2]+.001))out[oldKey]=v;out[mapping.get(oldKey)??oldKey]=v}c[field]=out}
   c.panelPatches=[...(c.panelPatches||[]),patch];a.curtain=c;const layout=buildCurtainLayout(a),desired=[...panel.cell];desired[axis]=low;desired[axis+2]=high;
   const result=layout.panels.find(candidate=>candidate.cell.every((v,i)=>Math.abs(v-desired[i])<eps)&&boundaryCorners(candidate.rings[0]).some((point,i,ring)=>{const start=frame.to(point),end=frame.to(ring[(i+1)%ring.length]);return (length(sub(start,fixed))<eps&&length(sub(end,target))<eps)||(length(sub(end,fixed))<eps&&length(sub(start,target))<eps)}));
   if(!result)throw Error('ขอบที่เลือกติดขอบ Area หรือช่องเปิด · ไม่สามารถปรับถึงระยะนี้โดยคงจุดยึดเดิม');
   c.panelSizes[result.key]={patchReset:{before,after:structuredClone(c.panelPatches),key:saved?.key??key,mapBack:{...saved?.mapBack,...Object.fromEntries([...mapping].map(([from,to])=>[to,saved?.mapBack?.[from]??from]))}}};
   const next=areas.map(item=>item.id===areaId?a:item);validateFoldedSheetLimits(foldedAssemblies(next));return {areas:next,key:result.key};
  }catch(error){failure=error}
 }
 throw failure??Error('ขอบนี้ไม่สามารถปรับระยะด้วยแนวกริดปัจจุบัน');
}
