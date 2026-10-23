import {sharedEdges} from './curtain-join.js';
import {curtainSettings} from './curtain-settings.js';
import {curtainMullionOffset} from './curtain-world.js';
import {add,sub,mul,dot,cross,unit,signedArea,worldPoint} from './geometry.js';
// Each joined seam has one common mitre plane. Both faces retain opposite sides.
export function mullionJointPlanes(areas){
 const result=new Map(),groups=new Map();
 for(const a of areas){const c=curtainSettings(a);if(a.visible===false||!c.enabled||!c.showMullions||!c.join)continue;const key=c.join.group;if(!groups.has(key))groups.set(key,[]);groups.get(key).push(a)}
 for(const list of groups.values())for(const e of sharedEdges(list).edges){
  const a=list[e.i],b=list[e.j],na=cross(a.u,a.v),nb=cross(b.u,b.v),cos=dot(na,nb),den=1-cos*cos;if(den<1e-6)continue;
  const inward=(area,k)=>{const p=area.outer[k],q=area.outer[(k+1)%area.outer.length],s=Math.sign(signedArea(area.outer));return unit(add(mul(area.u,-(q[1]-p[1])*s),mul(area.v,(q[0]-p[0])*s)))};
  const da=inward(a,e.ai),db=inward(b,e.bi),normal=unit(sub(da,db));
  const oa=curtainMullionOffset(a,curtainSettings(a)),ob=curtainMullionOffset(b,curtainSettings(b));
  const centre=add(e.p,add(mul(na,(oa-cos*ob)/den),mul(nb,(ob-cos*oa)/den))),constant=dot(normal,centre);
  for(const [area,dir,sign] of [[a,da,1],[b,db,-1]]){if(!result.has(area.id))result.set(area.id,[]);result.get(area.id).push({p:e.p,q:e.q,inward:dir,normal:mul(normal,sign),constant:constant*sign})}
 }
 return result;
}
export function memberJointPlanes(a,rings,planes=[]){
 const points=rings[0].map(p=>worldPoint(a,p)),c=curtainSettings(a),z=curtainMullionOffset(a,c),normal=cross(a.u,a.v);
 return planes.filter(j=>{const edge=unit(sub(j.q,j.p)),len=Math.hypot(...sub(j.q,j.p)),ts=points.map(p=>dot(sub(p,j.p),edge));return Math.min(...ts)>=-.11&&Math.max(...ts)<=len+.11&&(points.filter(p=>Math.abs(dot(sub(p,j.p),j.inward))<.11).length>=2||points.some(p=>Math.min(...[-1,1].map(side=>dot(j.normal,add(p,mul(normal,z+side*c.mullionDepth/2)))-j.constant))<-.001))});
}

