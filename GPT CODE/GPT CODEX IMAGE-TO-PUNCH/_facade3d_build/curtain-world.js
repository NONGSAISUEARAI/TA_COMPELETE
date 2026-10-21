import {add,sub,mul,dot,cross,length,unit,localPoint} from './geometry.js';

// Resolve the same physical basis regardless of vertex order or local UCS.
export function worldCurtainBasis(area,angle=0){
 let normal=unit(cross(area.u,area.v));
 const dominant=normal.reduce((best,n,i)=>Math.abs(n)>Math.abs(normal[best])+1e-8?i:best,0),preferred=dominant===1?-1:1;
 if(normal[dominant]*preferred<0)normal=mul(normal,-1);
 let y=sub([0,0,1],mul(normal,normal[2]));
 if(length(y)<1e-6)y=sub([0,1,0],mul(normal,normal[1]));
 y=unit(y);const x=unit(cross(y,normal)),r=(angle%360)*Math.PI/180,c=Math.cos(r),s=Math.sin(r);
 return {x:add(mul(x,c),mul(y,s)),y:add(mul(x,-s),mul(y,c)),normal};
}

export function worldCurtainFrame(area,settings){
 // A joined group shares settings; unfolding is an explicit alternative to World.
 // Never let stored per-face Join rotations override the World reference.
 if(settings.join&&settings.joinMode==='unfold'){
  const j=settings.join,anchor=settings.worldOrigin??[0,0,0],r=((settings.worldAngle??0)%360)*Math.PI/180,c=Math.cos(r),s=Math.sin(r);
  const anchorOffset=j.anchorOffset??[0,0],x=add(mul(j.x,c),mul(j.y,s)),y=add(mul(j.x,-s),mul(j.y,c)),dx=dot(area.base,j.x)+j.offset[0]-dot(anchor,j.anchorX)-anchorOffset[0],dy=dot(area.base,j.y)+j.offset[1]-dot(anchor,j.anchorY)-anchorOffset[1];
  const o=[c*dx+s*dy,-s*dx+c*dy],lx=[dot(x,area.u),dot(x,area.v)],ly=[dot(y,area.u),dot(y,area.v)];
  return {x,y,normal:worldCurtainBasis(area).normal,to:p=>[o[0]+p[0]*lx[0]+p[1]*lx[1],o[1]+p[0]*ly[0]+p[1]*ly[1]],from:p=>{const u=p[0]-o[0],v=p[1]-o[1];return [lx[0]*u+ly[0]*v,lx[1]*u+ly[1]*v]}};
 }
 const basis=worldCurtainBasis(area,settings.worldAngle??0),origin=settings.worldOrigin??[0,0,0];
 const o=localPoint(area,origin),x=[dot(basis.x,area.u),dot(basis.x,area.v)],y=[dot(basis.y,area.u),dot(basis.y,area.v)];
 return {
  ...basis,
  to:p=>{const dx=p[0]-o[0],dy=p[1]-o[1];return [dx*x[0]+dy*x[1],dx*y[0]+dy*y[1]]},
  from:p=>[o[0]+x[0]*p[0]+y[0]*p[1],o[1]+x[1]*p[0]+y[1]*p[1]]
 };
}

export function curtainMullionOffset(area,settings){
 const sign=settings.reference==='world'&&dot(cross(area.u,area.v),worldCurtainBasis(area).normal)<0?-1:1;
 return settings.mullionOffset*(settings.flipMullionSide?-1:1)*sign;
}
