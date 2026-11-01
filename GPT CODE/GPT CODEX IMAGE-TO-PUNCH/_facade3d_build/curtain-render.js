import {memberJointPlanes} from './mullion-joints.js';
import {mitreMullionGeometry} from './mullion-joints-render.js';
import {panelBendFaceRings,panelBendEdges} from './panel-bends.js';
import {renderPanelBends} from './panel-bends-render.js';
import {curtainMullionOffset,worldCurtainBasis} from './curtain-world.js';
import {rectangleFrame,addBoxBatch} from './curtain-batch.js';
import * as THREE from 'three';
import {worldPoint} from './geometry.js';
function shape(rings){const s=new THREE.Shape(rings[0].map(p=>new THREE.Vector2(...p)));s.holes=rings.slice(1).map(h=>new THREE.Path(h.map(p=>new THREE.Vector2(...p))));return s}
function extrude(rings,depth,offset){const g=new THREE.ExtrudeGeometry(shape(rings),{depth,bevelEnabled:false,steps:1,curveSegments:1});g.translate(0,0,offset-depth/2);return g}
export function renderCurtain(a,layout,{surfaces,frames,outlines,matrix,selectedPanelKey,selectedPanelKeys,mullionJoints=[]}){
 const c=layout.settings,baseColor=new THREE.Color(c.panelColor),dense=layout.panels.length>1000,batches=new Map();
 const materials={};
 function panelMaterial(type,selected,folded=false){const key=type+selected+folded;if(materials[key])return materials[key];return materials[key]=new THREE.MeshStandardMaterial({color:selected?0xe9c687:type==='glass'?0x80bac4:folded?0xa6c4b1:baseColor,metalness:type==='solid'?.25:.05,roughness:type==='glass'?.13:.6,transparent:type!=='solid',opacity:type==='open'?.035:type==='glass'?.45:1,depthWrite:type==='solid',side:THREE.DoubleSide,visible:c.showPanels})}
 for(const p of layout.panels){
  const selected=selectedPanelKeys?.has(p.key)||p.key===selectedPanelKey,folded=!!p.foldGroup,rings=panelBendEdges(c.panelBends?.[p.key]).length?panelBendFaceRings(p,c.panelBends[p.key],c.panelThickness):p.rings,frame=dense?rectangleFrame(rings):null;
  if(frame){const key=p.type+selected+folded;if(!batches.has(key))batches.set(key,{type:p.type,selected,folded,items:[]});batches.get(key).items.push({...p,rings,frame});continue}
  const geometry=extrude(rings,c.panelThickness,0),mesh=new THREE.Mesh(geometry,panelMaterial(p.type,selected,folded));mesh.applyMatrix4(matrix);mesh.userData={areaId:a.id,panelKey:p.key,panelType:p.type};surfaces.add(mesh);
  if(c.showPanels){const edge=new THREE.LineSegments(new THREE.EdgesGeometry(geometry,30),new THREE.LineBasicMaterial({color:selected?0xffd398:p.type==='open'?0x4e6358:0x74877a,transparent:p.type==='open',opacity:p.type==='open'?.35:1}));edge.applyMatrix4(matrix);outlines.add(edge)}
 }
 for(const {type,selected,folded,items} of batches.values())addBoxBatch(items,{group:surfaces,material:panelMaterial(type,selected,folded),matrix,depth:c.panelThickness,areaId:a.id,panelType:type,edges:c.showPanels?outlines:null,edgeMaterial:c.showPanels?new THREE.LineBasicMaterial({color:selected?0xffd398:type==='open'?0x4e6358:0x74877a,transparent:type==='open',opacity:type==='open'?.35:1}):null});
 renderPanelBends(a,layout,{surfaces,outlines,matrix,selectedPanelKey,selectedPanelKeys});
 if(c.showMullions){const mat=new THREE.MeshStandardMaterial({color:c.mullionColor,metalness:.55,roughness:.4}),offset=curtainMullionOffset(a,c),members=[];for(const m of layout.mullions)for(const rings of m.rings){const joints=memberJointPlanes(a,rings,mullionJoints),frame=dense&&!joints.length?rectangleFrame(rings):null;if(frame){members.push({rings,frame});continue}const mesh=new THREE.Mesh(mitreMullionGeometry(extrude(rings,c.mullionDepth,offset),a,joints),mat);mesh.applyMatrix4(matrix);mesh.userData.areaId=a.id;frames.add(mesh)}addBoxBatch(members,{group:frames,material:mat,matrix,depth:c.mullionDepth,offset,areaId:a.id})}
 if(c.showGrid){const points=[],n=c.reference==='world'?new THREE.Vector3(...worldCurtainBasis(a).normal):new THREE.Vector3(0,0,1).transformDirection(matrix);for(const segment of layout.grid)for(const p of segment){const wp=worldPoint(a,p);points.push(new THREE.Vector3(...wp).addScaledVector(n,c.panelThickness/2+1))}if(points.length)frames.add(new THREE.LineSegments(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineBasicMaterial({color:0xc5ab6e,transparent:true,opacity:.65})))}
}

