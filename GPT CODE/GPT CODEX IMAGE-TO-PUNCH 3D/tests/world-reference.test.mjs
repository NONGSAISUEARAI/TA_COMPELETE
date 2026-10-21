import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,areaFromWorld,worldPoint,localPoint,add,mul,cross,validateArea} from '../geometry.js';
import {curtainSettings,validateCurtainSettings} from '../curtain-settings.js';
import {buildCurtainLayout,curtainFrame} from '../curtain.js';
import {worldCurtainBasis,curtainMullionOffset} from '../curtain-world.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
import {mergeDxfUpdate} from '../dxf-update.js';
import {resizeArea} from '../area-size.js';

const near=(p,q)=>p.forEach((n,i)=>assert.ok(Math.abs(n-q[i])<1e-6,`${p} != ${q}`));
const worldSettings=()=>({enabled:true,reference:'world',worldOrigin:[350,700,900],worldAngle:17,spacingX:1200,spacingY:1000,gap:12,customX:[450],customY:[550]});
const signature=a=>buildCurtainLayout(a).panels.map(p=>({key:p.key,rings:p.rings.map(r=>r.map(q=>worldPoint(a,q).map(n=>Number(n.toFixed(4))).join(',')).sort().join('|')).sort()}));
function reframe(a,angle=73,flipped=false){
 const out=structuredClone(a),r=angle*Math.PI/180;out.base=worldPoint(a,[1234,-678]);out.u=add(mul(a.u,Math.cos(r)),mul(a.v,Math.sin(r)));out.v=mul(add(mul(a.u,-Math.sin(r)),mul(a.v,Math.cos(r))),flipped?-1:1);
 out.outer=a.outer.map(p=>localPoint(out,worldPoint(a,p)));out.holes=a.holes.map(h=>h.map(p=>localPoint(out,worldPoint(a,p))));out.pattern={...a.pattern,origin:[987,654],angle:133};validateArea(out);return out;
}

test('world grid is invariant under translated/rotated/reversed local UCS on the same physical surface',()=>{
 for(const angle of [0,45,90,125]){
  const a=rectangle({width:8000,height:4200,angle,x:400,y:500,z:200});a.holes=[[[1800,1000],[2800,1000],[2800,2400],[1800,2400]]];a.curtain=worldSettings();
  const expected=signature(a);assert.deepEqual(signature(reframe(a)),expected);assert.deepEqual(signature(reframe(a,90,true)),expected);
 }
});

test('world frame is invertible on vertical, horizontal and sloped surfaces; horizontal fallback is World XY',()=>{
 const faces=[rectangle(),areaFromWorld([[0,0,100],[6000,0,100],[6000,4000,100],[0,4000,100]]),areaFromWorld([[0,0,0],[6000,0,0],[6000,2400,3200],[0,2400,3200]])];
 for(const a of faces){a.curtain=worldSettings();const f=curtainFrame(a);for(const p of [[0,0],[1500,2000],[-500,4000]])near(f.from(f.to(p)),p);assert.deepEqual(signature(reframe(a,31,true)),signature(a))}
 const basis=worldCurtainBasis(faces[1]);near(basis.x,[1,0,0]);near(basis.y,[0,1,0]);
});

test('corner facades share World Z levels and one raw world anchor despite different UCS',()=>{
 const front=rectangle({width:8000,height:4200}),side=reframe(rectangle({width:5000,height:4200,x:8000,angle:90}),61,true);
 for(const a of [front,side])a.curtain={...worldSettings(),worldAngle:0};
 const levels=a=>[...new Set(buildCurtainLayout(a).grid.map(s=>s.map(p=>worldPoint(a,p))).filter(([p,q])=>Math.abs(p[2]-q[2])<1e-6).map(([p])=>Number(p[2].toFixed(4))))].sort((a,b)=>a-b);
 assert.deepEqual(levels(front),levels(side));assert.ok(levels(front).includes(900));
});

test('world reference survives DXF/JSON round trip, unit conversion and Live DXF coordinate-frame changes',()=>{
 const a=rectangle({angle:125,x:500,y:700});a.curtain=worldSettings();
 const parsed=parseDxf(buildFacadeDxf([a])).areas[0];assert.deepEqual(parsed.curtain,a.curtain);assert.deepEqual(signature(parsed),signature(a));
 const scaled=parseDxf(buildFacadeDxf([a]),'10').areas[0];near(scaled.curtain.worldOrigin,a.curtain.worldOrigin.map(n=>n*10));
 const fresh=reframe(a,37,true);fresh.dxfSource={metadataId:a.id,layer:'AREA_001'};
 const updated=mergeDxfUpdate([a],[fresh],'world.dxf').areas[0];assert.deepEqual(updated.curtain,a.curtain);assert.deepEqual(signature(updated),signature(a));
 assert.deepEqual(JSON.parse(JSON.stringify(a)).curtain,a.curtain);
});

test('resizing changes boundary only; world anchor and physical mullion offset stay fixed across UCS reversal',()=>{
 const a=rectangle();a.curtain=worldSettings();const worldAnchor=[...a.curtain.worldOrigin];resizeArea(a,9000,5000);assert.deepEqual(a.curtain.worldOrigin,worldAnchor);
 const b=reframe(a,24,true),c=curtainSettings(a),d=curtainSettings(b);
 near(mul(cross(a.u,a.v),curtainMullionOffset(a,c)),mul(cross(b.u,b.v),curtainMullionOffset(b,d)));
 assert.throws(()=>validateCurtainSettings({...a.curtain,worldOrigin:[0,0]}),/World Origin/);assert.throws(()=>validateCurtainSettings({...a.curtain,reference:'other'}),/reference/);
});
