import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,worldPoint,length,sub,netArea} from '../geometry.js';
import {buildCurtainLayout} from '../curtain.js';
import {selectionDimensions} from '../dimensions.js';
import {resizePanelEdge} from '../panel-resize.js';
import {resetPanelDimensions} from '../panel-size-reset.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
const fixture=(angle=0)=>{const a=rectangle({width:3600,height:2400,angle});a.outer=[[0,2400],[500,0],[3600,600],[3000,1800]];a.pattern.origin=[500,0];a.curtain={enabled:true,reference:'world',spacingX:1800,spacingY:3000,gapAtBoundary:false};return a};
const selected=(out)=>buildCurtainLayout(out.areas[0]).panels.find(p=>p.key===out.key);
test('Sloped E2 changes its true length while the Origin endpoint and installation boundary remain fixed',()=>{
 for(const angle of [0,35,110]){const a=fixture(angle),before=JSON.stringify(a),origin=worldPoint(a,a.pattern.origin),out=resizePanelEdge([a],a.id,'0:0:0',1,1000),panel=selected(out),edge=selectionDimensions(out.areas[0],panel).find(d=>d.edgeIndex===1);
  assert.ok(Math.abs(edge.value-1000)<.001);assert.ok(Math.min(length(sub(edge.start,origin)),length(sub(edge.end,origin)))<.001);assert.deepEqual(out.areas[0].pattern,a.pattern);assert.deepEqual(out.areas[0].outer,a.outer);assert.equal(JSON.stringify(a),before);
  const next=buildCurtainLayout(out.areas[0]).panels.find(p=>p.cell[0]>panel.cell[0]&&Math.abs(p.cell[0]-panel.cell[2])<.001);assert.ok(next);assert.ok(Math.abs(Math.min(...next.rings[0].map(p=>p[0]))-Math.max(...panel.rings[0].map(p=>p[0]))-12)<.001);
 }
});
test('Repeated E2 edits use the current edge and preserve full Area coverage without overlaps',()=>{
 const a=fixture();a.curtain.gap=0;let out={areas:[a],key:'0:0:0'};for(const value of [1000,1500,800]){out=resizePanelEdge(out.areas,a.id,out.key,1,value);assert.ok(Math.abs(selectionDimensions(out.areas[0],selected(out))[1].value-value)<.001);assert.ok(Math.abs(buildCurtainLayout(out.areas[0]).panelArea-netArea(a))<1e-8)}
});
test('Unreachable edge dimensions reject atomically, and true sloped dimensions survive DXF and Reset',()=>{
 const a=fixture(),out=resizePanelEdge([a],a.id,'0:0:0',1,1000),before=JSON.stringify(out.areas);assert.throws(()=>resizePanelEdge(out.areas,a.id,out.key,1,10000));assert.equal(JSON.stringify(out.areas),before);
 const parsed=parseDxf(buildFacadeDxf(out.areas)).areas,p=buildCurtainLayout(parsed[0]).panels.find(p=>p.key===out.key);assert.ok(Math.abs(selectionDimensions(parsed[0],p)[1].value-1000)<.001);const reset=resetPanelDimensions(parsed,[{areaId:parsed[0].id,key:out.key}]);assert.deepEqual(reset.areas[0].curtain.panelPatches,[]);assert.ok(Math.abs(selectionDimensions(reset.areas[0],buildCurtainLayout(reset.areas[0]).panels.find(p=>p.key==='0:0:0'))[1].value-1318.0144196501901)<.001);
});
