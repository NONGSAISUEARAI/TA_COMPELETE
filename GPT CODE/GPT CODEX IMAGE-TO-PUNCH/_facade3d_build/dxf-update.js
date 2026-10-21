import {refreshCurtainJoins} from './curtain-join.js';
import {add,mul,dot,worldPoint,localPoint,validateArea} from './geometry.js';
import {curtainOrigin} from './curtain-settings.js';

const layer=a=>a.dxfSource?.layer||a.name;
const handle=a=>typeof a.dxfSource?.handle==='string'?a.dxfSource.handle.toUpperCase():null;
const identity=a=>a.dxfSource?.metadataId;
const angleOn=(before,after,angle)=>{
 const r=angle*Math.PI/180,direction=add(mul(before.u,Math.cos(r)),mul(before.v,Math.sin(r)));
 const x=dot(direction,after.u),y=dot(direction,after.v);
 return Math.hypot(x,y)<1e-8?angle:Math.atan2(y,x)*180/Math.PI;
};

export function mergeDxfUpdate(current,incoming,fileName){
 const eligible=current.filter(a=>!a.dxfSource?.file||a.dxfSource.file===fileName),used=new Set(),matches=new Map();
 // Stable identifiers take precedence over a layer name, which may be repeated.
 for(const next of incoming){
  let candidates=identity(next)?current.filter(a=>a.id===identity(next)):[];
  if(!candidates.length&&handle(next))candidates=eligible.filter(a=>handle(a)===handle(next));
  if(candidates.length>1)throw Error('DXF มีรหัสวัตถุซ้ำ จับคู่ Area ไม่ได้อย่างชัดเจน');
  if(candidates.length){const old=candidates[0];if(used.has(old.id))throw Error('DXF หลายขอบเขตอ้างถึง Area เดียวกัน');matches.set(next,old);used.add(old.id)}
 }
 for(const next of incoming.filter(a=>!matches.has(a))){
  const candidates=eligible.filter(a=>!used.has(a.id)&&layer(a)===layer(next));
  if(!candidates.length)continue;
  if(candidates.length!==1||incoming.filter(a=>!matches.has(a)&&layer(a)===layer(next)).length!==1)throw Error(`Layer ${layer(next)} มีหลาย Area: ต้องมีรหัสวัตถุเดิม หรือแยก Layer ก่อนอัปเดต`);
  matches.set(next,candidates[0]);used.add(candidates[0].id);
 }
 const replacements=new Map(),additions=[],ids=new Set(current.map(a=>a.id));let updated=0;
 for(const incomingArea of incoming){
  const next=structuredClone(incomingArea),old=matches.get(incomingArea);
  next.dxfSource={...next.dxfSource,file:fileName};
  if(old){
   next.id=old.id;next.name=old.name;next.visible=old.visible;
   next.pattern={...old.pattern,origin:localPoint(next,worldPoint(old,old.pattern.origin)),angle:angleOn(old,next,old.pattern.angle)};
   if(old.curtain){const f=curtainOrigin(old);next.curtain=structuredClone(old.curtain);if(next.curtain.reference!=='world'&&next.curtain.origin!==null&&next.curtain.origin!==undefined)next.curtain.origin=localPoint(next,worldPoint(old,f.origin));if(next.curtain.reference!=='world'&&next.curtain.angle!==null&&next.curtain.angle!==undefined)next.curtain.angle=angleOn(old,next,f.angle)}
   else delete next.curtain;
   validateArea(next);replacements.set(old.id,next);if(JSON.stringify(old)!==JSON.stringify(next))updated++;
  }else{
   if(ids.has(next.id))next.id=crypto.randomUUID();ids.add(next.id);validateArea(next);additions.push(next);
  }
 }
 const missing=current.filter(a=>a.dxfSource?.file===fileName&&!used.has(a.id)).length;
 const areas=refreshCurtainJoins([...current.map(a=>replacements.get(a.id)||a),...additions]);
 if(areas.length>200)throw Error('อัปเดตแล้วเกิน 200 Areas');
 return {areas,updated,added:additions.length,missing,changed:!!(updated||additions.length)};
}
