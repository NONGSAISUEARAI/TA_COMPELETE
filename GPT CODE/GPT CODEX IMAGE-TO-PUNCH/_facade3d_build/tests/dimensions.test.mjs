import test from 'node:test';
import assert from 'node:assert/strict';
import {selectionDimensions} from '../dimensions.js';
import {rectangle,areaFromWorld,worldPoint,localPoint,add,mul} from '../geometry.js';
import {buildCurtainLayout} from '../curtain.js';
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-6,`${a} != ${b}`);

test('Area dimensions measure true size on a rotated 3D surface and ignore openings',()=>{
 const area=rectangle({width:8000,height:4200,x:500,y:1000,z:300,angle:125});area.holes=[[[500,500],[1000,500],[1000,1000],[500,1000]]];
 const [w,h]=selectionDimensions(area);near(w.value,8000);near(h.value,4200);assert.equal(w.kind,'area');assert.equal(w.axis,'width');assert.equal(h.axis,'height');
 area.visible=false;assert.deepEqual(selectionDimensions(area),[]);assert.deepEqual(selectionDimensions(null),[]);
});
test('Panel dimensions measure finished clipped geometry including boundary and internal gaps',()=>{
 const area=rectangle({width:4000,height:3000});area.curtain={enabled:true,spacingX:1000,spacingY:1000,gap:12};
 const panel=buildCurtainLayout(area).panels[0],[w,h]=selectionDimensions(area,panel);
 near(w.value,988);near(h.value,988);assert.equal(w.kind,'panel');assert.equal(w.panelKey,panel.key);
 area.curtain.gapAtBoundary=false;const flush=buildCurtainLayout(area).panels[0];near(selectionDimensions(area,flush)[0].value,994);
});
test('Rotated curtain rectangles retain finished W/H; clipped triangles measure all actual edges',()=>{
 const area=rectangle({width:6000,height:5000,angle:90});area.curtain={enabled:true,angle:33,spacingX:1000,spacingY:1000,gap:12};
 const panels=buildCurtainLayout(area).panels;
 const interior=panels.find(p=>p.rings[0].length===4&&Math.abs(p.area-.976144)<1e-8);
 assert.ok(interior);const dims=selectionDimensions(area,interior);near(dims[0].value,988);near(dims[1].value,988);
 const triangle={key:'triangle',name:'P custom',rings:[[[0,0],[2000,0],[0,1000]]]};area.curtain.angle=0;
 const t=selectionDimensions(area,triangle);assert.equal(t.length,3);near(t[0].value,2000);near(t[1].value,Math.hypot(2000,1000));near(t[2].value,1000);assert.ok(t.every(d=>d.measurement==='boundary-edge'));
});


test('triangle dimensions terminate on real vertices and preserve true 3D lengths after UCS rotation or reversal',()=>{
 const a=areaFromWorld([[10000,2000,3000],[16000,2000,3000],[10000,2000,6000]],'Triangle');
 const check=area=>{const d=selectionDimensions(area);assert.equal(d.length,3);for(let i=0;i<3;i++){near(d[i].value,[6000,Math.hypot(6000,3000),3000][i]);for(const key of ['start','end'])assert.ok(a.outer.some(p=>worldPoint(a,p).every((n,k)=>Math.abs(n-d[i][key][k])<1e-6)))}return d};
 check(a);const b=structuredClone(a),r=37*Math.PI/180;b.base=worldPoint(a,[1234,-678]);b.u=add(mul(a.u,Math.cos(r)),mul(a.v,Math.sin(r)));b.v=mul(add(mul(a.u,-Math.sin(r)),mul(a.v,Math.cos(r))),-1);b.outer=a.outer.map(p=>localPoint(b,worldPoint(a,p)));check(b);
});

test('a rectangular boundary rotated within its stored UCS keeps its actual side lengths',()=>{
 const a=rectangle({width:6000,height:3000}),b=structuredClone(a),r=31*Math.PI/180;b.u=add(mul(a.u,Math.cos(r)),mul(a.v,Math.sin(r)));b.v=add(mul(a.u,-Math.sin(r)),mul(a.v,Math.cos(r)));b.outer=a.outer.map(p=>localPoint(b,worldPoint(a,p)));const [w,h]=selectionDimensions(b);near(w.value,6000);near(h.value,3000);
 a.outer=[[0,0],[2000,0],[6000,0],[6000,3000],[0,3000]];const dims=selectionDimensions(a);assert.equal(dims.length,2);near(dims[0].value,6000);near(dims[1].value,3000);
});

test('concave outlines and reversed winding measure the same real edges without a fictitious bounding rectangle',()=>{
 const a=rectangle();a.outer=[[0,0],[4000,0],[4000,1000],[2000,1000],[2000,3000],[0,3000]];let dims=selectionDimensions(a);assert.equal(dims.length,6);assert.deepEqual(dims.map(d=>d.value),[4000,1000,2000,2000,2000,3000]);a.outer.reverse();assert.deepEqual(selectionDimensions(a).map(d=>d.value).sort((a,b)=>a-b),dims.map(d=>d.value).sort((a,b)=>a-b));
});

import {panelEdgeLabels,boundaryCorners} from '../dimensions.js';
test('Panel E labels use all real edges in the same order as folds, including sloped and reversed outlines',()=>{const area=rectangle({width:1000,height:600,angle:35});for(const ring of [[[0,0],[300,0],[300,200],[0,200]],[[0,0],[100,0],[300,0],[350,100],[300,200],[0,200]],[[0,200],[300,200],[300,0],[0,0]]]){const panel={key:'0:0:0',rings:[ring]},labels=panelEdgeLabels(area,panel),corners=boundaryCorners(ring);assert.equal(labels.length,corners.length);for(let i=0;i<corners.length;i++){assert.equal(labels[i].label,'E'+(i+1));assert.equal(labels[i].edgeIndex,i);assert.deepEqual(labels[i].start,worldPoint(area,corners[i]));assert.deepEqual(labels[i].end,worldPoint(area,corners[(i+1)%corners.length]));assert.deepEqual(labels[i].mid,worldPoint(area,corners[i].map((n,j)=>(n+corners[(i+1)%corners.length][j])/2)))}}assert.deepEqual(panelEdgeLabels(area,null),[]);area.visible=false;assert.deepEqual(panelEdgeLabels(area,{rings:[area.outer]}),[])});
