import {add,sub,mul,dot,cross,length,worldPoint,signedArea,validateArea} from './geometry.js';
import {curtainSettings,curtainOrigin} from './curtain-settings.js';
import {worldCurtainBasis} from './curtain-world.js';

export const JOIN_SHARED_KEYS=['followPatternOrigin','worldOrigin','worldAngle','joinMode','spacingX','spacingY','gap','gapAtBoundary','customX','customY'];
const tolerance=.1;
const raw=(frame,p)=>[dot(p,frame.x)+frame.offset[0],dot(p,frame.y)+frame.offset[1]];
const vec=(a,b)=>[b[0]-a[0],b[1]-a[1]];
const unit2=v=>{const d=Math.hypot(...v);return v.map(n=>n/d)};
const perp=v=>[-v[1],v[0]];
const dot2=(a,b)=>a[0]*b[0]+a[1]*b[1];
const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
const winding=points=>Math.sign(signedArea(points.map(p=>[p[0]-points[0][0],p[1]-points[0][1]])));
const cleanVector=v=>v.map(n=>n===0?0:n);

export function sharedEdges(areas){
 const polygons=areas.map(a=>a.outer.map(p=>worldPoint(a,p))),edges=[];let checks=0;
 const boxes=polygons.map(points=>[0,1,2].map(axis=>[Math.min(...points.map(p=>p[axis])),Math.max(...points.map(p=>p[axis]))]));
 for(let i=0;i<areas.length;i++)for(let j=i+1;j<areas.length;j++){
  if(boxes[i].some((range,k)=>range[1]<boxes[j][k][0]-tolerance||boxes[j][k][1]<range[0]-tolerance))continue;
  const a=polygons[i],b=polygons[j];
  for(let ai=0;ai<a.length;ai++)for(let bi=0;bi<b.length;bi++){
   if(++checks>5000000)throw Error('ขอบเขตซับซ้อนเกินสำหรับ Join กรุณาเลือก Area กลุ่มเล็กลง');
   const p=a[ai],q=a[(ai+1)%a.length],r=b[bi],s=b[(bi+1)%b.length];
   if(p.some((n,k)=>Math.max(n,q[k])<Math.min(r[k],s[k])-tolerance||Math.max(r[k],s[k])<Math.min(n,q[k])-tolerance))continue;
   const e=sub(q,p),f=sub(s,r),len=length(e),lenB=length(f);if(len<tolerance||lenB<tolerance)continue;
   const direction=mul(e,1/len);if(length(cross(direction,mul(f,1/lenB)))>1e-6||length(cross(sub(r,p),direction))>tolerance)continue;
   const t0=dot(sub(r,p),direction),t1=dot(sub(s,p),direction),low=Math.max(0,Math.min(t0,t1)),high=Math.min(len,Math.max(t0,t1));
   if(high-low>tolerance)edges.push({i,j,ai,bi,p:add(p,mul(direction,low)),q:add(p,mul(direction,high))});
  }
 }
 return {polygons,edges};
}

