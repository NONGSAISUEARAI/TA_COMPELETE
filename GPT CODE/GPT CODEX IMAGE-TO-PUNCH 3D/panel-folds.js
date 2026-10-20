import {worldPoint,sub,mul,dot,cross,length} from './geometry.js';
import {curtainSettings} from './curtain-settings.js';
import {buildCurtainLayout} from './curtain.js';
import {sharedEdges} from './curtain-join.js';
import {convexBoundary} from './panel-fold-mask.js';

export const panelRef=(areaId,key)=>JSON.stringify([areaId,key]);
export const parsePanelRef=ref=>{const [areaId,key]=JSON.parse(ref);return {areaId,key}};
const tolerance=.15;
function trace(a,panel,edge){
 const direction=mul(sub(edge.q,edge.p),1/length(sub(edge.q,edge.p))),extent=length(sub(edge.q,edge.p)),intervals=[];
 for(const ring of panel.rings)for(let i=0;i<ring.length;i++){
  const p=worldPoint(a,ring[i]),q=worldPoint(a,ring[(i+1)%ring.length]);if(length(cross(sub(p,edge.p),direction))>tolerance||length(cross(sub(q,edge.p),direction))>tolerance)continue;
  const t=dot(sub(p,edge.p),direction),u=dot(sub(q,edge.p),direction),low=Math.max(0,Math.min(t,u)),high=Math.min(extent,Math.max(t,u));if(high-low>1)intervals.push([low,high]);
 }
 if(!intervals.length)return null;intervals.sort((a,b)=>a[0]-b[0]);let low=intervals[0][0],high=intervals[0][1];for(const r of intervals.slice(1)){if(r[0]>high+tolerance)return null;high=Math.max(high,r[1])}return {low,high,direction};
}
function connections(members,requireStoredEdges=false){
 const areas=[...new Map(members.map(m=>[m.a.id,m.a])).values()],{edges}=sharedEdges(areas),result=[];
 for(let i=0;i<members.length;i++)for(let j=i+1;j<members.length;j++){
  const a=members[i],b=members[j];if(a.a.id===b.a.id)continue;
  if(Math.abs(dot(cross(a.a.u,a.a.v),cross(b.a.u,b.a.v)))>1-1e-6)continue;
  for(const e of edges){let ai,bi;if(areas[e.i].id===a.a.id&&areas[e.j].id===b.a.id){ai=e.ai;bi=e.bi}else if(areas[e.j].id===a.a.id&&areas[e.i].id===b.a.id){ai=e.bi;bi=e.ai}else continue;
   if(requireStoredEdges&&(!a.panel.foldEdges?.includes(ai)||!b.panel.foldEdges?.includes(bi)))continue;
   const x=trace(a.a,a.panel,e),y=trace(b.a,b.panel,e);if(!x||!y||Math.min(x.high,y.high)-Math.max(x.low,y.low)<=1)continue;
   if(Math.abs(x.low-y.low)>tolerance||Math.abs(x.high-y.high)>tolerance)throw Error('ขอบ Panel ที่มุมยาวไม่ตรงกัน · ปรับ Grid / Origin ให้แนวแผ่นสองด้านตรงกันก่อน Join');
   const ca=curtainSettings(a.a),cb=curtainSettings(b.a);if(a.panel.type!=='solid'||b.panel.type!=='solid'||Math.abs(ca.panelThickness-cb.panelThickness)>.001)throw Error('แผ่นพับต้องเป็น Solid และมีความหนาเท่ากัน');
   result.push({i,j,ai,bi,p:e.p.map((n,k)=>n+x.direction[k]*x.low),q:e.p.map((n,k)=>n+x.direction[k]*x.high)});
  }
 }
 return result;
}
function components(count,edges){const seen=new Set(),groups=[];for(let i=0;i<count;i++){if(seen.has(i))continue;const group=[],queue=[i];seen.add(i);while(queue.length){const n=queue.shift();group.push(n);for(const e of edges){const k=e.i===n?e.j:e.j===n?e.i:null;if(k!==null&&!seen.has(k)){seen.add(k);queue.push(k)}}}groups.push(group)}return groups}

