import test from 'node:test';
import assert from 'node:assert/strict';
import {areaSize,resizeArea} from '../area-size.js';
import {rectangle,validateArea,worldPoint} from '../geometry.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';

test('imported rotated Area resizes in its plane including openings and origins',()=>{
 const original=rectangle({width:4000,height:3000,x:500,y:200,z:100,angle:125});
 original.holes=[[[1000,1000],[2000,1000],[2000,2000],[1000,2000]]];
 original.pattern.origin=[500,500];original.curtain={origin:[1000,1500],spacingX:1200,spacingY:900};
 const a=parseDxf(buildFacadeDxf([original])).areas[0],base=[...a.base],u=[...a.u],v=[...a.v];
 const anchor=worldPoint(a,areaSize(a).min);resizeArea(a,8000,1500);validateArea(a);
 assert.equal(areaSize(a).width,8000);assert.equal(areaSize(a).height,1500);
 assert.deepEqual(worldPoint(a,areaSize(a).min),anchor);
 assert.deepEqual(a.base,base);assert.deepEqual(a.u,u);assert.deepEqual(a.v,v);
 const near=(p,q)=>p.forEach((n,i)=>assert.ok(Math.abs(n-q[i])<1e-6));
 near(a.holes[0][0],[2000,500]);near(a.pattern.origin,[1000,250]);near(a.curtain.origin,[2000,750]);assert.equal(a.curtain.spacingX,1200);
});

test('irregular Area keeps its shape proportions and minimum local corner',()=>{
 const a=rectangle();a.outer=[[-200,100],[3800,100],[-200,3100]];
 resizeArea(a,2000,6000);validateArea(a);
 assert.deepEqual(a.outer,[[-200,100],[1800,100],[-200,6100]]);
 for(const width of [0,NaN,Infinity,-10])assert.throws(()=>resizeArea(a,width,1000));
});
