const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright'),assert=require('node:assert/strict'),path=require('node:path'),{spawn}=require('node:child_process');
(async()=>{let browser;const server=spawn(process.execPath,[path.join(__dirname,'../server.mjs')],{env:{...process.env,PORT:'4174'},stdio:['ignore','pipe','pipe'],windowsHide:true});try{
 await new Promise((r,j)=>{server.stdout.once('data',r);server.once('error',j)});
 browser=await chromium.launch({channel:'chrome',headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('http://127.0.0.1:4174');
 const results=await page.evaluate(async()=>{
  const THREE=await import('/vendor/three.module.js'),{rectangle,worldPoint,cross}=await import('/geometry.js'),{joinFoldedPanels,foldedAssemblies}=await import('/panel-folds.js'),{resizeFoldedPanel}=await import('/folded-panel-resize.js'),{buildCurtainLayout}=await import('/curtain.js'),{createOriginSnap}=await import('/origin-snap.js'),{originSnapScreen}=await import('/origin-snap-screen.js');
  const a=rectangle({width:2400,height:2400}),b=rectangle({x:2400,angle:90,width:1200,height:2400});for(const x of [a,b])x.curtain={enabled:true,reference:'world'};
  let areas=joinFoldedPanels([a,b],[{areaId:a.id,key:'1200:0:0'},{areaId:b.id,key:'0:0:0'}]),id=foldedAssemblies(areas)[0].group;
  for(const [key,value]of [['width',1200],['wing0',900],['maxHeight',1000]])areas=resizeFoldedPanel(areas,id,key,value);
  const rect={left:30,top:50,width:1000,height:1000},results=[];
  for(const [index,mouse,compressed]of [[0,[1520,1006],'u'],[1,[280,506],'u'],[0,[1497.5,1010.5],'v']])for(const perspective of [false,true]){
   const face=areas[index],target=new THREE.Vector3(...worldPoint(face,mouse)),camera=perspective?new THREE.PerspectiveCamera(40,1,1,1e7):new THREE.OrthographicCamera(-1000,1000,1000,-1000,1,1e7);
   camera.up.set(...face.v);camera.position.copy(target).addScaledVector(new THREE.Vector3(...face[compressed]),5000).addScaledVector(new THREE.Vector3(...cross(face.u,face.v)),500);camera.lookAt(target);camera.updateMatrixWorld();
   const projected=target.clone().project(camera),screen=originSnapScreen(face,camera,rect,rect.left+(projected.x+1)*500,rect.top+(1-projected.y)*500);
   const snap=createOriginSnap(face,buildCurtainLayout(face).panels),result=snap(mouse,14,515,null,screen);
   results.push({index,compressed,perspective,result,pixels:screen.distance(result.point)});
  }
  return results;
 });
 for(const row of results){const expected=row.index===1?[300,506]:[1500,1006];assert.deepEqual(row.result.point,expected,JSON.stringify(row));assert.ok(row.pixels<=14)}
 assert.deepEqual(errors,[]);console.log('PASS: pixel aperture and closest visible target on both resized folded faces, orthographic and perspective cameras.');
}finally{await browser?.close();server.kill()}})().catch(e=>{console.error(e);process.exitCode=1});