function unfold(areas,rootId,group,seed=null){
 const {polygons,edges}=sharedEdges(areas);let rootIndex=areas.findIndex(a=>a.id===rootId);if(rootIndex<0)rootIndex=0;rootId=areas[rootIndex].id;
 if(curtainSettings(areas[rootIndex]).joinMode!=='unfold'){
  const connected=new Set([rootIndex]),queue=[rootIndex];
  while(queue.length){const i=queue.shift();for(const e of edges){const j=e.i===i?e.j:e.j===i?e.i:null;if(j!==null&&!connected.has(j)){connected.add(j);queue.push(j)}}}
  if(connected.size!==areas.length)throw Error('Join ไม่สำเร็จ: Area ต้องมีขอบนอกชนกันเป็นแนวต่อเนื่อง · ไม่ได้เชื่อม '+areas.filter((a,i)=>!connected.has(i)).map(a=>a.name).join(', '));
  const root=curtainSettings(areas[rootIndex]),anchor=worldCurtainBasis(areas[rootIndex]),anchorId=seed?.anchorId||rootId;
  return areas.map(a=>{const c=curtainSettings(a),basis=worldCurtainBasis(a);for(const key of JOIN_SHARED_KEYS)c[key]=structuredClone(root[key]);c.reference='world';c.join={version:1,group,rootId,anchorId,x:cleanVector(basis.x),y:cleanVector(basis.y),offset:[0,0],anchorX:cleanVector(anchor.x),anchorY:cleanVector(anchor.y),anchorOffset:[0,0]};const next={...a,curtain:c};validateArea(next);return next});
 }
 const basis=worldCurtainBasis(areas[rootIndex]),useSeed=seed&&Math.abs(dot(seed.x,basis.normal))<1e-5&&Math.abs(dot(seed.y,basis.normal))<1e-5,anchorId=seed?.anchorId||seed?.rootId||rootId;
 let anchorX=useSeed?seed.anchorX:basis.x,anchorY=useSeed?seed.anchorY:basis.y,anchorOffset=useSeed?(seed.anchorOffset??[0,0]):[0,0];
 const frames=new Map([[rootIndex,useSeed?{x:seed.x,y:seed.y,offset:seed.offset}:{x:basis.x,y:basis.y,offset:[0,0]}]]),queue=[rootIndex];
 while(queue.length){const index=queue.shift(),parent=frames.get(index);
  for(const edge of edges){if(edge.i!==index&&edge.j!==index)continue;const child=edge.i===index?edge.j:edge.i;if(frames.has(child))continue;
   const childBasis=worldCurtainBasis(areas[child]),base={...childBasis,offset:[0,0]},p=raw(parent,edge.p),q=raw(parent,edge.q),cp=raw(base,edge.p),cq=raw(base,edge.q),u=unit2(vec(p,q)),v=unit2(vec(cp,cq));
   const parentEdge=edge.i===index?edge.ai:edge.bi,childEdge=edge.i===child?edge.ai:edge.bi;
   const edgeVector=(which,k,frame)=>vec(raw(frame,polygons[which][k]),raw(frame,polygons[which][(k+1)%polygons[which].length]));
   const sideParent=winding(polygons[index].map(p=>raw(parent,p)))*Math.sign(dot2(edgeVector(index,parentEdge,parent),u));
   const sideChild=winding(polygons[child].map(p=>raw(base,p)))*Math.sign(dot2(edgeVector(child,childEdge,base),v));
   const determinant=-sideParent*sideChild,pu=perp(u),pv=perp(v),m=[u[0]*v[0]+determinant*pu[0]*pv[0],u[0]*v[1]+determinant*pu[0]*pv[1],u[1]*v[0]+determinant*pu[1]*pv[0],u[1]*v[1]+determinant*pu[1]*pv[1]];
   const x=add(mul(base.x,m[0]),mul(base.y,m[1])),y=add(mul(base.x,m[2]),mul(base.y,m[3])),offset=[p[0]-m[0]*cp[0]-m[1]*cp[1],p[1]-m[2]*cp[0]-m[3]*cp[1]];
   frames.set(child,{x,y,offset});queue.push(child);
  }
 }
 if(frames.size!==areas.length)throw Error('Join ไม่สำเร็จ: Area ต้องมีขอบนอกชนกันเป็นแนวต่อเนื่อง · ไม่ได้เชื่อม '+areas.filter((a,i)=>!frames.has(i)).map(a=>a.name).join(', '));
 const anchorIndex=areas.findIndex(a=>a.id===anchorId);if(anchorIndex>=0){const frame=frames.get(anchorIndex);anchorX=frame.x;anchorY=frame.y;anchorOffset=frame.offset}
 const root=curtainSettings(areas[rootIndex]),angle=(root.worldAngle%360)*Math.PI/180,rotate=v=>[Math.cos(angle)*v[0]+Math.sin(angle)*v[1],-Math.sin(angle)*v[0]+Math.cos(angle)*v[1]],periodic=(value,spacing)=>Math.abs(value-Math.round(value/spacing)*spacing)<tolerance;
 for(const edge of edges){const a=frames.get(edge.i),b=frames.get(edge.j),p=rotate(vec(raw(a,edge.p),raw(b,edge.p))),q=rotate(vec(raw(a,edge.q),raw(b,edge.q)));
  if(Math.hypot(...p)<tolerance&&Math.hypot(...q)<tolerance)continue;
  if(!root.customX.length&&!root.customY.length&&Math.hypot(p[0]-q[0],p[1]-q[1])<tolerance&&periodic(p[0],root.spacingX)&&periodic(p[1],root.spacingY))continue;
  throw Error('แนว Area เป็นวงปิดหรือขอบซ้อนกันและกริดปิดรอบไม่ลงตัว · เลือกแนวเปิดสำหรับ Join หรือปรับ spacing ให้ลงตัวรอบอาคาร');
 }
 return areas.map((a,i)=>{const c=curtainSettings(a);for(const key of JOIN_SHARED_KEYS)c[key]=structuredClone(root[key]);c.reference='world';c.join={version:1,group,rootId,anchorId,x:cleanVector(frames.get(i).x),y:cleanVector(frames.get(i).y),offset:cleanVector(frames.get(i).offset),anchorX:cleanVector(anchorX),anchorY:cleanVector(anchorY),anchorOffset:cleanVector(anchorOffset)};const next={...a,curtain:c};validateArea(next);return next});
}

