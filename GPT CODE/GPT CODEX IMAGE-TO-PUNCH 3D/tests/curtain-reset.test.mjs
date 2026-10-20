import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {defaultCurtain} from '../curtain-settings.js';
import {resetCurtainAreas} from '../curtain-reset.js';
import {joinCurtainAreas} from '../curtain-join.js';
import {joinFoldedPanels,foldedAssemblies} from '../panel-folds.js';

test('Reset restores selected settings while retaining geometry, Pattern Origin and enabled state',()=>{
 const a=rectangle(),b=rectangle();a.pattern.origin=[100,200];a.curtain={enabled:true,spacingX:900,followPatternOrigin:true,customX:[50],cutOverridesX:{900:800},overrides:{'0:0:0':'glass'}};b.curtain={enabled:false,spacingX:500};
 const before=structuredClone([a,b]),next=resetCurtainAreas([a,b],new Set([a.id]));
 assert.deepEqual(next[0],{...a,curtain:{...defaultCurtain(),enabled:true}});assert.strictEqual(next[1],b);assert.deepEqual([a,b],before);
 const multi=resetCurtainAreas([a,b],new Set([a.id,b.id]));assert.deepEqual(multi[1].curtain,defaultCurtain());
});
test('Reset detaches corner relationships on both sides without resetting unselected settings',()=>{
 const a=rectangle({width:2400,height:2400}),b=rectangle({x:2400,angle:90,width:1200,height:2400}),other=rectangle();for(const x of [a,b])x.curtain={enabled:true,reference:'world'};
 let areas=joinFoldedPanels([a,b,other],[{areaId:a.id,key:'1200:0:0'},{areaId:b.id,key:'0:0:0'}]);areas=joinCurtainAreas(areas,new Set([a.id,b.id]),a.id);
 const next=resetCurtainAreas(areas,new Set([a.id]));assert.equal(foldedAssemblies(next).length,0);assert.equal(next[1].curtain.join,null);assert.deepEqual(next[1].curtain.panelJoins,{});assert.equal(next[1].curtain.reference,'world');assert.strictEqual(next[2],other);assert.equal(foldedAssemblies(areas).length,1);
});
