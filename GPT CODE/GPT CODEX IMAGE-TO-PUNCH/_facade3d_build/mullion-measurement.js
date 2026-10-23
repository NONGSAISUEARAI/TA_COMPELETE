import {add,sub,mul,dot,cross,length,worldPoint} from './geometry.js';
import {clipLine} from './curtain.js';
import {curtainMullionOffset,worldCurtainBasis} from './curtain-world.js';
// Measure an actual clipped member cross-section, never the Area's first vertex.
export function mullionMeasurement(area,layout,kind){
 if(!area||area.visible===false||!layout?.settings.showMullions||!['mullionWidth','mullionDepth','mullionOffset'].includes(kind))return null;
 const c=layout.settings,center=mul(area.outer.reduce((sum,p)=>add(sum,p),[0,0]),1/area.outer.length);let chosen=null,best=Infinity;
 for(const member of layout.mullions)for(const rings of member.rings){const ring=rings[0];let direction=null,longest=0;for(let i=0;i<ring.length;i++){const edge=sub(ring[(i+1)%ring.length],ring[i]),size=length(edge);if(size>longest){longest=size;direction=mul(edge,1/size)}}if(!direction)continue;
 const across=[-direction[1],direction[0]],ts=ring.map(p=>dot(p,direction)),xs=ring.map(p=>dot(p,across)),t=(Math.min(...ts)+Math.max(...ts))/2,from=add(mul(direction,t),mul(across,Math.min(...xs))),to=add(mul(direction,t),mul(across,Math.max(...xs)));
 for(const segment of clipLine(from,to,ring,rings.slice(1))){const width=length(sub(segment[1],segment[0]));if(width<.001)continue;const mid=mul(add(segment[0],segment[1]),.5),score=(Math.abs(width-c.mullionWidth)>.001?1e14:0)+(member.kind==='grid'?0:1e10)+dot(sub(mid,center),sub(mid,center));if(score<best){best=score;chosen={segment,mid,width,memberKind:member.kind}}}
 }
 if(!chosen)return null;const n=cross(area.u,area.v),offset=curtainMullionOffset(area,c),point=(p,z)=>add(worldPoint(area,p),mul(n,z)),p=chosen.segment,mid=chosen.mid;
 const section=[point(p[0],offset-c.mullionDepth/2),point(p[1],offset-c.mullionDepth/2),point(p[1],offset+c.mullionDepth/2),point(p[0],offset+c.mullionDepth/2)];
 let start,end,value,label;
 if(kind==='mullionWidth'){start=point(p[0],offset);end=point(p[1],offset);value=chosen.width;label=Math.abs(chosen.width-c.mullionWidth)>.001?'Width (clipped)':'Width'}
 else if(kind==='mullionDepth'){start=point(mid,offset-c.mullionDepth/2);end=point(mid,offset+c.mullionDepth/2);value=c.mullionDepth;label='Depth'}
 else{const referenceNormal=c.reference==='world'?worldCurtainBasis(area).normal:n,side=(c.flipMullionSide?1:-1)*Math.sign(dot(n,referenceNormal)),near=offset-side*c.mullionDepth/2;start=point(mid,0);end=point(mid,near);value=c.mullionOffset;label='Area → Mullion'}
 return {kind,label,value,start,end,section,areaId:area.id,areaName:area.name,memberKind:chosen.memberKind};
}