export function joinCurtainAreas(list,ids,rootId){
 const selected=list.filter(a=>ids.has(a.id));if(selected.length<2)throw Error('เลือกอย่างน้อย 2 Areas ที่มีขอบร่วมกัน');
 const groups=new Set(selected.map(a=>a.curtain?.join?.group).filter(Boolean));
 if(list.some(a=>groups.has(a.curtain?.join?.group)&&!ids.has(a.id)))throw Error('เลือกสมาชิกกลุ่ม Join เดิมให้ครบ หรือ Unjoin group ก่อน');
 const active=selected.find(a=>a.id===rootId)||selected[0],primary=curtainSettings(active),anchor=primary.reference==='world'?primary.worldOrigin:worldPoint(active,curtainOrigin(active).origin);
 const rootAngle=primary.reference==='world'?primary.worldAngle:0;
 const prepared=selected.map(a=>{const c=curtainSettings(a);delete c.join;c.enabled=true;c.reference='world';c.worldOrigin=[...anchor];c.worldAngle=rootAngle;for(const key of ['followPatternOrigin','joinMode','spacingX','spacingY','gap','gapAtBoundary','customX','customY'])c[key]=structuredClone(primary[key]);return {...a,curtain:c}});
 const joined=unfold(prepared,active.id,crypto.randomUUID(),primary.join),byId=new Map(joined.map(a=>[a.id,a]));return list.map(a=>byId.get(a.id)||a);
}

export function unjoinCurtainAreas(list,ids){
 const groups=new Set(list.filter(a=>ids.has(a.id)).map(a=>a.curtain?.join?.group).filter(Boolean));
 return list.map(a=>{if(!groups.has(a.curtain?.join?.group))return a;const c={...a.curtain};delete c.join;return {...a,curtain:c}});
}

export function refreshCurtainJoins(list){
 let next=list;const groups=new Set(list.map(a=>a.curtain?.join?.group).filter(Boolean));
 for(const group of groups){const members=next.filter(a=>a.curtain?.join?.group===group);if(members.length<2)continue;
  const rootId=members[0].curtain.join.rootId,root=members.find(a=>a.id===rootId)||members[0],updated=unfold(members,rootId,group,root.curtain.join),byId=new Map(updated.map(a=>[a.id,a]));next=next.map(a=>byId.has(a.id)&&!equal(a,byId.get(a.id))?byId.get(a.id):a);
 }
 return next;
}

export function propagateCurtainJoinChanges(previous,next){
 let result=next;const oldGroups=new Set(previous.map(a=>a.curtain?.join?.group).filter(Boolean));
 for(const group of oldGroups){const before=previous.filter(a=>a.curtain?.join?.group===group),after=before.map(a=>next.find(b=>b.id===a.id));
  if(after.some(a=>!a||a.curtain?.reference!=='world'||a.curtain?.join?.group!==group)){result=unjoinCurtainAreas(result,new Set(before.map(a=>a.id)));continue}
  const changes={},owners=new Set();for(let i=0;i<before.length;i++)if(before[i].curtain.join.anchorId!==after[i].curtain.join.anchorId)owners.add(after[i].curtain.join.anchorId);
  if(owners.size>1)throw Error('กลุ่ม Join ต้องใช้จุดอ้างอิงร่วมเพียงจุดเดียว');
  if(owners.size){const owner=[...owners][0];if(!after.some(a=>a.id===owner))throw Error('Pick Origin บน Area ในกลุ่ม Join');result=result.map(a=>a.curtain?.join?.group===group?{...a,curtain:{...a.curtain,join:{...a.curtain.join,anchorId:owner}}}:a)}
  for(let i=0;i<before.length;i++)for(const key of JOIN_SHARED_KEYS){const old=curtainSettings(before[i])[key],value=curtainSettings(after[i])[key];if(equal(old,value))continue;if(key in changes&&!equal(changes[key],value))throw Error('กลุ่ม Join ต้องใช้ Origin และระยะกริดร่วมกัน · ใช้ Pick shared curtain origin');changes[key]=value}
  if(Object.keys(changes).length)result=result.map(a=>a.curtain?.join?.group===group?{...a,curtain:{...a.curtain,...structuredClone(changes)}}:a);
 }
 return refreshCurtainJoins(result);
}

export function remapImportedCurtainJoins(incoming,current){
 const ids=new Set(current.map(a=>a.id)),map=new Map(),groups=new Map();
 for(const a of incoming){const id=ids.has(a.id)?crypto.randomUUID():a.id;ids.add(id);map.set(a.id,id);if(a.curtain?.join&&!groups.has(a.curtain.join.group))groups.set(a.curtain.join.group,crypto.randomUUID())}
 return incoming.map(a=>{const next=structuredClone(a);next.id=map.get(a.id);if(next.curtain?.join){const j=next.curtain.join;j.group=groups.get(j.group);j.rootId=map.get(j.rootId)||j.rootId;if(j.anchorId)j.anchorId=map.get(j.anchorId)||j.anchorId}return next});
}
