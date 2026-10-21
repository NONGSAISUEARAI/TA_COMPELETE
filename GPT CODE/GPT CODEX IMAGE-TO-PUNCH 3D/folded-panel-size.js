import {joinCurtainAreas} from './curtain-join.js';
import {curtainFrame} from './curtain.js';
import {worldCurtainBasis} from './curtain-world.js';
import {sub,dot,length} from './geometry.js';

// Develop the physical faces into a plane before measuring the blank. Summing
// arbitrary local widths or using a 3D box gives the wrong size at corners.
export function foldedPanelSize(assembly){
 const root=assembly.members[0],basis=worldCurtainBasis(root.a),bend=assembly.bends[0],d=sub(bend.q,bend.p),angle=Math.atan2(-dot(d,basis.x),dot(d,basis.y))*180/Math.PI;
 const virtual=assembly.members.map(({a,panel})=>({...a,outer:panel.rings[0],holes:panel.rings.slice(1),curtain:{enabled:true,reference:'world',joinMode:'unfold',worldOrigin:[...bend.p],worldAngle:angle,spacingX:1200,spacingY:1200,gap:0}}));
 if(new Set(virtual.map(a=>a.id)).size!==virtual.length)throw Error('แผ่นพับหลายหน้าบน Area เดียวกันยังไม่รองรับการวัดขนาดคลี่');
 const unfolded=joinCurtainAreas(virtual,new Set(virtual.map(a=>a.id)),root.a.id),faces=unfolded.map((a,i)=>({areaId:a.id,key:assembly.members[i].panel.key,rings:[a.outer,...a.holes].map(r=>r.map(curtainFrame(a).to))}));
 const points=faces.flatMap(f=>f.rings[0]),xs=points.map(p=>p[0]),ys=points.map(p=>p[1]),bounds=[Math.min(...xs),Math.min(...ys),Math.max(...xs),Math.max(...ys)];
 return {group:assembly.group,width:bounds[2]-bounds[0],height:bounds[3]-bounds[1],bounds,faces,bends:assembly.bends.map(b=>({length:length(sub(b.q,b.p))})),allowanceIncluded:false};
}
