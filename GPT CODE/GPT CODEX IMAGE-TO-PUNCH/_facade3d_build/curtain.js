import {panelBendFaceRings,joinedPanelBendEdges} from './panel-bends.js';
import {panelCells,panelGrid} from './panel-tiling.js';
import './vendor/polygon-clipping.umd.js';
import {signedArea,inside,sub,dot,mul,add,length} from './geometry.js';
import {curtainSettings,validateCurtainSettings,curtainOrigin} from './curtain-settings.js';
import {insetBoundary,stableIntersection} from './boundary-offset.js';
import {worldCurtainFrame} from './curtain-world.js';
import {foldBoundaryMask} from './panel-fold-mask.js';
const clipping=globalThis.polygonClipping;
export const MAX_CURTAIN_CELLS=100000;
function intersection(a,b){try{return clipping.intersection(a,b)}catch{return stableIntersection(a,b)}}
const closed=loop=>[...loop.map(p=>[...p]),[...loop[0]]];
const clean=poly=>poly.map(r=>r.slice(0,-1)).filter(r=>r.length>=3&&Math.abs(signedArea(r))>.001);
const polygonArea=poly=>Math.abs(signedArea(poly[0]))-poly.slice(1).reduce((s,r)=>s+Math.abs(signedArea(r)),0);
export function curtainFrame(a){const settings=curtainSettings(a);if(settings.reference==='world')return worldCurtainFrame(a,settings);const f=curtainOrigin(a),r=f.angle*Math.PI/180,c=Math.cos(r),s=Math.sin(r),o=f.origin;return {to:p=>{const d=sub(p,o);return[c*d[0]+s*d[1],-s*d[0]+c*d[1]]},from:p=>[o[0]+c*p[0]-s*p[1],o[1]+s*p[0]+c*p[1]]}}
export function cutLines(min,max,spacing,custom=[],overrides={}){
 if(!Number.isFinite(min)||!Number.isFinite(max)||max<min||!Number.isFinite(spacing)||spacing<=0)throw Error('ขอบเขตกริดหรือ spacing ไม่ถูกต้อง');
 const count=Math.ceil(max/spacing)-Math.floor(min/spacing);if(count>MAX_CURTAIN_CELLS+1)throw Error(`กริดแกนเดียวประมาณ ${count.toLocaleString('en-US')} ช่อง เกินงบ ${MAX_CURTAIN_CELLS.toLocaleString('en-US')} ช่องต่อ Area · เพิ่ม Grid spacing (mm) หรือตรวจหน่วย DXF`);
 const values=[min,max,...custom.filter(v=>v>min+.001&&v<max-.001)];for(let k=Math.floor(min/spacing)+1;k*spacing<max-.001;k++)values.push(k*spacing);
 const adjusted=values.map(v=>v===min||v===max?v:overrides[String(Number(v.toFixed(6)))]??v).filter(v=>v>=min&&v<=max);
 adjusted.push(...Object.values(overrides).filter(v=>v>min&&v<max));
 const cuts=adjusted.sort((a,b)=>a-b).filter((v,i,a)=>!i||v-a[i-1]>.001);
 if(cuts.length-1>MAX_CURTAIN_CELLS)throw Error(`กริดแกนเดียว ${cuts.length-1} ช่อง เกินงบ ${MAX_CURTAIN_CELLS} ช่องต่อ Area · เพิ่ม spacing หรือลด Additional grid lines`);
 return cuts;
}
export function clipLine(start,end,outer,holes){
 const direction=sub(end,start),ts=[0,1],cross2=(a,b)=>a[0]*b[1]-a[1]*b[0];
 for(const ring of [outer,...holes])for(let i=0;i<ring.length;i++){
  const a=ring[i],b=ring[(i+1)%ring.length],edge=sub(b,a),den=cross2(direction,edge);if(Math.abs(den)<1e-9)continue;const diff=sub(a,start),t=cross2(diff,edge)/den,u=cross2(diff,direction)/den;if(t>=0&&t<=1&&u>=-1e-8&&u<=1+1e-8)ts.push(t);
 }
 const sorted=ts.sort((a,b)=>a-b).filter((t,i,a)=>!i||t-a[i-1]>1e-8),result=[];
 for(let i=0;i<sorted.length-1;i++){const t0=sorted[i],t1=sorted[i+1],p=add(start,mul(direction,(t0+t1)/2));if(inside(p,outer)&&!holes.some(h=>inside(p,h)))result.push([add(start,mul(direction,t0)),add(start,mul(direction,t1))])}
 return result;
}
export function buildCurtainLayout(a){
 const c=curtainSettings(a);validateCurtainSettings(c);if(!c.enabled)return null;
 const frame=curtainFrame(a),outer=a.outer.map(frame.to),holes=a.holes.map(h=>h.map(frame.to)),mask=[[closed(outer),...holes.map(closed)]];
 const offsetMask=c.gapAtBoundary&&c.gap>0?insetBoundary(outer,c.gap/2):null;
 const panelMask=offsetMask?offsetMask.length?intersection(mask,offsetMask):[]:mask;
 const xs=outer.map(p=>p[0]),ys=outer.map(p=>p[1]),bounds=[Math.min(...xs),Math.min(...ys),Math.max(...xs),Math.max(...ys)];
 const xCuts=cutLines(bounds[0],bounds[2],c.spacingX,c.customX,c.cutOverridesX),yCuts=cutLines(bounds[1],bounds[3],c.spacingY,c.customY,c.cutOverridesY);
 const nx=xCuts.length-1,ny=yCuts.length-1;
 if(nx*ny>MAX_CURTAIN_CELLS)throw Error(`กริด ${nx} × ${ny} = ${(nx*ny).toLocaleString('en-US')} ช่อง เกิน ${MAX_CURTAIN_CELLS.toLocaleString('en-US')} ช่องต่อ Area · เพิ่ม Grid X / Grid Y (mm) หรือตรวจหน่วย DXF`);
 const cells=panelCells(xCuts,yCuts,c.panelPatches||[],c.overrides),panels=[],grid=[],mullions=[];
 const intersect=(poly,clipMask=mask)=>clipMask.length?intersection(clipMask,[[closed(poly)]]).map(clean).filter(p=>p.length&&polygonArea(p)>.01):[];
 for(const cell of cells){const b=cell.bounds;
  const [x0,x1,y0,y1]=[b[0]+(b[0]>bounds[0]+.001?c.gap/2:0),b[2]-(b[2]<bounds[2]-.001?c.gap/2:0),b[1]+(b[1]>bounds[1]+.001?c.gap/2:0),b[3]-(b[3]<bounds[3]-.001?c.gap/2:0)];if(x1<=x0||y1<=y0)continue;
  const polys=intersect([[x0,y0],[x1,y0],[x1,y1],[x0,y1]],panelMask);
  polys.forEach((poly,k)=>{const key=`${Number(b[0].toFixed(3))}:${Number(b[1].toFixed(3))}:${k}`,fold=c.panelJoins[key];
   if(fold&&c.gapAtBoundary&&c.gap>0){const selective=intersection(mask,foldBoundaryMask(outer,c.gap/2,fold.edges)),restored=intersect([[x0,y0],[x1,y0],[x1,y1],[x0,y1]],selective);if(restored.length!==1)throw Error('ขอบ Folded panel เปลี่ยนไป กรุณา Unjoin panels ก่อนปรับกริด');poly=restored[0]}
   panels.push({key,name:'P'+String(panels.length+1).padStart(3,'0'),rings:poly.map(r=>r.map(frame.from)),cell:[...b],type:c.overrides[key]||cell.override||c.panelType,area:polygonArea(poly)/1e6,width:x1-x0,height:y1-y0,...(fold?{foldGroup:fold.group,foldEdges:fold.edges}:{})})});
 }
 function addMember(start,end,kind){
  const d=sub(end,start),len=length(d);if(len<.01)return;const half=kind==='grid'?c.mullionWidth/2:c.mullionWidth,n=[-d[1]/len*half,d[0]/len*half];
  const polygons=intersect([add(start,n),add(end,n),sub(end,n),sub(start,n)]);
  if(polygons.length)mullions.push({kind,length:len,rings:polygons.map(p=>p.map(r=>r.map(frame.from)))});
 }
 if(c.panelPatches?.length){for(const [p,q]of panelGrid(cells,bounds))for(const segment of clipLine(p,q,outer,holes)){grid.push(segment.map(frame.from));addMember(...segment,'grid')}}else{
 for(const x of xCuts.slice(1,-1))for(const segment of clipLine([x,bounds[1]],[x,bounds[3]],outer,holes)){grid.push(segment.map(frame.from));addMember(...segment,'grid')}
 for(const y of yCuts.slice(1,-1))for(const segment of clipLine([bounds[0],y],[bounds[2],y],outer,holes)){grid.push(segment.map(frame.from));addMember(...segment,'grid')}
 }
 if(c.boundary)outer.forEach((p,i)=>addMember(p,outer[(i+1)%outer.length],'boundary'));
 if(c.openings)holes.forEach(h=>h.forEach((p,i)=>addMember(p,h[(i+1)%h.length],'opening')));
 for(const panel of panels)if(panel.foldEdges)panel.joinedEdges=joinedPanelBendEdges(a,panel);
 for(const panel of panels)if(c.panelBends[panel.key])panelBendFaceRings(panel,c.panelBends[panel.key],c.panelThickness);
 return {panels,grid,mullions,cells,bounds,settings:c,panelArea:panels.filter(p=>p.type!=='open').reduce((s,p)=>s+p.area,0),mullionLength:mullions.reduce((s,m)=>s+m.length,0)/1000};
}
