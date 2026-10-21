import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {buildCurtainLayout,curtainFrame} from '../curtain.js';
import {createOriginSnap} from '../origin-snap.js';
import {originAtEdgeDistance,patternOriginMeasurements} from '../pattern-origin.js';

test('Origin snaps to finished panel corners, edge midpoints and centers, respecting suppression and mode bits',()=>{
 const a=rectangle({width:6000,height:3000});a.curtain={enabled:true,spacingX:1200,spacingY:1200,gap:12};const snap=createOriginSnap(a,buildCurtainLayout(a).panels);
 assert.deepEqual(snap([1205,1207],15,515),{point:[1206,1206],type:'Panel corner'});
 assert.deepEqual(snap([1802,1801],15,515),{point:[1800,1800],type:'Panel center'});
 assert.deepEqual(snap([1802,1207],15,515),{point:[1800,1206],type:'Panel midpoint'});
 assert.equal(snap([1802,1801],15,1).type,null);assert.equal(snap([1802,1801],15,515|16384).type,null);
});
test('Pattern grid snaps are frozen at the start of an Origin move',()=>{
 const a=rectangle();a.pattern={origin:[100,200],angle:0,spacing:500};const snap=createOriginSnap(a);assert.deepEqual(snap([604,701],15,515).point,[600,700]);assert.deepEqual(snap([851,949],15,515).point,[850,950]);
});
test('Typing an edge distance preserves the along-edge position and supports zero/inward movement',()=>{
 const a=rectangle();assert.deepEqual(originAtEdgeDistance(a,[1200,800],1,450),[1200,450]);assert.deepEqual(originAtEdgeDistance(a,[1200,800],4,300),[300,800]);assert.deepEqual(originAtEdgeDistance(a,[1200,0],1,200),[1200,200]);
 assert.throws(()=>originAtEdgeDistance(a,[0,0],1,-2));const p=originAtEdgeDistance(a,[1200,800],1,0);assert.ok(patternOriginMeasurements(a,p).dimensions.some(d=>d.edge===1&&d.value===0));
});

test('Joint center snaps to grid intersections inside panel gaps, including custom and rotated grids',()=>{
 const a=rectangle({width:6000,height:4000});a.curtain={enabled:true,reference:'world',worldOrigin:[0,0,0],spacingX:1200,spacingY:1200,gap:40};let snap=createOriginSnap(a,buildCurtainLayout(a).panels);assert.deepEqual(snap([1201,1199],15,515),{point:[1200,1200],type:'Joint center'});assert.equal(snap([1201,1199],15,1).type,null);
 a.curtain.customX=[700];a.curtain.customY=[900];snap=createOriginSnap(a,buildCurtainLayout(a).panels);assert.deepEqual(snap([702,901],15,515),{point:[700,900],type:'Joint center'});
 a.curtain.worldAngle=17;const point=curtainFrame(a).from([2400,1200]);snap=createOriginSnap(a);const rotated=snap([point[0]+1,point[1]-1],15,515);assert.equal(rotated.type,'Joint center');assert.ok(Math.hypot(...rotated.point.map((n,i)=>n-point[i]))<1e-6);a.curtain.worldAngle=0;
 a.holes=[[[600,800],[800,800],[800,1000],[600,1000]]];snap=createOriginSnap(a);assert.notEqual(snap([700,900],15,515).type,'Joint center');
});
