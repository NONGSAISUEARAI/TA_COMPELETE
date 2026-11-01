import * as THREE from 'three';

// A rectangle can share a unit box even after the curtain grid is rotated.
export function rectangleFrame(rings){
 if(rings.length!==1||rings[0].length!==4)return null;
 const p=rings[0],x=[p[1][0]-p[0][0],p[1][1]-p[0][1]],y=[p[2][0]-p[1][0],p[2][1]-p[1][1]];
 const width=Math.hypot(...x),height=Math.hypot(...y);
 if(width<1e-6||height<1e-6||Math.abs(x[0]*y[0]+x[1]*y[1])>width*height*1e-7)return null;
 const tolerance=Math.max(1e-5,Math.max(width,height)*1e-7);
 if(Math.hypot(p[3][0]-p[0][0]-y[0],p[3][1]-p[0][1]-y[1])>tolerance||Math.hypot(p[2][0]-p[3][0]-x[0],p[2][1]-p[3][1]-x[1])>tolerance)return null;
 return {x:(p[0][0]+p[2][0])/2,y:(p[0][1]+p[2][1])/2,width,height,angle:Math.atan2(x[1],x[0])};
}

export function addBoxBatch(items,{group,material,matrix,depth,offset=0,areaId,panelType,edges,edgeMaterial}){
 if(!items.length)return;
 const mesh=new THREE.InstancedMesh(new THREE.BoxGeometry(1,1,1),material,items.length);
 const transform=new THREE.Matrix4(),position=new THREE.Vector3(),rotation=new THREE.Quaternion(),scale=new THREE.Vector3(),axis=new THREE.Vector3(0,0,1);
 mesh.userData={areaId,panelType,panelKeys:items.map(item=>item.key)};
 const linePositions=edges?new Float32Array(items.length*72):null;let cursor=0;
 for(let i=0;i<items.length;i++){
  const {frame:f,rings}=items[i];position.set(f.x,f.y,offset);rotation.setFromAxisAngle(axis,f.angle);scale.set(f.width,f.height,depth);
  transform.compose(position,rotation,scale);mesh.setMatrixAt(i,transform);
  if(edges){const ring=rings[0];for(let k=0;k<4;k++){const p=ring[k],q=ring[(k+1)%4];for(const z of [offset-depth/2,offset+depth/2]){linePositions.set([p[0],p[1],z,q[0],q[1],z],cursor);cursor+=6}linePositions.set([p[0],p[1],offset-depth/2,p[0],p[1],offset+depth/2],cursor);cursor+=6}}
 }
 mesh.instanceMatrix.needsUpdate=true;mesh.applyMatrix4(matrix);group.add(mesh);
 if(edges){const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.BufferAttribute(linePositions,3));const lines=new THREE.LineSegments(geometry,edgeMaterial);lines.applyMatrix4(matrix);edges.add(lines)}
 return mesh;
}

export function hitPanelKey(hit){return hit.object.userData.panelKeys?.[hit.instanceId]??hit.object.userData.panelKey}
