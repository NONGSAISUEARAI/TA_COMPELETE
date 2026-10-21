import * as THREE from 'three';

// A view of the World directions, independent of selection, Area UCS and grid.
export function setupWorldUcs(view){
 const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');
 svg.id='world-ucs';svg.setAttribute('viewBox','0 0 136 128');svg.setAttribute('role','img');svg.setAttribute('aria-label','World UCS: X, Y, Z');
 const title=document.createElementNS(ns,'text');title.textContent='WORLD UCS';title.setAttribute('x','9');title.setAttribute('y','14');title.setAttribute('class','ucs-title');svg.append(title);
 const axes=[['X',[1,0,0],'#f0a17e'],['Y',[0,1,0],'#a9ddaa'],['Z',[0,0,1],'#99c8ec']].map(([name,direction,color])=>{
  const g=document.createElementNS(ns,'g'),line=document.createElementNS(ns,'line'),label=document.createElementNS(ns,'text');
  g.dataset.worldDirection=direction.join(',');g.dataset.axis=name;g.setAttribute('stroke',color);label.setAttribute('fill',color);label.textContent=name;g.append(line,label);svg.append(g);return {g,line,label,direction};
 });
 const origin=document.createElementNS(ns,'circle');origin.setAttribute('cx','64');origin.setAttribute('cy','72');origin.setAttribute('r','3');origin.setAttribute('fill','#e4eae6');svg.append(origin);view.append(svg);
 return {update(camera){
  for(const {g,line,label,direction} of axes){const v=new THREE.Vector3(...direction).transformDirection(camera.matrixWorldInverse),x=64+v.x*40,y=72-v.y*40;
   line.setAttribute('x1','64');line.setAttribute('y1','72');line.setAttribute('x2',x);line.setAttribute('y2',y);line.setAttribute('opacity',v.z<-.5?'.55':'1');
   label.setAttribute('x',64+v.x*51);label.setAttribute('y',76-v.y*51);g.dataset.screenDirection=[v.x,v.y,v.z].join(',');
  }
 }};
}
