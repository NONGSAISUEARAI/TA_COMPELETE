import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,worldPoint} from '../geometry.js';
import {buildCurtainLayout} from '../curtain.js';
import {joinFoldedPanels,unjoinFoldedPanels,foldedAssemblies,remapFoldGroups} from '../panel-folds.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
const source=()=>{const a=rectangle({width:2400,height:2400}),b=rectangle({x:2400,angle:90,width:1200,height:2400});for(const x of [a,b])x.curtain={enabled:true,reference:'world',gap:12};return [a,b]};
const refs=list=>[{areaId:list[0].id,key:'1200:0:0'},{areaId:list[1].id,key:'0:0:0'}];
test('Two corner faces become one persistent folded piece with a shared real bend and gaps retained elsewhere',()=>{
 const before=source(),saved=JSON.stringify(before),next=joinFoldedPanels(before,refs(before)),groups=foldedAssemblies(next);assert.equal(groups.length,1);assert.equal(groups[0].members.length,2);assert.equal(groups[0].bends.length,1);assert.equal(JSON.stringify(before),saved);
 const bend=groups[0].bends[0];assert.deepEqual(bend.p,[2400,0,6]);assert.deepEqual(bend.q,[2400,0,1194]);
 const front=buildCurtainLayout(next[0]).panels.find(p=>p.key==='1200:0:0');assert.equal(Math.max(...front.rings[0].map(p=>worldPoint(next[0],p)[0])),2400);assert.equal(Math.min(...front.rings[0].map(p=>p[1])),6);
 const unjoined=unjoinFoldedPanels(next,[refs(next)[0]]);assert.equal(foldedAssemblies(unjoined).length,0);assert.deepEqual(buildCurtainLayout(unjoined[0]).panels,buildCurtainLayout(before[0]).panels);
});
test('Several selected rows create separate folded pieces with no gap bridges between rows',()=>{
 const a=source(),selection=[...refs(a),{areaId:a[0].id,key:'1200:1200:0'},{areaId:a[1].id,key:'0:1200:0'}],joined=joinFoldedPanels(a,selection),groups=foldedAssemblies(joined);assert.equal(groups.length,2);assert.equal(groups.reduce((n,g)=>n+g.members.length,0),4);
});
test('Disconnected panels, mismatched edges, thickness or glass reject without altering any Area',()=>{
 for(const mutate of [a=>a[1].base[0]+=100,a=>a[1].curtain.spacingY=1000,a=>a[1].curtain.panelThickness=8,a=>a[1].curtain.panelType='glass']){const a=source();mutate(a);const saved=JSON.stringify(a);assert.throws(()=>joinFoldedPanels(a,refs(a)));assert.equal(JSON.stringify(a),saved)}
});
test('Folded pieces survive JSON/DXF/unit conversion and imported copies receive independent groups',()=>{
 const a=source(),joined=joinFoldedPanels(a,refs(a)),id=foldedAssemblies(joined)[0].group;assert.equal(foldedAssemblies(JSON.parse(JSON.stringify(joined)))[0].group,id);
 const parsed=parseDxf(buildFacadeDxf(joined)).areas;assert.equal(foldedAssemblies(parsed)[0].group,id);const scaled=parseDxf(buildFacadeDxf(joined),'10').areas;assert.equal(foldedAssemblies(scaled)[0].bends[0].p[0],24000);
 const copies=remapFoldGroups(joined);assert.notEqual(foldedAssemblies(copies)[0].group,id);assert.equal(new Set(copies.flatMap(a=>Object.values(a.curtain.panelJoins).map(j=>j.group))).size,1);
});
test('Grid edits that break a fold are detected instead of silently leaving a fake connected piece',()=>{
 const a=source(),joined=joinFoldedPanels(a,refs(a)),edited=structuredClone(joined);edited[1].curtain.worldOrigin=[0,0,250];assert.throws(()=>foldedAssemblies(edited));
});
