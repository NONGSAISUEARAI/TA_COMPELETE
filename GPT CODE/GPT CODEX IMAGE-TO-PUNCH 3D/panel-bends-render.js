import * as THREE from 'three';
import {panelBendSections,panelBendSectionRing,panelBendPoint} from './panel-bends.js';
export function curvedFlangeGeometry(section,thickness,{openJoints=false}={}){
 const points=panelBendSectionRing(section,thickness),ring=points.map(q=>new THREE.Vector2(q.x,q.z)),n=ring.length;
 const vertices=[0,1].flatMap(end=>points.flatMap(q=>panelBendPoint(section,q,end))),indices=[];
 for(const [i,j,k]of THREE.ShapeUtils.triangulateShape(ring,[])){if(!openJoints||!section.miters?.some(m=>m.end===0&&m.matched))indices.push(k,j,i);if(!openJoints||!section.miters?.some(m=>m.end===1&&m.matched))indices.push(n+i,n+j,n+k)}
 for(let i=0;i<n;i++){const j=(i+1)%n;indices.push(i,j,n+j,i,n+j,n+i)}
 const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(vertices,3));g.setIndex(indices);g.computeVertexNormals();return g;
}
// Weld matching corner rings once so internal end caps and duplicate outlines disappear.
export function joinedFlangeGeometry(sections,thickness){
 const positions=[],indices=[],lookup=new Map();for(const section of sections){const part=curvedFlangeGeometry(section,thickness,{openJoints:true}),p=part.attributes.position.array,remap=[];for(let i=0;i<p.length;i+=3){const key=[p[i],p[i+1],p[i+2]].map(n=>Math.round(n*1e5)).join(':');let index=lookup.get(key);if(index===undefined){index=positions.length/3;lookup.set(key,index);positions.push(p[i],p[i+1],p[i+2])}remap.push(index)}for(let i=0;i<part.index.count;i+=3){const tri=[remap[part.index.array[i]],remap[part.index.array[i+1]],remap[part.index.array[i+2]]];if(new Set(tri).size===3)indices.push(...tri)}part.dispose()}
 const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));g.setIndex(indices);g.computeVertexNormals();return g;
}
export function renderPanelBends(a,layout,{surfaces,outlines,matrix,selectedPanelKey,selectedPanelKeys}){for(const p of layout.panels){const bend=layout.settings.panelBends?.[p.key];if(!bend)continue;const sections=panelBendSections(p,bend,layout.settings.panelThickness);if(!sections.length)continue;const selected=selectedPanelKeys?.has(p.key)||p.key===selectedPanelKey,material=new THREE.MeshStandardMaterial({color:selected?0xe9c687:layout.settings.panelColor,metalness:.25,roughness:.6,side:THREE.DoubleSide,visible:layout.settings.showPanels}),geometry=joinedFlangeGeometry(sections,layout.settings.panelThickness),mesh=new THREE.Mesh(geometry,material);mesh.applyMatrix4(matrix);mesh.userData={areaId:a.id,panelKey:p.key,panelBend:true};surfaces.add(mesh);if(layout.settings.showPanels){const edge=new THREE.LineSegments(new THREE.EdgesGeometry(geometry,30),new THREE.LineBasicMaterial({color:selected?0xffd398:0x91b39a}));edge.applyMatrix4(matrix);outlines.add(edge)}}}
