import {boundaryCorners} from './dimensions.js';
import {signedArea,sub,length,add,mul,dot,inside,intersects} from './geometry.js';
import {curtainSettings} from './curtain-settings.js';
import {buildCurtainLayout} from './curtain.js';
import './vendor/polygon-clipping.umd.js';
export const defaultPanelBend=()=>({type:'none',edge:0,depth:30,lip:15,side:1,radius:3,trimStart:0,trimEnd:0,trimCStart:0,trimCEnd:0,relief:0});
export const panelBendEdges=b=>b?.edgeSettings?Object.keys(b.edgeSettings).map(Number).filter(e=>b.edgeSettings[e].type!=='none').sort((a,b)=>a-b):b?.type==='none'||!b?[]:(b.edges??[b.edge??0]);
export function panelBendProfile(b,edge){
 const defaults=defaultPanelBend();if(b?.edgeSettings)return {...defaults,...b.edgeSettings[edge]};
 return panelBendEdges(b).includes(edge)?{...defaults,...b,radius:b.radius??0}:defaults;
}
function validateProfile(b){if(!b||!['none','L','C'].includes(b.type)||![1,-1].includes(b.side)||!Number.isFinite(b.depth)||b.depth<1||b.depth>1000||!Number.isFinite(b.lip)||b.lip<1||b.lip>1000||!Number.isFinite(b.radius??0)||(b.radius??0)<0||(b.radius??0)>1000||!Number.isFinite(b.relief??0)||(b.relief??0)<0||(b.relief??0)>1000||[b.trimStart??0,b.trimEnd??0,b.trimCStart??0,b.trimCEnd??0].some(n=>!Number.isFinite(n)||n<0||n>=90))throw Error('ค่าพับปีกไม่ถูกต้อง · มุมปาดต้องอยู่ระหว่าง 0 ถึงน้อยกว่า 90°')}
export function validatePanelBends(map){
 if(!map||typeof map!=='object'||Array.isArray(map)||Object.keys(map).length>100)throw Error('พับปีกได้สูงสุด 100 Panel ต่อ Area');
 for(const [key,b]of Object.entries(map)){if(key.length>120||!b)throw Error('ค่าการพับปีก Panel ไม่ถูกต้อง');
 if(b.edgeSettings!==undefined){if(!b.edgeSettings||typeof b.edgeSettings!=='object'||Array.isArray(b.edgeSettings)||Object.keys(b.edgeSettings).length>5000)throw Error('รายการขอบพับไม่ถูกต้อง');for(const [edge,c]of Object.entries(b.edgeSettings)){if(!/^\d+$/.test(edge)||Number(edge)>4999)throw Error('หมายเลขขอบพับไม่ถูกต้อง');validateProfile(c)}}
 else{validateProfile(b);const edges=panelBendEdges(b);if(!Array.isArray(edges)||edges.length>5000||new Set(edges).size!==edges.length||edges.some(e=>!Number.isInteger(e)||e<0||e>4999))throw Error('หมายเลขขอบพับไม่ถูกต้อง')}
 }
}
// A positive x moves inward. The outside skin of the flange stays on the original edge.
// Join metadata stores Area boundary indices, while flange controls use cleaned Panel edges.
export function joinedPanelBendEdges(area,panel){
 if(!panel.foldEdges?.length)return [];
 const points=boundaryCorners(panel.rings[0]),onEdge=(p,a,b)=>{const e=sub(b,a),len=length(e);if(len<1e-6)return false;const d=sub(p,a),t=dot(d,e)/(len*len);return Math.abs(e[0]*d[1]-e[1]*d[0])/len<.15&&t>=-1e-5&&t<=1+1e-5};
 return points.flatMap((p,i)=>panel.foldEdges.some(edge=>{const a=area.outer[edge],b=area.outer[(edge+1)%area.outer.length];return a&&b&&onEdge(p,a,b)&&onEdge(points[(i+1)%points.length],a,b)})?[i]:[]);
}
// R is the centreline radius; depth is measured normal to the main panel.
export function panelBendSections(panel,bend,thickness=0){
 const edges=panelBendEdges(bend).filter(edge=>!panel.joinedEdges?.includes(edge));if(!edges.length)return [];if(panel.type!=='solid')throw Error('การพับปีกใช้กับ Solid panel เท่านั้น');
 const points=boundaryCorners(panel.rings[0]),sign=Math.sign(signedArea(points)),half=thickness/2;
 // A concave corner requires a separate relief topology rather than silently bridging it.
 if(points.some((a,i)=>{const b=points[(i+1)%points.length],c=points[(i+2)%points.length];return ((b[0]-a[0])*(c[1]-b[1])-(b[1]-a[1])*(c[0]-b[0]))*sign<-.00001}))throw Error('แผ่นขอบเว้าต้องแบ่งเป็นแผ่นขอบนูนก่อนกำหนดปีกพับ');
 return edges.map(edge=>{
 const cfg=panelBendProfile(bend,edge);validateProfile(cfg);const radius=cfg.radius??0;
 if(radius>0&&radius<half)throw Error('รัศมีแนวกึ่งกลางต้องไม่น้อยกว่าครึ่งความหนาแผ่น');
 if(radius*(cfg.type==='C'?2:1)>cfg.depth)throw Error('รัศมีพับเกินระยะปีก · L ต้องมีระยะปีก ≥ R และ C ≥ 2R');
 const a=points[edge],b=points[(edge+1)%points.length];if(!a||!b)throw Error('ขอบพับเปลี่ยนไป กรุณาเลือกขอบ E ใหม่');
 const d=sub(b,a),len=length(d),along=mul(d,1/len),outward=[-d[1]/len*sign,d[0]/len*sign],samples=[];
 const push=(x,z,tx,tz)=>{const last=samples.at(-1);if(last&&Math.hypot(last.x-x,last.z-z*cfg.side)<1e-9)return;samples.push({x,z:z*cfg.side,tx,tz:tz*cfg.side})};
 if(radius===0){push(half,0,0,1);push(half,cfg.depth,0,1);if(cfg.type==='C')push(half+cfg.lip,cfg.depth,1,0)}
 else{for(let i=0;i<=16;i++){const t=i/16*Math.PI/2;push(half+radius*(1-Math.sin(t)),radius*(1-Math.cos(t)),-Math.cos(t),Math.sin(t))}
 if(cfg.type==='L')push(half,cfg.depth,0,1);else{push(half,cfg.depth-radius,0,1);for(let i=1;i<=16;i++){const t=i/16*Math.PI/2;push(half+radius*(1-Math.cos(t)),cfg.depth-radius+radius*Math.sin(t),Math.sin(t),Math.cos(t))}push(half+radius+cfg.lip,cfg.depth,1,0)}}
 const miters=[];for(const [end,neighbor]of [[0,(edge+points.length-1)%points.length],[1,(edge+1)%points.length]]){if(!edges.includes(neighbor))continue;const other=panelBendProfile(bend,neighbor);if(other.side!==cfg.side)continue;const origin=points[neighbor],dir=sub(points[(neighbor+1)%points.length],origin),normal=mul([-dir[1]*sign,dir[0]*sign],1/length(dir)),k=dot(along,normal);if(Math.abs(k)<1e-9)continue;const slope=Math.abs((1-dot(outward,normal))/k),same=['type','depth','side'].every(key=>other[key]===cfg[key])&&(other.radius??0)===radius&&(cfg.type!=='C'||other.lip===cfg.lip),manual=[end?cfg.trimEnd:cfg.trimStart,end?cfg.trimCEnd:cfg.trimCStart,end?other.trimStart:other.trimEnd,end?other.trimCStart:other.trimCEnd].some(n=>(n??0)>0);const gap=Math.max(cfg.relief??0,other.relief??0);miters.push({end,origin,normal,k,slope,gap,neighbor,same,clearance:gap/2*length(sub(normal,outward)),matched:same&&gap===0&&!manual})}

 const section={a,b,outward,along,len,samples,edge,cfg,points,half,rings:panel.rings,miters};
 // Validate the actual thick profile, not only its centreline.
 for(const q of panelBendSectionRing(section,thickness))panelBendEndRange(section,q);
 return section;
 });
}
export function panelBendSectionRing(section,thickness){const h=thickness/2,{samples}=section,raw=[...samples.map(s=>({x:s.x-s.tz*h,z:s.z+s.tx*h})),...samples.slice().reverse().map(s=>({x:s.x+s.tz*h,z:s.z-s.tx*h}))],ring=[];for(const q of raw)if(!ring.length||Math.hypot(q.x-ring.at(-1).x,q.z-ring.at(-1).z)>1e-8)ring.push(q);if(ring.length>1&&Math.hypot(ring[0].x-ring.at(-1).x,ring[0].z-ring.at(-1).z)<1e-8)ring.pop();return ring}
export function panelBendEndRange(s,q){
 // Convex panel half-planes clip the complete skin, even on sloped edges.
 let low=0,high=s.len;const sign=Math.sign(signedArea(s.points)),base=add(s.a,mul(s.outward,q.x));
 for(let i=0;i<s.points.length;i++){const a=s.points[i],b=s.points[(i+1)%s.points.length],d=sub(b,a),p=sub(base,a),c=(d[0]*p[1]-d[1]*p[0])*sign,k=(d[0]*s.along[1]-d[1]*s.along[0])*sign;if(Math.abs(k)<1e-10){if(c<-.000001)throw Error('ปีกพับเกินกรอบแผ่น · ลดรัศมีหรือกว้างปีก 2');continue}const t=-c/k;if(k>0)low=Math.max(low,t);else high=Math.min(high,t)}
 // Adjacent folded edges share the same bisector plane, including the curved skin.
 for(const m of s.miters??[]){const t=(q.x+m.clearance-dot(sub(base,m.origin),m.normal))/m.k;if(m.end===0)low=Math.max(low,t);else high=Math.min(high,t)}
 // L trims cut the rising web; C trims cut only the return lip, continuing from the web end.
 const rise=Math.max(0,q.z*s.cfg.side),returnWidth=s.cfg.type==='C'&&rise>=s.cfg.depth-(s.cfg.radius??0)-.000001?Math.max(0,q.x-(s.cfg.radius??0)-s.half):0;
 low+=rise*Math.tan((s.cfg.trimStart??0)*Math.PI/180)+returnWidth*Math.tan((s.cfg.trimCStart??0)*Math.PI/180);
 high-=rise*Math.tan((s.cfg.trimEnd??0)*Math.PI/180)+returnWidth*Math.tan((s.cfg.trimCEnd??0)*Math.PI/180);
 if(high-low<.001)throw Error('มุมปาดหรือขนาดปีกเกินความยาวขอบแผ่น');
 for(const t of [low,(low+high)/2,high]){const p=add(base,mul(s.along,t));if(s.rings.slice(1).some(h=>inside(p,h)))throw Error('ปีกพับผ่านช่องเปิด · ลดขนาดปีกหรือแบ่งแผ่นก่อน')}
 const p0=add(base,mul(s.along,low)),p1=add(base,mul(s.along,high));if(s.rings.slice(1).some(h=>h.some((p,i)=>intersects(p0,p1,p,h[(i+1)%h.length]))))throw Error('ปีกพับผ่านช่องเปิด · ลดขนาดปีกหรือแบ่งแผ่นก่อน');
 return [low,high];
}
export function panelBendPoint(section,q,end){const t=panelBendEndRange(section,q)[end];return [...add(add(section.a,mul(section.outward,q.x)),mul(section.along,t)),q.z]}
export function panelBendQuads(panel,bend,thickness=0){return panelBendSections(panel,bend,thickness).flatMap(s=>s.samples.slice(1).map((q,i)=>[panelBendPoint(s,s.samples[i],0),panelBendPoint(s,s.samples[i],1),panelBendPoint(s,q,1),panelBendPoint(s,q,0)]))}
export function panelBendFaceRings(panel,bend,thickness=0){
 const sections=panelBendSections(panel,bend,thickness);if(!sections.length)return panel.rings;const closed=r=>[...r,r[0]],span=Math.max(...panel.rings[0].map(p=>length(sub(p,panel.rings[0][0]))),1)*10;
 let mask=[panel.rings.map(closed)];for(const s of sections){const inset=s.samples[0].x,p=add(s.a,mul(s.outward,inset)),a=add(p,mul(s.along,-span)),b=add(p,mul(s.along,span));mask=globalThis.polygonClipping.intersection(mask,[[closed([a,b,add(b,mul(s.outward,span)),add(a,mul(s.outward,span))])]])}
 // Remove the small triangular corner from the main face too, leaving a real open relief.
 for(const s of sections)for(const m of s.miters??[]){if(m.end!==0||m.gap<=0||!m.same)continue;const neighbor=sections.find(other=>other.edge===m.neighbor);if(!neighbor)continue;const p=panelBendPoint(s,s.samples[0],0).slice(0,2),q=panelBendPoint(neighbor,neighbor.samples[0],1).slice(0,2),notch=[s.a,p,q];if(Math.abs(signedArea(notch))>.000001)mask=globalThis.polygonClipping.difference(mask,[[closed(notch)]])}
 if(mask.length!==1||!mask[0]?.length)throw Error('ปีกพับใช้พื้นที่หน้าแผ่นทั้งหมด · ลดรัศมี');return mask[0].map(r=>r.slice(0,-1));
}
export function applyPanelBends(areas,refs,patch){
 const byArea=new Map();for(const r of refs){if(!byArea.has(r.areaId))byArea.set(r.areaId,new Set());byArea.get(r.areaId).add(r.key)}if(!refs.length)throw Error('เลือก Panel ก่อน');
 return areas.map(a=>{const keys=byArea.get(a.id);if(!keys)return a;const c=curtainSettings(a),layout=buildCurtainLayout(a);c.panelBends={...c.panelBends};for(const key of keys){const p=layout?.panels.find(p=>p.key===key);if(!p)throw Error('ไม่พบ Panel ที่เลือก');const {toggleEdge,checked,edgeIndex,edgePatch,edgeEdits,...values}=patch,old=c.panelBends[key];let b={...defaultPanelBend(),...old,radius:old?(old.radius??0):defaultPanelBend().radius,...values};
 if(edgeIndex!==undefined||edgeEdits!==undefined){const requested=edgeEdits??[{edgeIndex,edgePatch}];if(!Array.isArray(requested)||!requested.length||requested.length>5000)throw Error('Invalid edge edits');const edits=requested.filter(e=>(!e.areaId||e.areaId===a.id)&&(!e.panelKey||e.panelKey===key));if(!edits.length)continue;if(!Array.isArray(edits)||!edits.length||edits.length>5000)throw Error('รายการช่องที่เลือกไม่ถูกต้อง');const edgeSettings=old?.edgeSettings?{...old.edgeSettings}:Object.fromEntries(panelBendEdges(old).map(e=>[e,panelBendProfile(old,e)]));for(const edit of edits){const index=edit.edgeIndex,change=edit.edgePatch;if(!Number.isInteger(index)||index<0||index>=boundaryCorners(p.rings[0]).length||!change||typeof change!=='object'||Array.isArray(change))throw Error('ไม่พบขอบหรือช่องที่เลือก');const prior=panelBendProfile({edgeSettings},index);edgeSettings[index]={...prior,...(prior.type==='none'&&change.type&&change.type!=='none'?{radius:Math.max(prior.radius,c.panelThickness/2)}:{}),...change}}b={...b,edgeSettings};}

 else if(b.edgeSettings){b.edgeSettings=Object.fromEntries(Object.entries(b.edgeSettings).map(([e,v])=>[e,{...v,...values}]));}
 if(Object.hasOwn(values,'edge')){b.edges=[values.edge];delete b.edgeSettings}
 if(toggleEdge!==undefined){const edges=new Set(panelBendEdges(b));if(checked)edges.add(toggleEdge);else edges.delete(toggleEdge);b.edges=[...edges].sort((a,b)=>a-b);if(b.edgeSettings){b.edgeSettings={...b.edgeSettings,[toggleEdge]:{...panelBendProfile(b,toggleEdge),type:checked?'L':'none'}}}if(checked&&b.type==='none')b.type='L'}
 if(b.type==='none'&&!b.edgeSettings)delete c.panelBends[key];else{validatePanelBends({[key]:b});panelBendFaceRings(p,b,c.panelThickness);c.panelBends[key]=b}
 }validatePanelBends(c.panelBends);return {...a,curtain:c}});
}
