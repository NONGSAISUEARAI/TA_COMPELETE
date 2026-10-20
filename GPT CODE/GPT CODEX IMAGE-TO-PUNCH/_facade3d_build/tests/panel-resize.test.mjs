import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,worldPoint} from '../geometry.js';
import {buildCurtainLayout} from '../curtain.js';
import {resizePanel,panelDimensions} from '../panel-resize.js';
import {resetPanelDimensions} from '../panel-size-reset.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
import {createOriginSnap} from '../origin-snap.js';
const fixture=origin=>{const a=rectangle({width:6000,height:3600});a.pattern.origin=origin??[0,0];a.curtain={enabled:true,reference:'world',gapAtBoundary:false};return a};
const row=a=>buildCurtainLayout(a).panels.filter(p=>p.key.endsWith(':0:0')).map(p=>({key:p.key,...panelDimensions(a,p)})).sort((a,b)=>a.low[0]-b.low[0]);

test('Editing a clicked panel changes only its width; subsequent panels translate, while Origin and preceding panels stay fixed',()=>{
 const a=fixture(),original=JSON.stringify(a),out=resizePanel([a],a.id,'1200:0:0','width',600),panels=row(out.areas[0]);
 assert.equal(panels[0].width,1194);assert.equal(panels[1].width,600);assert.equal(panels[2].low[0],1818);assert.equal(panels[2].width,1188);assert.deepEqual(out.areas[0].pattern,a.pattern);assert.deepEqual(out.areas[0].curtain.worldOrigin,[0,0,0]);assert.equal(JSON.stringify(a),original);
 const untouched=buildCurtainLayout(out.areas[0]).panels.find(p=>p.key==='1200:1200:0');assert.equal(panelDimensions(out.areas[0],untouched).width,1188);
});
test('A panel on the other side of Origin keeps its nearer edge and translates panels outward to the left',()=>{
 const a=fixture([6000,0]),out=resizePanel([a],a.id,'1200:0:0','width',600),p=buildCurtainLayout(out.areas[0]).panels.find(p=>p.key===out.key),m=panelDimensions(out.areas[0],p);
 assert.equal(m.high[0],2394);assert.equal(m.low[0],1794);assert.deepEqual(out.areas[0].pattern.origin,[6000,0]);
});
test('Origin inside the resized panel remains fixed while both edges contract around it',()=>{
 const a=fixture([1800,600]),before=worldPoint(a,a.pattern.origin),out=resizePanel([a],a.id,'1200:0:0','width',600),p=buildCurtainLayout(out.areas[0]).panels.find(p=>p.key===out.key),m=panelDimensions(out.areas[0],p);
 assert.equal(m.low[0],1500);assert.equal(m.high[0],2100);assert.deepEqual(worldPoint(out.areas[0],out.areas[0].pattern.origin),before);
});
test('Width and Height edits persist in DXF, reset their complete start chains, and reject impossible sizes atomically',()=>{
 const a=fixture(),w=resizePanel([a],a.id,'1200:0:0','width',600),h=resizePanel(w.areas,a.id,w.key,'height',800),saved=JSON.stringify(h.areas);assert.throws(()=>resizePanel(h.areas,a.id,h.key,'width',10000));assert.equal(JSON.stringify(h.areas),saved);
 for(const scale of [1,10]){const list=scale===1?JSON.parse(saved):parseDxf(buildFacadeDxf(h.areas),'10').areas,key=Object.keys(list[0].curtain.panelSizes)[0],before=JSON.stringify(list),out=resetPanelDimensions(list,[{areaId:list[0].id,key}]);assert.deepEqual(out.areas[0].curtain.cutOverridesX,{});assert.deepEqual(out.areas[0].curtain.cutOverridesY,{});assert.deepEqual(out.areas[0].curtain.panelSizes,{});assert.deepEqual(out.areas[0].curtain.panelPatches,[]);assert.equal(JSON.stringify(list),before)}
});
test('Local row/column edits cover the Area without overlap and preserve unaffected panel dimensions',()=>{
 const a=fixture();a.curtain.gap=0;const w=resizePanel([a],a.id,'1200:0:0','width',600),h=resizePanel(w.areas,a.id,w.key,'height',800),layout=buildCurtainLayout(h.areas[0]);assert.ok(Math.abs(layout.panelArea-21.6)<1e-8);
 for(let i=0;i<layout.cells.length;i++)for(let j=i+1;j<layout.cells.length;j++){const x=layout.cells[i].bounds,y=layout.cells[j].bounds;assert.ok(Math.min(x[2],y[2])-Math.max(x[0],y[0])<.001||Math.min(x[3],y[3])-Math.max(x[1],y[1])<.001)}
 const left=layout.panels.find(p=>p.key==='0:0:0');assert.equal(panelDimensions(h.areas[0],left).height,1200);
});
test('Snap and grid follow the local edited row and ignore obsolete joint positions',()=>{
 const a=fixture(),out=resizePanel([a],a.id,'1200:0:0','width',600),layout=buildCurtainLayout(out.areas[0]),snap=createOriginSnap(out.areas[0],layout.panels);
 assert.deepEqual(snap([1812,1200],2,1024).point,[1812,1200]);assert.equal(snap([2400,0],2,1024).type,null);assert.ok(!layout.grid.some(([p,q])=>p[0]===2400&&q[0]===2400&&p[1]===0));
});
