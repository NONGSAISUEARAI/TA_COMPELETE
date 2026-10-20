import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {buildCurtainLayout} from '../curtain.js';
import {panelRef} from '../panel-folds.js';
import {originPanelSelection} from '../origin-panel-selection.js';

test('Origin movement keeps edge cells, interior cells and the active panel selected',()=>{
 const a=rectangle({width:4000,height:3000});a.curtain={enabled:true,reference:'world',worldOrigin:[250,0,200]};const b=structuredClone(a);b.curtain.worldOrigin=[400,0,300];
 const refs=new Set([panelRef(a.id,'-250:-200:0'),panelRef(a.id,'1200:-200:0'),panelRef(a.id,'1200:1200:0')]),out=originPanelSelection([a],[b],refs,{areaId:a.id,key:'-250:-200:0'},buildCurtainLayout);
 assert.deepEqual([...out.refs],[panelRef(a.id,'-400:-300:0'),panelRef(a.id,'1200:-300:0'),panelRef(a.id,'1200:1200:0')]);assert.deepEqual(out.active,{areaId:a.id,key:'-400:-300:0'});assert.equal(refs.size,3);
});
test('Unlocked Origin changes retain panel selection unchanged',()=>{
 const a=rectangle();a.curtain={enabled:true,reference:'world'};const b=structuredClone(a);b.pattern.origin=[300,500];const refs=new Set([panelRef(a.id,'0:0:0')]);assert.deepEqual(originPanelSelection([a],[b],refs,{areaId:a.id,key:'0:0:0'},buildCurtainLayout),{refs,active:{areaId:a.id,key:'0:0:0'}});
});