export function foldedAssemblies(areas,layoutFor=buildCurtainLayout){
 const groups=new Map();for(const a of areas){const entries=Object.entries(a.curtain?.panelJoins||{});if(!entries.length)continue;const panels=new Map((layoutFor(a)?.panels||[]).map(p=>[p.key,p]));for(const [key,join]of entries){const panel=panels.get(key);if(!panel)throw Error('Folded panel ไม่พบแผ่นเดิม · Unjoin panels ก่อนเปลี่ยนกริดหรือปิด Curtain');if(!groups.has(join.group))groups.set(join.group,[]);groups.get(join.group).push({a,panel})}}
 return [...groups].map(([group,members])=>{const bends=connections(members,true);if(members.length<2||components(members.length,bends).length!==1)throw Error('Folded panel มีขอบไม่ต่อเนื่อง · Unjoin panels ก่อนเปลี่ยนพื้นที่หรือกริด');return {group,members,bends}});
}

export function joinFoldedPanels(areas,refs){
 const selection=[...new Map(refs.map(r=>[panelRef(r.areaId,r.key),r])).values()];if(selection.length<2||selection.length>100)throw Error('เลือก 2–100 Panels ที่อยู่คนละด้านของมุม');
 const raw=new Map(),members=selection.map(r=>{const a=areas.find(a=>a.id===r.areaId);if(!a||a.visible===false||!a.curtain?.enabled)throw Error('เลือก Panel ที่แสดงอยู่ในฉาก');if(!convexBoundary(a.outer))throw Error('แบ่ง Area ขอบเขตเว้าให้เป็นด้านนูนก่อน Join แผ่นพับ');if(!raw.has(a.id)){const copy=structuredClone(a);copy.curtain={...curtainSettings(a),panelJoins:{},gapAtBoundary:false};raw.set(a.id,new Map(buildCurtainLayout(copy).panels.map(p=>[p.key,p])))}const panel=raw.get(a.id).get(r.key);if(!panel||panel.rings.length!==1)throw Error('เลือกแผ่นมุมที่ไม่มีช่องเปิดภายใน');return {a,panel}});
 // Existing folded pieces must be selected in full to avoid dangling members.
 const touched=new Set(members.map(m=>m.a.curtain?.panelJoins?.[m.panel.key]?.group).filter(Boolean)),ids=new Set(selection.map(r=>panelRef(r.areaId,r.key)));
 for(const a of areas)for(const [key,j]of Object.entries(a.curtain?.panelJoins||{}))if(touched.has(j.group)&&!ids.has(panelRef(a.id,key)))throw Error('เลือกสมาชิกแผ่นพับเดิมให้ครบ หรือ Unjoin panels ก่อน');
 const edges=connections(members),parts=components(members.length,edges);if(parts.some(p=>p.length<2))throw Error('Panel ที่เลือกต้องมีขอบมุมร่วมกันและแนวขอบตรงกัน · ไม่สามารถ Join แผ่นที่อยู่ห่างกัน');
 const assignments=new Map();for(const part of parts){const group=crypto.randomUUID();for(const i of part){const boundary=[...new Set(edges.flatMap(e=>e.i===i?[e.ai]:e.j===i?[e.bi]:[]))];assignments.set(panelRef(members[i].a.id,members[i].panel.key),{group,edges:boundary})}}
 const next=areas.map(a=>{const changes=[...assignments].filter(([ref])=>parsePanelRef(ref).areaId===a.id);if(!changes.length)return a;const c=curtainSettings(a);for(const [ref,j]of changes)c.panelJoins[parsePanelRef(ref).key]=j;return {...a,curtain:c}});foldedAssemblies(next);return next;
}
export function unjoinFoldedPanels(areas,refs){
 const groups=new Set(refs.map(r=>areas.find(a=>a.id===r.areaId)?.curtain?.panelJoins?.[r.key]?.group).filter(Boolean));return areas.map(a=>{const entries=Object.entries(a.curtain?.panelJoins||{});if(!entries.some(([,j])=>groups.has(j.group)))return a;const c=curtainSettings(a);c.panelJoins=Object.fromEntries(entries.filter(([,j])=>!groups.has(j.group)));return {...a,curtain:c}});
}
export function remapFoldGroups(incoming){const groups=new Map();return incoming.map(a=>{if(!Object.keys(a.curtain?.panelJoins||{}).length)return a;const next=structuredClone(a);for(const j of Object.values(next.curtain.panelJoins)){if(!groups.has(j.group))groups.set(j.group,crypto.randomUUID());j.group=groups.get(j.group)}return next})}
