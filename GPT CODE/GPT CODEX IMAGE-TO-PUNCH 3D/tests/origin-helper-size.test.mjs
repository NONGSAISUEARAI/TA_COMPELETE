import test from 'node:test';
import assert from 'node:assert/strict';
import {originHelperWorldSize} from '../origin-helper-size.js';
test('Origin helpers shrink in screen space when zooming in and never exceed 48 px',()=>{
 let previous=Infinity;for(const unit of [30,10,3,1,.1,.001]){const size=originHelperWorldSize(1200,unit),pixels=size*.85/unit;assert.ok(pixels<=48+1e-8);assert.ok(pixels<=previous+1e-8);assert.ok(size>0&&size<=1200);previous=pixels}
 assert.equal(previous,14);
});
