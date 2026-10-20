import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle,worldPoint,areaFromWorld} from '../geometry.js';
import {buildFacadeDxf,parseDxf} from '../dxf.js';
import {mergeDxfUpdate} from '../dxf-update.js';

const tag=(a,handle,layer='FRONT',file='drawing.dxf')=>({...a,dxfSource:{handle,layer,...(file?{file}:{})}});
test('DXF parser exposes stable handle, layer and metadata identity',()=>{
 const a=rectangle(),p=parseDxf(buildFacadeDxf([a])).areas[0];
 assert.equal(p.dxfSource.metadataId,a.id);assert.ok(p.dxfSource.handle);assert.equal(p.dxfSource.layer,'AREA_001');
});
test('exported Area identity reconnects after Save As without duplicating the Area',()=>{
 const old=tag(rectangle(),'10');old.curtain={enabled:true,spacingX:1700};
 const saved=parseDxf(buildFacadeDxf([old])).areas;
 const result=mergeDxfUpdate([old],saved,'saved-from-cad.dxf');
 assert.equal(result.added,0);assert.equal(result.areas.length,1);assert.equal(result.areas[0].id,old.id);assert.equal(result.areas[0].dxfSource.file,'saved-from-cad.dxf');assert.equal(result.areas[0].curtain.spacingX,1700);
});
test('update matches CAD handle, preserves settings and unrelated Areas, and retains missing Areas',()=>{
 const old=tag(rectangle({name:'My facade'}),'10');old.curtain={enabled:true,origin:[500,600],angle:20,spacingX:1500,mullionOffset:-70};
 const other=tag(rectangle(),'10','OTHER','other.dxf'),missing=tag(rectangle(),'12','MISSING');
 const next=tag(rectangle({width:9000}),'10','RENAMED',null),added=tag(rectangle(),'11','NEW',null);
 const result=mergeDxfUpdate([old,other,missing],[next,added],'drawing.dxf');
 assert.equal(result.updated,1);assert.equal(result.added,1);assert.equal(result.missing,1);assert.equal(result.areas[0].id,old.id);assert.equal(result.areas[0].name,'My facade');assert.deepEqual(result.areas[0].curtain,old.curtain);assert.deepEqual(result.areas[1],other);assert.deepEqual(result.areas[2],missing);
 assert.equal(result.areas[0].outer[1][0],9000);assert.equal(old.outer[1][0],6000);
});
test('frame changes preserve world origin and axes instead of copying local coordinates',()=>{
 const old=tag(rectangle({angle:125}),'AA');old.pattern.origin=[500,900];old.pattern.angle=23;old.curtain={origin:[1100,1300],angle:15};
 const points=old.outer.map(p=>worldPoint(old,p));const next=tag(areaFromWorld([...points.slice(1),points[0]],'FRONT'),'AA',undefined,null);
 const updated=mergeDxfUpdate([old],[next],'drawing.dxf').areas[0];
 for(const key of ['pattern','curtain']){const a=worldPoint(old,old[key].origin),b=worldPoint(updated,updated[key].origin);a.forEach((n,i)=>assert.ok(Math.abs(n-b[i])<1e-6))}
 assert.ok(Math.abs(updated.pattern.angle-old.pattern.angle)>1);
});
test('legacy unique-layer fallback works; ambiguous layers reject atomically',()=>{
 const a=rectangle({name:'FRONT'}),next=tag(rectangle({width:9000}),'B','FRONT',null);
 assert.equal(mergeDxfUpdate([a],[next],'drawing.dxf').areas[0].id,a.id);
 const b=rectangle({name:'FRONT'});assert.throws(()=>mergeDxfUpdate([a,b],[next],'drawing.dxf'),/หลาย Area/);assert.equal(a.outer[1][0],6000);
});
test('new handles sharing a layer are resolved after all exact matches; identifiers cannot map twice',()=>{
 const a=tag(rectangle(),'A'),old=tag(rectangle(),'A','FRONT',null),added=tag(rectangle(),'B','FRONT',null);
 assert.equal(mergeDxfUpdate([a],[added,old],'drawing.dxf').added,1);
 assert.throws(()=>mergeDxfUpdate([a],[old,old],'drawing.dxf'),/เดียวกัน/);
});
