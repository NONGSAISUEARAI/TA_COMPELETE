import {add,sub,mul,dot,length,inside} from './geometry.js';
import {objectSnap,snapEnabled} from './osnap.js';
import {curtainFrame,cutLines} from './curtain.js';
import {curtainSettings} from './curtain-settings.js';
import {panelCells} from './panel-tiling.js';

export function createOriginSnap(area,panels=[]){
 // Freeze the rendered panel geometry at drag start: an inherited pattern must
 // not move its own snap targets while its Origin is being dragged.
 const cell=Math.max(50,Math.min(area.curtain?.spacingX??1000,area.curtain?.spacingY??1000)/2),buckets=new Map();
 const settings=curtainSettings(area),frame=settings.enabled?curtainFrame(area):null,gridCuts=frame?[0,1].map(axis=>{const points=area.outer.map(frame.to).map(p=>p[axis]),suffix=axis?'Y':'X';return cutLines(Math.min(...points),Math.max(...points),settings['spacing'+suffix],settings['custom'+suffix],settings['cutOverrides'+suffix])}):null;
 const insert=(point,type,bit)=>{const key=point.map(n=>Math.floor(n/cell)).join(',');if(!buckets.has(key))buckets.set(key,[]);buckets.get(key).push({point,type,bit})};
 if(frame&&settings.panelPatches?.length)for(const {bounds:b}of panelCells(gridCuts[0],gridCuts[1],settings.panelPatches))for(const q of [[b[0],b[1]],[b[2],b[1]],[b[2],b[3]],[b[0],b[3]]]){const point=frame.from(q);if(inside(point,area.outer)&&!area.holes.some(h=>inside(point,h)))insert(point,'Joint center',2|1024)}
 for(const panel of panels){if(panel.type==='open')continue;
  for(const loop of panel.rings)for(let i=0;i<loop.length;i++){insert(loop[i],'Panel corner',1);insert(mul(add(loop[i],loop[(i+1)%loop.length]),.5),'Panel midpoint',2)}
  const ring=panel.rings[0];let sum=0,x=0,y=0;for(let i=0;i<ring.length;i++){const p=ring[i],q=ring[(i+1)%ring.length],c=p[0]*q[1]-q[0]*p[1];sum+=c;x+=(p[0]+q[0])*c;y+=(p[1]+q[1])*c}
  if(Math.abs(sum)>1e-9){const center=[x/(3*sum),y/(3*sum)];if(inside(center,ring)&&!panel.rings.slice(1).some(h=>inside(center,h)))insert(center,'Panel center',2|1024)}
 }
 return (p,tolerance,mode,reference,screen=null)=>{
  const distanceTo=screen?.distance??(point=>length(sub(point,p))),radius=screen?.radius??tolerance;
  const boundary=objectSnap(p,area,radius,mode,reference,distanceTo);if(!snapEnabled(mode))return boundary;
  let best=boundary.type&&boundary.type!=='Nearest'?{...boundary,distance:distanceTo(boundary.point)}:null;
  const consider=t=>{if(!(mode&t.bit))return;const distance=distanceTo(t.point);if(distance<=radius&&(!best||distance<best.distance))best={point:[...t.point],type:t.type,distance}};
  const bounds=screen?.bounds??p.map(n=>[n-tolerance,n+tolerance]),low=bounds.map(b=>Math.floor(b[0]/cell)),high=bounds.map(b=>Math.floor(b[1]/cell));
  if((high[0]-low[0]+1)*(high[1]-low[1]+1)<=4096){for(let x=low[0];x<=high[0];x++)for(let y=low[1];y<=high[1];y++)for(const t of buckets.get(`${x},${y}`)??[])consider(t)}else for(const bucket of buckets.values())for(const t of bucket)consider(t);
  if(frame){
   const q=frame.to(p),nearest=(value,cuts)=>{let low=0,high=cuts.length-1;while(low<high){const middle=Math.floor((low+high)/2);if(cuts[middle]<value)low=middle+1;else high=middle}const a=cuts[low],b=cuts[Math.max(0,low-1)];return Math.abs(a-value)<Math.abs(b-value)?a:b};
   let xs=[nearest(q[0],gridCuts[0])],ys=[nearest(q[1],gridCuts[1])];
   if(screen){const corners=bounds[0].flatMap(x=>bounds[1].map(y=>frame.to([x,y]))),ranges=[0,1].map(axis=>[Math.min(...corners.map(p=>p[axis])),Math.max(...corners.map(p=>p[axis]))]);xs=gridCuts[0].filter(x=>x>=ranges[0][0]&&x<=ranges[0][1]);ys=gridCuts[1].filter(y=>y>=ranges[1][0]&&y<=ranges[1][1])}
   for(const x of xs)for(const y of ys){if(settings.panelPatches?.some(p=>x>=p.bounds[0]-.001&&x<=p.bounds[2]+.001&&y>=p.bounds[1]-.001&&y<=p.bounds[3]+.001))continue;const point=frame.from([x,y]);if(inside(point,area.outer)&&!area.holes.some(h=>inside(point,h)))consider({point,type:'Joint center',bit:2|1024})}
  }
  if(!area.curtain?.enabled){
   const a=area.pattern.angle*Math.PI/180,x=[Math.cos(a),Math.sin(a)],y=[-Math.sin(a),Math.cos(a)],d=sub(p,area.pattern.origin),spacing=area.pattern.spacing,u=dot(d,x)/spacing,v=dot(d,y)/spacing;
   for(const [shift,type,bit]of [[0,'Pattern corner',1],[.5,'Pattern center',2|1024]]){const point=add(area.pattern.origin,add(mul(x,(Math.round(u-shift)+shift)*spacing),mul(y,(Math.round(v-shift)+shift)*spacing)));if(inside(point,area.outer)&&!area.holes.some(h=>inside(point,h)))consider({point,type,bit})}
  }
  return best?{point:best.point,type:best.type}:boundary;
 };
}
