import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {joinFoldedPanels,foldedAssemblies} from '../panel-folds.js';
import {foldedPanelSize} from '../folded-panel-size.js';
import {resizeFoldedPanel,foldedFaceMetrics} from '../folded-panel-resize.js';
import {resetPanelDimensions} from '../panel-size-reset.js';
function fixture(){const a=rectangle({width:2400,height:2400}),b=rectangle({x:2400,angle:90,width:1200,height:2400}),other=rectangle();for(const x of [a,b])x.curtain={enabled:true,reference:'world'};return joinFoldedPanels([a,b,other],[{areaId:a.id,key:'1200:0:0'},{areaId:b.id,key:'0:0:0'}])}
test('Reset restores folded dimensions and clears sheet caps while preserving the fold and unrelated areas',()=>{
 const original=fixture(),id=foldedAssemblies(original)[0].group;let areas=original;
 for(const [key,value]of [['width',1200],['wing0',900],['maxHeight',1000],['height',800]])areas=resizeFoldedPanel(areas,id,key,value);
 const before=JSON.stringify(areas),g=foldedAssemblies(areas)[0],result=resetPanelDimensions(areas,[{areaId:g.members[0].a.id,key:g.members[0].panel.key}]),after=foldedAssemblies(result.areas)[0];
 assert.equal(after.group,id);assert.deepEqual(foldedFaceMetrics(after).map(m=>m.width),[1194,1194]);assert.equal(foldedPanelSize(after).height,1188);assert.equal(result.refs.size,2);assert.strictEqual(result.areas[2],areas[2]);assert.equal(JSON.stringify(areas),before);
 for(const member of after.members){const c=member.a.curtain;assert.deepEqual(c.cutOverridesX,{});assert.deepEqual(c.cutOverridesY,{});assert.equal(c.panelJoins[member.panel.key].sheet,undefined);assert.equal(c.spacingX,1200);assert.equal(c.reference,'world')}
});
test('Reset only removes split overrides bordering selected panels and preserves appearance overrides',()=>{
 const a=rectangle({width:4800,height:3600});a.curtain={enabled:true,reference:'world',cutOverridesX:{1200:1000,3600:3500},cutOverridesY:{1200:1000},overrides:{'1000:0:0':'glass'}};
 const result=resetPanelDimensions([a],[{areaId:a.id,key:'1000:0:0'}]);assert.deepEqual(result.areas[0].curtain.cutOverridesX,{3600:3500});assert.deepEqual(result.areas[0].curtain.cutOverridesY,{});assert.deepEqual(result.areas[0].curtain.overrides,{'1200:0:0':'glass'});
});
