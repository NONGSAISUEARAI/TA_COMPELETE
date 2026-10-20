import test from 'node:test';
import assert from 'node:assert/strict';
import {rectangle} from '../geometry.js';
import {joinFoldedPanels,foldedAssemblies} from '../panel-folds.js';
import {resizeFoldedPanel} from '../folded-panel-resize.js';
import {buildCurtainLayout} from '../curtain.js';
import {createOriginSnap} from '../origin-snap.js';

function fixture(){
 const a=rectangle({width:2400,height:2400}),b=rectangle({x:2400,angle:90,width:1200,height:2400});
 for(const face of [a,b])face.curtain={enabled:true,reference:'world'};
 let areas=joinFoldedPanels([a,b],[{areaId:a.id,key:'1200:0:0'},{areaId:b.id,key:'0:0:0'}]);
 const group=foldedAssemblies(areas)[0].group;
 for(const [key,value]of [['width',1200],['wing0',900],['maxHeight',1000]])areas=resizeFoldedPanel(areas,group,key,value);
 return areas;
}
const screenAt=(p,sx=.1,sy=1)=>({radius:14,bounds:p.map((v,i)=>[v-14/(i?sy:sx),v+14/(i?sy:sx)]),distance:q=>Math.hypot((q[0]-p[0])*sx,(q[1]-p[1])*sy)});

test('Resized folded-panel corners and bend midpoints remain reachable on foreshortened faces',()=>{
 const [a,b]=fixture();
 for(const [face,mouse,target,type]of [[a,[1520,1006],[1500,1006],'Panel corner'],[a,[2380,506],[2400,506],'Panel midpoint'],[b,[280,506],[300,506],'Panel midpoint'],[b,[20,1006],[0,1006],'Panel corner']]){
  const snap=createOriginSnap(face,buildCurtainLayout(face).panels);
  assert.deepEqual(snap(mouse,14,515,null,screenAt(mouse)),{point:target,type});
  assert.equal(snap(mouse,14,515|16384,null,screenAt(mouse)).type,null);
 }
});

test('Screen distance chooses the point under the cursor instead of the closest local coordinate',()=>{
 const [a]=fixture(),snap=createOriginSnap(a,buildCurtainLayout(a).panels),mouse=[1497.5,1010.5];
 // Local distance favors the gap intersection (1494,1012); screen distance
 // favors the finished corner (1500,1006) when the vertical axis is compressed.
 assert.deepEqual(snap(mouse,30,515).point,[1494,1012]);
 const screen=screenAt(mouse,1,.05);
 assert.deepEqual(snap(mouse,30,515,null,screen),{point:[1500,1006],type:'Panel corner'});
});

test('Moved grid intersections acquire in screen pixels and never restore the old split',()=>{
 const [a]=fixture(),snap=createOriginSnap(a,buildCurtainLayout(a).panels),mouse=[1514,1012];
 assert.deepEqual(snap(mouse,14,1024,null,screenAt(mouse)),{point:[1494,1012],type:'Joint center'});
 assert.equal(snap([1200,1012],14,1024,null,screenAt([1200,1012])).type,null);
});
