import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {joinFoldedPanels,foldedAssemblies} from '../panel-folds.js';
import {resizeFoldedPanel,foldedFaceMetrics} from '../folded-panel-resize.js';
import {buildCurtainLayout} from '../curtain.js';
import {resetPanelDimensions} from '../panel-size-reset.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
function fixture(width=6000){const a=rectangle({width,height:3600}),b=rectangle({x:width,angle:90,width,height:3600});for(const x of [a,b])x.curtain={enabled:true,reference:'world'};return joinFoldedPanels([a,b],[{areaId:a.id,key:`${width-1200}:0:0`},{areaId:b.id,key:'0:0:0'}])}
function resize(areas){const id=foldedAssemblies(areas)[0].group;areas=resizeFoldedPanel(areas,id,'width',1200);return resizeFoldedPanel(areas,id,'wing0',900)}
const xs=a=>buildCurtainLayout(a).grid.filter(([p,q])=>Math.abs(p[0]-q[0])<.001).map(([p])=>p[0]);
test('Both wings restart subsequent panels from the resized corner, with gap and unchanged pitch',()=>{
 const original=fixture(),areas=resize(original);assert.deepEqual(xs(areas[0]),[294,1494,2694,3894,5094]);assert.deepEqual(xs(areas[1]),[306,1506,2706,3906,5106]);
 const panels=buildCurtainLayout(areas[1]).panels.filter(p=>p.key.endsWith(':0:0'));
 assert.deepEqual(panels.slice(0,3).map(p=>Math.min(...p.rings[0].map(q=>q[0]))),[0,312,1512]);
 for(const a of areas){assert.equal(a.curtain.spacingX,1200);assert.deepEqual(a.curtain.worldOrigin,[0,0,0]);for(const p of buildCurtainLayout(a).panels.filter(p=>!p.foldGroup)){const x=p.rings[0].map(q=>q[0]);assert.ok(Math.max(...x)-Math.min(...x)<=1200+.01)}}
 assert.deepEqual(foldedFaceMetrics(foldedAssemblies(areas)[0]).map(m=>m.width),[900,300]);
});
test('Repeated edits and height changes reflow starts without leftover former grid lines',()=>{
 let areas=resize(fixture()),id=foldedAssemblies(areas)[0].group;areas=resizeFoldedPanel(areas,id,'wing0',600);assert.deepEqual(xs(areas[1]),[606,1806,3006,4206,5406]);areas=resizeFoldedPanel(areas,id,'wing0',900);assert.deepEqual(xs(areas[1]),[306,1506,2706,3906,5106]);areas=resizeFoldedPanel(areas,id,'maxHeight',1000);
 for(const a of areas){const ys=buildCurtainLayout(a).grid.filter(([p,q])=>Math.abs(p[1]-q[1])<.001).map(([p])=>p[1]);assert.deepEqual(ys,[1012,2212,3412])}
});
test('Reset reverses the complete start chain, including after DXF scaling',()=>{
 const original=fixture(),areas=resize(original);for(const scale of [1,10]){const parsed=scale===1?JSON.parse(JSON.stringify(areas)):parseDxf(buildFacadeDxf(areas),'10').areas,g=foldedAssemblies(parsed)[0],out=resetPanelDimensions(parsed,g.members.map(m=>({areaId:m.a.id,key:m.panel.key}))).areas;for(const a of out){assert.deepEqual(xs(a),[1200,2400,3600,4800].map(x=>x*scale));assert.deepEqual(a.curtain.cutOverridesX,{});assert.deepEqual(a.curtain.cutOverridesY,{})}}
});
test('Start reflow works on facades longer than 100 cells',()=>{const areas=resize(fixture(156000));for(const a of areas){const lines=xs(a);assert.ok(lines.length>100);for(let i=1;i<lines.length;i++)assert.ok(Math.abs(lines[i]-lines[i-1]-1200)<.01)}});
test('Re-entering a saved legacy size repairs stale starts without changing the requested wings',()=>{
 const areas=fixture(),id=foldedAssemblies(areas)[0].group,left=areas[0].curtain,right=areas[1].curtain;
 left.panelJoins['5094:0:0']=left.panelJoins['4800:0:0'];delete left.panelJoins['4800:0:0'];left.cutOverridesX={4800:5094};right.cutOverridesX={1200:306};
 for(const a of areas)for(const j of Object.values(a.curtain.panelJoins))j.sheet={width:1200,height:1188};
 const fixed=resizeFoldedPanel(areas,id,'width',1200);assert.deepEqual(xs(fixed[0]),[294,1494,2694,3894,5094]);assert.deepEqual(xs(fixed[1]),[306,1506,2706,3906,5106]);assert.deepEqual(foldedFaceMetrics(foldedAssemblies(fixed)[0]).map(m=>m.width),[900,300]);
});
