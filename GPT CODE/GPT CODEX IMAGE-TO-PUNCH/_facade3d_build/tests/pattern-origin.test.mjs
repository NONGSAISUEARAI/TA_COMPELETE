import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,areaFromWorld} from '../geometry.js';
import {patternOriginMeasurements} from '../pattern-origin.js';

test('Pattern Origin distances terminate on actual Area edges in world space',()=>{
 const a=rectangle({width:6000,height:3000,angle:125,x:400,y:700,z:900});a.pattern.origin=[1200,800];const m=patternOriginMeasurements(a);
 assert.deepEqual(m.dimensions.map(d=>[d.edge,d.value]),[[1,800],[4,1200]]);for(const d of m.dimensions)assert.ok(Math.abs(Math.hypot(...d.end.map((n,i)=>n-d.start[i]))-d.value)<1e-6);
});
test('Triangle and outside origins measure real segments, and parallel sides are not selected twice',()=>{
 const a=areaFromWorld([[0,0,0],[6000,0,0],[0,0,3000]]);a.pattern.origin=[1000,700];const m=patternOriginMeasurements(a);assert.deepEqual(m.dimensions.map(d=>[d.edge,d.value]),[[1,700],[3,1000]]);
 const b=rectangle();b.pattern.origin=[-300,-400];const outside=patternOriginMeasurements(b);assert.deepEqual(outside.dimensions.map(d=>d.value),[500,500]);b.visible=false;assert.equal(patternOriginMeasurements(b),null);
});
