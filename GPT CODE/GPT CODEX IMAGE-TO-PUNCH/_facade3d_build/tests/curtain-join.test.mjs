import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,demoAreas,worldPoint,localPoint,add,mul,validateArea} from '../geometry.js';
import {curtainFrame,buildCurtainLayout} from '../curtain.js';
import {joinCurtainAreas,propagateCurtainJoinChanges,refreshCurtainJoins,unjoinCurtainAreas,remapImportedCurtainJoins} from '../curtain-join.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
import {mergeDxfUpdate} from '../dxf-update.js';
const near=(p,q)=>p.forEach((n,i)=>assert.ok(Math.abs(n-q[i])<1e-5,`${p} != ${q}`));
const joined=(angle=0)=>{const a=demoAreas();a[0].curtain={enabled:true,reference:'world',worldOrigin:[0,0,0],worldAngle:angle,joinMode:'unfold',spacingX:1200,spacingY:1200};return joinCurtainAreas(a,new Set(a.map(a=>a.id)),a[0].id)};
function seamLevels(a,x,y){return [...new Set(buildCurtainLayout(a).grid.flatMap(s=>s.map(p=>worldPoint(a,p))).filter(p=>Math.abs(p[0]-x)<.001&&Math.abs(p[1]-y)<.001).map(p=>Number(p[2].toFixed(3))))].sort((a,b)=>a-b)}
function reframe(a){const out=structuredClone(a),r=37*Math.PI/180;out.base=worldPoint(a,[1234,-678]);out.u=add(mul(a.u,Math.cos(r)),mul(a.v,Math.sin(r)));out.v=mul(add(mul(a.u,-Math.sin(r)),mul(a.v,Math.cos(r))),-1);out.outer=a.outer.map(p=>localPoint(out,worldPoint(a,p)));out.holes=a.holes.map(h=>h.map(p=>localPoint(out,worldPoint(a,p))));return validateArea(out)}

test('folded distance carries the remainder across a corner instead of restarting at zero',()=>{
 const a=joined();for(const z of [0,500,2100,4200])near(curtainFrame(a[0]).to(localPoint(a[0],[8000,0,z])),curtainFrame(a[1]).to(localPoint(a[1],[8000,0,z])));
 const vertical=buildCurtainLayout(a[1]).grid.filter(([p,q])=>Math.abs(p[0]-q[0])<1e-6).map(([p])=>p[0]);assert.ok(vertical.some(n=>Math.abs(n-400)<1e-5));assert.ok(!vertical.some(n=>Math.abs(n-1200)<1e-5));
 for(const z of [0,1000,4200])near(curtainFrame(a[0]).to(localPoint(a[0],[0,0,z])),curtainFrame(a[2]).to(localPoint(a[2],[0,0,z])));
});
test('rotated joints intersect both sides of a corner at the same elevations',()=>{
 const a=joined(17);assert.deepEqual(seamLevels(a[0],8000,0),seamLevels(a[1],8000,0));assert.deepEqual(seamLevels(a[0],0,0),seamLevels(a[2],0,0));assert.ok(seamLevels(a[0],8000,0).length>2);
});
test('changing one joined member shares phase, angle and spacing across the group',()=>{
 const before=joined(17),next=structuredClone(before);next[1].curtain.worldOrigin=[350,700,900];next[1].curtain.spacingX=1500;next[1].curtain.worldAngle=23;
 const updated=propagateCurtainJoinChanges(before,next);for(const a of updated){assert.deepEqual(a.curtain.worldOrigin,[350,700,900]);assert.equal(a.curtain.spacingX,1500);assert.equal(a.curtain.worldAngle,23)}assert.deepEqual(seamLevels(updated[0],8000,0),seamLevels(updated[1],8000,0));
});
test('picking a shared Origin on a child face uses that physical point as grid zero',()=>{
 const before=joined(17),next=structuredClone(before),point=[8000,2000,1500];next[1].curtain.worldOrigin=point;next[1].curtain.join.anchorId=next[1].id;
 const updated=propagateCurtainJoinChanges(before,next);near(curtainFrame(updated[1]).to(localPoint(updated[1],point)),[0,0]);
 for(const a of updated){assert.deepEqual(a.curtain.worldOrigin,point);assert.equal(a.curtain.join.anchorId,updated[1].id)}assert.deepEqual(seamLevels(updated[0],8000,0),seamLevels(updated[1],8000,0));
 const parsed=parseDxf(buildFacadeDxf(updated)).areas;near(curtainFrame(parsed[1]).to(localPoint(parsed[1],point)),[0,0]);
 const scaled=parseDxf(buildFacadeDxf(updated),'10').areas;near(curtainFrame(scaled[1]).to(localPoint(scaled[1],point.map(n=>n*10))),[0,0]);
});
test('UCS reversal and DXF/JSON round trips preserve joined seams and live updates recompute the group',()=>{
 const original=joined(17),reframed=refreshCurtainJoins(original.map(reframe));for(let i=0;i<3;i++)for(const p of [[0,0],[1500,2500]]){const w=worldPoint(original[i],p);near(curtainFrame(original[i]).to(p),curtainFrame(reframed[i]).to(localPoint(reframed[i],w)))}
 const parsed=parseDxf(buildFacadeDxf(original)).areas;assert.deepEqual(seamLevels(parsed[0],8000,0),seamLevels(parsed[1],8000,0));assert.deepEqual(JSON.parse(JSON.stringify(original)).map(a=>a.curtain.join),original.map(a=>a.curtain.join));
 const updated=mergeDxfUpdate(original,parsed,'joined.dxf').areas;assert.deepEqual(seamLevels(updated[0],8000,0),seamLevels(updated[1],8000,0));
 const scaled=parseDxf(buildFacadeDxf(original),'10').areas;assert.ok(Math.abs(scaled[1].curtain.join.offset[0]-original[1].curtain.join.offset[0]*10)<1e-5);
});
test('invalid topology rejects atomically; closed loops require periodic spacing',()=>{
 const a=rectangle(),b=rectangle({x:100000}),before=JSON.stringify([a,b]);assert.throws(()=>joinCurtainAreas([a,b],new Set([a.id,b.id]),a.id),/ขอบนอกชนกัน/);assert.equal(JSON.stringify([a,b]),before);
 const loop=[rectangle({width:8000,height:4200}),rectangle({width:5000,height:4200,x:8000,angle:90}),rectangle({width:8000,height:4200,x:8000,y:5000,angle:180}),rectangle({width:5000,height:4200,y:5000,angle:270})];
 loop[0].curtain={enabled:true,joinMode:'unfold'};assert.throws(()=>joinCurtainAreas(loop,new Set(loop.map(a=>a.id)),loop[0].id),/วงปิด/);loop[0].curtain={enabled:true,joinMode:'unfold',spacingX:1000};const closed=joinCurtainAreas(loop,new Set(loop.map(a=>a.id)),loop[0].id);assert.equal(closed.length,4);
});
test('unlink and repeated imports do not leave shared identifiers between independent copies',()=>{
 const a=joined(),copies=remapImportedCurtainJoins(a,a);for(const item of copies){assert.ok(!a.some(old=>old.id===item.id));assert.notEqual(item.curtain.join.group,a[0].curtain.join.group);assert.equal(item.curtain.join.rootId,copies[0].id)}
 const unjoined=unjoinCurtainAreas(a,new Set([a[1].id]));assert.ok(unjoined.every(a=>!a.curtain.join));assert.ok(a.every(a=>a.curtain.join));
 const changed=structuredClone(a);delete changed[1].curtain.join;changed[1].curtain.reference='local';assert.ok(propagateCurtainJoinChanges(a,changed).every(a=>!a.curtain.join));
});
test('extending a joined group retains its existing phase even when an existing child is primary',()=>{
 const source=demoAreas();source[0].curtain={joinMode:'unfold'};const first=joinCurtainAreas(source,new Set([source[0].id,source[1].id]),source[0].id),extended=joinCurtainAreas(first,new Set(first.map(a=>a.id)),first[1].id);
 for(let i=0;i<2;i++)for(const p of [[0,0],[1500,2500]])near(curtainFrame(first[i]).to(p),curtainFrame(extended[i]).to(p));
});
test('Live DXF geometry updates recalculate the corner position for every joined member',()=>{
 const before=joined(17),edited=structuredClone(before);edited[0].outer[1][0]=9000;edited[0].outer[2][0]=9000;edited[1].base[0]=9000;
 const incoming=parseDxf(buildFacadeDxf(edited)).areas,updated=mergeDxfUpdate(before,incoming,'moved-corner.dxf').areas;
 assert.ok(Math.abs(updated[1].curtain.join.offset[0]-9000)<1e-5);assert.deepEqual(seamLevels(updated[0],9000,0),seamLevels(updated[1],9000,0));assert.equal(before[1].curtain.join.offset[0],8000);
});


