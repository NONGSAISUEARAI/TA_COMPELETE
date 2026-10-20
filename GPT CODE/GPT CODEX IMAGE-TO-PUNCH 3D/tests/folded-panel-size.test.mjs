import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {joinFoldedPanels,foldedAssemblies,unjoinFoldedPanels} from '../panel-folds.js';
import {foldedPanelSize} from '../folded-panel-size.js';
import {foldedFaceMetrics,resizeFoldedPanel,validateFoldedSheetLimits} from '../folded-panel-resize.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
import {createOriginSnap} from '../origin-snap.js';
import {buildCurtainLayout} from '../curtain.js';
const fixture=()=>{const a=rectangle({width:2400,height:2400}),b=rectangle({x:2400,angle:90,width:1200,height:2400});for(const x of [a,b])x.curtain={enabled:true,reference:'world'};return joinFoldedPanels([a,b],[{areaId:a.id,key:'1200:0:0'},{areaId:b.id,key:'0:0:0'}])};
const info=areas=>{const group=foldedAssemblies(areas)[0];return {id:group.group,size:foldedPanelSize(group),wings:foldedFaceMetrics(group).map(m=>m.width)}};
test('Blank dimensions measure the whole developed sheet, not one face or a 3D box',()=>{const d=info(fixture());assert.equal(d.size.width,2388);assert.equal(d.size.height,1188);assert.deepEqual(d.wings,[1194,1194])});
test('1200 total width allocates 900 + 300 automatically and changes real geometry',()=>{
 let areas=fixture(),before=JSON.stringify(areas),id=info(areas).id;areas=resizeFoldedPanel(areas,id,'width',1200);assert.equal(info(areas).size.width,1200);assert.deepEqual(info(areas).wings,[600,600]);areas=resizeFoldedPanel(areas,id,'wing0',900);assert.deepEqual(info(areas).wings,[900,300]);areas=resizeFoldedPanel(areas,id,'wing1',400);assert.deepEqual(info(areas).wings,[800,400]);assert.notEqual(JSON.stringify(areas),before);assert.ok(buildCurtainLayout(areas[1]).panels.length>2);
 const free=unjoinFoldedPanels(areas,foldedAssemblies(areas)[0].members.map(m=>({areaId:m.a.id,key:m.panel.key})));assert.ok(Object.keys(free[0].curtain.cutOverridesX).length>0);
});
test('Height cap shrinks both faces and rejects oversize or impossible allocations atomically',()=>{
 let a=fixture(),id=info(a).id;a=resizeFoldedPanel(a,id,'width',1200);a=resizeFoldedPanel(a,id,'maxHeight',1000);assert.equal(info(a).size.height,1000);const before=JSON.stringify(a);for(const [key,value]of [['height',1100],['wing0',1200],['wing1',-10],['width',100000]])assert.throws(()=>resizeFoldedPanel(a,id,key,value));assert.equal(JSON.stringify(a),before);a=resizeFoldedPanel(a,id,'height',800);assert.equal(info(a).size.height,800);validateFoldedSheetLimits(foldedAssemblies(a));
});
test('Manual split positions and stock limits survive JSON, DXF and unit conversion',()=>{
 let a=fixture(),id=info(a).id;a=resizeFoldedPanel(a,id,'width',1200);a=resizeFoldedPanel(a,id,'wing0',900);a=resizeFoldedPanel(a,id,'maxHeight',1000);assert.deepEqual(info(JSON.parse(JSON.stringify(a))).wings,[900,300]);const parsed=parseDxf(buildFacadeDxf(a)).areas;assert.deepEqual(info(parsed).wings,[900,300]);const scaled=parseDxf(buildFacadeDxf(a),'10').areas;assert.deepEqual(info(scaled).wings,[9000,3000]);assert.equal(info(scaled).size.height,10000);validateFoldedSheetLimits(foldedAssemblies(scaled));
});

test('A wider sheet redistributes into the available wings and snap follows moved split lines',()=>{
 let a=fixture(),id=info(a).id;a=resizeFoldedPanel(a,id,'width',2440);assert.deepEqual(info(a).wings,[1246,1194]);a=resizeFoldedPanel(a,id,'wing0',1900);assert.deepEqual(info(a).wings,[1900,540]);
 a=resizeFoldedPanel(a,id,'width',1200);a=resizeFoldedPanel(a,id,'wing0',900);a=resizeFoldedPanel(a,id,'maxHeight',1000);const snap=createOriginSnap(a[0],buildCurtainLayout(a[0]).panels);assert.deepEqual(snap([1494,1012],10,515),{point:[1494,1012],type:'Joint center'});
});
test('Folded height changes keep an upper Pattern Origin fixed while both faces contract toward it',()=>{
 let areas=fixture();areas[0].pattern.origin=[0,1194];const id=info(areas).id,before=structuredClone(areas[0].pattern);areas=resizeFoldedPanel(areas,id,'height',800);const g=foldedAssemblies(areas)[0];assert.equal(foldedPanelSize(g).height,800);assert.deepEqual(areas[0].pattern,before);for(const member of g.members){const ys=member.panel.rings[0].map(p=>p[1]);assert.equal(Math.max(...ys),1194);assert.equal(Math.min(...ys),394)}
});
