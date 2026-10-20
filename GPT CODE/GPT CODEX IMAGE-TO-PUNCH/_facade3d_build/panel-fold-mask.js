import {sub,dot,mul,add,length,signedArea} from './geometry.js';
export function convexBoundary(points){const sign=Math.sign(signedArea(points));return points.every((p,i)=>{const a=sub(points[(i+1)%points.length],p),b=sub(points[(i+2)%points.length],points[(i+1)%points.length]);return (a[0]*b[1]-a[1]*b[0])*sign>=-1e-6})}
// Offset every actual boundary side except the explicitly joined bend edges.
export function foldBoundaryMask(outer,distance,edges){
 if(!convexBoundary(outer))throw Error('Folded panel รองรับ Area ขอบเขตนูน · แบ่ง Area ที่เว้าก่อน Join');
 let result=outer.map(p=>[...p]);const sign=Math.sign(signedArea(outer));
 for(let i=0;i<outer.length;i++){if(edges.includes(i))continue;const p=outer[i],e=sub(outer[(i+1)%outer.length],p),normal=mul([-e[1],e[0]],sign/length(e)),margin=q=>dot(sub(q,p),normal)-distance,next=[];
  for(let j=0;j<result.length;j++){const a=result[j],b=result[(j+1)%result.length],da=margin(a),db=margin(b),insideA=da>=-1e-8,insideB=db>=-1e-8;if(insideA)next.push(a);if(insideA!==insideB)next.push(add(a,mul(sub(b,a),da/(da-db))))}result=next;
 }
 return result.length>=3?[[[...result,result[0]]]]:[];
}
