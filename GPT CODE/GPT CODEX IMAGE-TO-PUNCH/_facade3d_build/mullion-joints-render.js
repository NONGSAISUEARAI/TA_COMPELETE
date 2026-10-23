import * as THREE from 'three';
import {dot,sub} from './geometry.js';
// Clip a closed triangle mesh and cap the planar cut. Geometry stays in Area coordinates.
export function mitreMullionGeometry(geometry,a,joints){
 let g=geometry;
 for(const j of joints){
  const n=new THREE.Vector3(dot(j.normal,a.u),dot(j.normal,a.v),dot(j.normal,new THREE.Vector3().crossVectors(new THREE.Vector3(...a.u),new THREE.Vector3(...a.v)).toArray())),constant=j.constant-dot(j.normal,a.base),d=new THREE.Vector2(dot(j.inward,a.u),dot(j.inward,a.v)),origin=new THREE.Vector2(dot(sub(j.p,a.base),a.u),dot(sub(j.p,a.base),a.v)),pos=g.attributes.position;
  // Extend only the member's boundary end; the mitre then trims to the common plane.
  for(let i=0;i<pos.count;i++){let x=pos.getX(i),y=pos.getY(i),z=pos.getZ(i);if(Math.abs((x-origin.x)*d.x+(y-origin.y)*d.y)<.11){const shift=(constant-n.dot(new THREE.Vector3(x,y,z)))/(n.x*d.x+n.y*d.y);if(shift<0){x+=d.x*(shift-1);y+=d.y*(shift-1);pos.setXYZ(i,x,y,z)}}}
  const triangles=[],cut=[],eps=1e-5;
  for(let i=0;i<pos.count;i+=3){let poly=[0,1,2].map(k=>new THREE.Vector3().fromBufferAttribute(pos,i+k)),out=[];for(let k=0;k<poly.length;k++){const p=poly[k],q=poly[(k+1)%poly.length],dp=n.dot(p)-constant,dq=n.dot(q)-constant;if(dp>=-eps)out.push(p);if((dp>eps&&dq< -eps)||(dp< -eps&&dq>eps)){const v=p.clone().lerp(q,dp/(dp-dq));out.push(v);cut.push(v)}}for(let k=1;k+1<out.length;k++)triangles.push(out[0],out[k],out[k+1]);for(const p of out)if(Math.abs(n.dot(p)-constant)<eps)cut.push(p)}
  const unique=[];for(const p of cut)if(!unique.some(q=>q.distanceToSquared(p)<1e-8))unique.push(p);
  if(unique.length>=3&&Array.from({length:pos.count},(_,i)=>n.dot(new THREE.Vector3().fromBufferAttribute(pos,i))-constant).some(d=>d< -eps)){const centre=unique.reduce((s,p)=>s.add(p),new THREE.Vector3()).multiplyScalar(1/unique.length),u=unique[0].clone().sub(centre).normalize(),v=new THREE.Vector3().crossVectors(n,u);unique.sort((p,q)=>Math.atan2(p.clone().sub(centre).dot(v),p.clone().sub(centre).dot(u))-Math.atan2(q.clone().sub(centre).dot(v),q.clone().sub(centre).dot(u)));for(let k=0;k<unique.length;k++)triangles.push(centre,unique[(k+1)%unique.length],unique[k])}
  const next=new THREE.BufferGeometry().setAttribute('position',new THREE.Float32BufferAttribute(triangles.flatMap(p=>p.toArray()),3));next.computeVertexNormals();g.dispose();g=next;
 }
 return g;
}
