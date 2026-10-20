import {add,sub,mul,dot,length,worldPoint,signedArea} from './geometry.js';
import {boundaryCorners} from './dimensions.js';

// Distances terminate on real boundary segments, including concave/triangular
// outlines. Choose the two closest nonparallel sides, not an invented bbox.
export function patternOriginMeasurements(area,origin=area?.pattern.origin){
 if(!area||area.visible===false)return null;
 const corners=boundaryCorners(area.outer),candidates=corners.map((p,i)=>{
  const edge=sub(corners[(i+1)%corners.length],p),size=length(edge),direction=mul(edge,1/size),t=Math.max(0,Math.min(size,dot(sub(origin,p),direction))),foot=add(p,mul(direction,t));
  return {edge:i+1,start:worldPoint(area,foot),end:worldPoint(area,origin),value:length(sub(origin,foot)),direction};
 }).sort((a,b)=>a.value-b.value||a.edge-b.edge);
 const first=candidates[0],second=candidates.find(d=>Math.abs(dot(d.direction,first.direction))<1-1e-7);
 return {local:[...origin],world:worldPoint(area,origin),dimensions:[first,second].filter(Boolean)};
}

export function originAtEdgeDistance(area,origin,edgeNumber,value){
 if(!Number.isFinite(value)||value<0||value>1e9)throw Error('ระยะต้องเป็นตัวเลขตั้งแต่ 0 ถึง 1,000,000,000 mm');
 const corners=boundaryCorners(area.outer),p=corners[edgeNumber-1],q=corners[edgeNumber%corners.length];if(!p||!q)throw Error('ไม่พบขอบ Area');
 const edge=sub(q,p),size=length(edge),tangent=mul(edge,1/size),foot=add(p,mul(tangent,Math.max(0,Math.min(size,dot(sub(origin,p),tangent))))),delta=sub(origin,foot),distance=length(delta);
 const direction=distance>1e-7?mul(delta,1/distance):mul([-tangent[1],tangent[0]],Math.sign(signedArea(corners)));
 return add(foot,mul(direction,value));
}
