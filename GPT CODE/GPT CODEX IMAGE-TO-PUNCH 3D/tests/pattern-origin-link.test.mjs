import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,demoAreas,worldPoint} from '../geometry.js';
import {curtainFrame} from '../curtain.js';
import {curtainSettings} from '../curtain-settings.js';
import {applyPatternOriginLinks} from '../pattern-origin-link.js';
import {joinCurtainAreas,propagateCurtainJoinChanges} from '../curtain-join.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
const edit=(list,id,mutate)=>{const next=structuredClone(list);mutate(next.find(a=>a.id===id));return propagateCurtainJoinChanges(list,applyPatternOriginLinks(list,next,id))};
test('World lock aligns once, follows numeric origin and Area movement, and unlock freezes the grid',()=>{
 let a=rectangle({x:100,y:200,z:300,angle:90});a.pattern.origin=[800,900];a.curtain={enabled:true,reference:'world',worldOrigin:[0,0,0],worldAngle:17,spacingX:1200,spacingY:2400};let list=[a];
 list=edit(list,a.id,a=>a.curtain.followPatternOrigin=true);assert.deepEqual(list[0].curtain.worldOrigin,worldPoint(a,a.pattern.origin));
 list=edit(list,a.id,a=>a.pattern.origin=[1500,700]);assert.deepEqual(list[0].curtain.worldOrigin,worldPoint(list[0],[1500,700]));assert.equal(list[0].curtain.worldAngle,17);assert.equal(list[0].curtain.spacingY,2400);
 list=edit(list,a.id,a=>a.base[0]+=500);assert.deepEqual(list[0].curtain.worldOrigin,worldPoint(list[0],[1500,700]));
 list=edit(list,a.id,a=>a.curtain.followPatternOrigin=false);const anchor=[...list[0].curtain.worldOrigin];list=edit(list,a.id,a=>a.pattern.origin=[3000,2000]);assert.deepEqual(list[0].curtain.worldOrigin,anchor);
});
test('Local lock preserves curtain angle and is persistent in JSON and DXF',()=>{
 const a=rectangle();a.pattern.angle=31;a.curtain={enabled:true,reference:'local',origin:[800,900],angle:17};let list=edit([a],a.id,a=>a.curtain.followPatternOrigin=true);list=edit(list,a.id,a=>{a.pattern.origin=[1000,1200];a.pattern.angle=70});assert.deepEqual(list[0].curtain.origin,[1000,1200]);assert.equal(list[0].curtain.angle,17);
 assert.equal(parseDxf(buildFacadeDxf(list)).areas[0].curtain.followPatternOrigin,true);assert.equal(JSON.parse(JSON.stringify(list))[0].curtain.followPatternOrigin,true);assert.equal(curtainSettings(a).followPatternOrigin,false);
});
test('A locked joined group follows any member with one shared physical anchor',()=>{
 const source=demoAreas();source[0].curtain={enabled:true,reference:'world'};let list=joinCurtainAreas(source,new Set(source.slice(0,2).map(a=>a.id)),source[0].id);
 list=edit(list,list[0].id,a=>a.curtain.followPatternOrigin=true);assert.ok(list.slice(0,2).every(a=>a.curtain.followPatternOrigin));
 list=edit(list,list[1].id,a=>a.pattern.origin=[900,800]);const anchor=worldPoint(list[1],[900,800]);for(const a of list.slice(0,2)){assert.deepEqual(a.curtain.worldOrigin,anchor);assert.equal(a.curtain.join.anchorId,list[1].id)}assert.equal(list[2].curtain,undefined);
 const f=curtainFrame(list[1]);assert.ok(Math.hypot(...f.to([900,800]))<1e-6);
 list=edit(list,list[0].id,a=>a.curtain.followPatternOrigin=false);assert.ok(list.slice(0,2).every(a=>!a.curtain.followPatternOrigin));
});

test('Locked Unfold groups keep shared seam phase when a child moves the Pattern Origin',()=>{
 const source=demoAreas();source[0].curtain={enabled:true,reference:'world',joinMode:'unfold',worldAngle:17};let list=joinCurtainAreas(source,new Set(source.slice(0,2).map(a=>a.id)),source[0].id);list=edit(list,list[0].id,a=>a.curtain.followPatternOrigin=true);list=edit(list,list[1].id,a=>a.pattern.origin=[900,800]);assert.ok(Math.hypot(...curtainFrame(list[1]).to([900,800]))<1e-6);const p=curtainFrame(list[0]).to([8000,1500]),q=curtainFrame(list[1]).to([0,1500]);assert.ok(Math.hypot(p[0]-q[0],p[1]-q[1])<1e-6);assert.equal(list[1].curtain.worldAngle,17);
});
