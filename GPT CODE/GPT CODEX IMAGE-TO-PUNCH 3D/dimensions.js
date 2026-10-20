import {worldPoint,length,sub,dot,signedArea,add,mul} from './geometry.js';
import {curtainFrame} from './curtain.js';
import {worldCurtainBasis} from './curtain-world.js';

export function boundaryCorners(ring){
 let points=ring.map(p=>[...p]);if(points.length>1&&length(sub(points[0],points.at(-1)))<1e-6)points.pop();
 return points.filter((p,i)=>{const a=sub(p,points[(i+points.length-1)%points.length]),b=sub(points[(i+1)%points.length],p),la=length(a),lb=length(b);return la>1e-6&&lb>1e-6&&(Math.abs(a[0]*b[1]-a[1]*b[0])>la*lb*1e-8||dot(a,b)<0)});
}

// Use real edges: a local bounding box invents corners on triangles and on
// rectangular geometry whose imported Local UCS does not follow its sides.
export function selectionDimensions(area,panel=null){
 if(!area||area.visible===false)return [];
 const points=boundaryCorners(panel?panel.rings[0]:area.outer);if(points.length<3)return [];
 const edges=points.map((p,i)=>sub(points[(i+1)%points.length],p));
 const rectangle=points.length===4&&edges.every((e,i)=>Math.abs(dot(e,edges[(i+1)%4]))<=length(e)*length(edges[(i+1)%4])*1e-7);
 const center=worldPoint(area,mul(points.reduce((sum,p)=>add(sum,p),[0,0]),1/points.length)),winding=Math.sign(signedArea(points));
 let indices=points.map((_,i)=>i);
 if(rectangle){
  const frame=panel?curtainFrame(area):null,axis=panel?sub(worldPoint(area,frame.from([1,0])),worldPoint(area,frame.from([0,0]))):worldCurtainBasis(area).x;
  const align=i=>Math.abs(dot(sub(worldPoint(area,points[(i+1)%4]),worldPoint(area,points[i])),axis))/length(edges[i]);
  const width=align(0)>=align(1)?0:1;indices=[width,(width+3)%4];
 }
 return indices.map((i,index)=>{
  const p=points[i],q=points[(i+1)%points.length],edge=edges[i],size=length(edge),mid=mul(add(p,q),.5);
  return {axis:rectangle?(index===0?'width':'height'):`edge-${i+1}`,label:rectangle?(index===0?'W':'H'):`E${i+1}`,edgeIndex:i,start:worldPoint(area,p),end:worldPoint(area,q),value:length(sub(worldPoint(area,q),worldPoint(area,p))),center,outside:worldPoint(area,add(mid,mul([edge[1],-edge[0]],winding/size))),measurement:'boundary-edge',kind:panel?'panel':'area',areaId:area.id,panelKey:panel?.key||'',name:panel?.name||area.name};
 });
}
