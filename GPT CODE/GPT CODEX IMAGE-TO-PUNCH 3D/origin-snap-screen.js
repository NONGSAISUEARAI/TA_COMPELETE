import * as THREE from 'three';
import {worldPoint,localPoint,cross} from './geometry.js';

// Snap acquisition is a circle in screen pixels, including on foreshortened faces.
// Its inverse projection supplies a conservative local-space bucket query.
export function originSnapScreen(area,camera,rect,clientX,clientY,radius=14){
 camera.updateMatrixWorld();
 const mouse=[clientX-rect.left,clientY-rect.top],ray=new THREE.Raycaster(),plane=new THREE.Plane().setFromNormalAndCoplanarPoint(new THREE.Vector3(...cross(area.u,area.v)),new THREE.Vector3(...area.base)),corners=[];
 for(const dx of [-radius,radius])for(const dy of [-radius,radius]){
  ray.setFromCamera(new THREE.Vector2((mouse[0]+dx)/rect.width*2-1,1-(mouse[1]+dy)/rect.height*2),camera);
  const hit=ray.ray.intersectPlane(plane,new THREE.Vector3());if(!hit)return null;
  corners.push(localPoint(area,hit.toArray()));
 }
 const bounds=[0,1].map(axis=>[Math.min(...corners.map(p=>p[axis])),Math.max(...corners.map(p=>p[axis]))]);
 return {radius,bounds,distance(point){const v=new THREE.Vector3(...worldPoint(area,point)).project(camera);return v.z< -1||v.z>1?Infinity:Math.hypot((v.x+1)*rect.width/2-mouse[0],(1-v.y)*rect.height/2-mouse[1])}};
}
