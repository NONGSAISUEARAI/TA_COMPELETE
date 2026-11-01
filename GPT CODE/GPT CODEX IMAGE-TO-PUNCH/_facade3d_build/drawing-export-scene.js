import * as THREE from 'three';
import {triangleCut,drawingResult} from './drawing-export.js';
// Read the rendered solid geometry, including batched panels and mitered Mullions.
export function collectDrawing(groups,areas,view,options,folds=[]){
 const lines=[],push=line=>{if(lines.length>=1000000)throw Error('โมเดลมีเส้นมากเกินไป กรุณาเลือกส่งออกเฉพาะ Area ที่ต้องการ');lines.push(line)},edgeCache=new Map();let triangles=0;
 const wanted=new Set(areas.filter(a=>a.visible!==false).map(a=>a.id));
 try{for(const [group,kind]of groups){group.updateMatrixWorld(true);group.traverse(mesh=>{if(!mesh.isMesh||!wanted.has(mesh.userData.areaId)||mesh.material?.visible===false||mesh.userData.panelType==='open')return;const layer=mesh.userData.panelBend?'FOLD':kind==='PANEL'&&!mesh.userData.panelKey&&!mesh.userData.panelKeys?'AREA':kind;if(options[layer.toLowerCase()]===false)return;let edge=edgeCache.get(mesh.geometry);if(!edge){edge=new THREE.EdgesGeometry(mesh.geometry,30);edgeCache.set(mesh.geometry,edge)}const positions=mesh.geometry.attributes.position,index=mesh.geometry.index;
 for(let instance=0;instance<(mesh.isInstancedMesh?mesh.count:1);instance++){
  const matrix=mesh.matrixWorld.clone();if(mesh.isInstancedMesh){const im=new THREE.Matrix4();mesh.getMatrixAt(instance,im);matrix.multiply(im)}const point=(attribute,i)=>new THREE.Vector3().fromBufferAttribute(attribute,i).applyMatrix4(matrix).toArray(),ep=edge.attributes.position;
  for(let i=0;i<ep.count;i+=2)push({layer,a:point(ep,i),b:point(ep,i+1)});
  if(view.cut)for(let i=0;i<(index?.count||positions.count);i+=3){if(++triangles>3000000)throw Error('โมเดลใหญ่เกินไปสำหรับตัดแบบ กรุณาลดจำนวน Area ที่ส่งออก');const p=[0,1,2].map(k=>point(positions,index?index.getX(i+k):i+k)),cut=triangleCut(p,view);if(cut)push({layer:'CUT_'+layer,a:cut[0],b:cut[1],cut:true})}
 }
 })}
 if(options.fold!==false)for(const f of folds)push({layer:'FOLD',a:f.p,b:f.q});
 if(options.area)for(const a of areas)if(a.visible!==false)for(const ring of [a.outer,...a.holes])for(let i=0;i<ring.length;i++){const wp=p=>new THREE.Vector3(...a.base).addScaledVector(new THREE.Vector3(...a.u),p[0]).addScaledVector(new THREE.Vector3(...a.v),p[1]).toArray();push({layer:'AREA',a:wp(ring[i]),b:wp(ring[(i+1)%ring.length])})}
 return drawingResult(lines,view,options);
 }finally{for(const g of edgeCache.values())g.dispose()}
}