test('World joined frames ignore root selection, unfolding transforms and local UCS',()=>{
 const source=demoAreas();for(const a of source)a.curtain={enabled:true,reference:'world',worldOrigin:[350,700,900],worldAngle:17};
 const ids=new Set(source.map(a=>a.id)),frontRoot=joinCurtainAreas(source,ids,source[0].id),sideRoot=joinCurtainAreas(source,ids,source[1].id);
 for(let i=0;i<source.length;i++)for(const p of [[0,0],[1500,2500]]){
  near(curtainFrame(frontRoot[i]).to(p),curtainFrame(source[i]).to(p));
  near(curtainFrame(sideRoot[i]).to(p),curtainFrame(source[i]).to(p));
 }
 const changed=structuredClone(frontRoot);changed[2].curtain.joinMode='unfold';const unfolded=propagateCurtainJoinChanges(frontRoot,changed);assert.ok(unfolded.every(a=>a.curtain.joinMode==='unfold'));
 const back=structuredClone(unfolded);back[1].curtain.joinMode='world';const world=propagateCurtainJoinChanges(unfolded,back);
 for(let i=0;i<world.length;i++){const fresh=reframe(world[i]),f=curtainFrame(fresh);for(const p of [[0,0],[1500,2500]])near(f.to(localPoint(fresh,worldPoint(source[i],p))),curtainFrame(source[i]).to(p))}
 const parsed=parseDxf(buildFacadeDxf(world)).areas;for(const a of parsed)assert.equal(a.curtain.joinMode,'world');
});

test('World joining a closed facade does not require its perimeter to be divisible by spacing',()=>{
 const loop=[rectangle({width:8000,height:4200}),rectangle({width:5000,height:4200,x:8000,angle:90}),rectangle({width:8000,height:4200,x:8000,y:5000,angle:180}),rectangle({width:5000,height:4200,y:5000,angle:270})];
 const world=joinCurtainAreas(loop,new Set(loop.map(a=>a.id)),loop[0].id);assert.equal(world.length,4);assert.ok(world.every(a=>a.curtain.joinMode==='world'));for(const a of world)assert.ok(buildCurtainLayout(a).panels.length>0);
});
