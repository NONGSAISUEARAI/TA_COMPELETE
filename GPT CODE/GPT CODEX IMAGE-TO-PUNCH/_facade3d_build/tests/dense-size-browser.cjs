const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright'),assert=require('node:assert/strict'),path=require('node:path'),{spawn}=require('node:child_process');
(async()=>{let browser;const server=spawn(process.execPath,[path.join(__dirname,'../server.mjs')],{env:{...process.env,PORT:'4174'},stdio:['ignore','pipe','pipe'],windowsHide:true});try{
 await new Promise((r,j)=>{server.stdout.once('data',r);server.once('error',j)});
 browser=await chromium.launch({channel:'chrome',headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage({viewport:{width:1500,height:1100}}),errors=[];page.on('pageerror',e=>errors.push(e.message));page.setDefaultTimeout(30000);
 await page.route('**/app.js',async route=>{const response=await route.fetch();await route.fulfill({response,body:(await response.text())+'\nwindow.__renderCounts=()=>({meshes:surfaces.children.length,instances:surfaces.children.filter(o=>o.isInstancedMesh).reduce((n,o)=>n+o.count,0)});'});});
 await page.goto('http://127.0.0.1:4174');await page.waitForSelector('#area-width');
 const project=()=>page.evaluate(()=>JSON.parse(localStorage.getItem('facade-studio-areas-v1')));
 const initial=await project();
 await page.locator('#area-width').fill('16000');await page.locator('#area-height').fill('2100');await page.locator('#resize-area').click();
 let p=await project();assert.equal(await page.locator('#area-width').inputValue(),'16000');assert.equal(await page.locator('#area-height').inputValue(),'2100');assert.deepEqual(p.areas[0].holes[0][0],[2200,550]);assert.deepEqual(p.areas[0].base,initial.areas[0].base);
 await page.locator('#undo').click();assert.deepEqual((await project()).areas,initial.areas);
 await page.locator('#area-width').fill('0');await page.locator('#resize-area').click();assert.deepEqual((await project()).areas,initial.areas);
 await page.locator('#new-project').click();await page.locator('#confirm-action').click();await page.locator('#add-area').click();await page.locator('#new-form [name=width]').fill('106000');await page.locator('#new-form [name=height]').fill('428000');await page.locator('#new-form button[type=submit]').click();
 const start=Date.now();await page.locator('#cw-enabled').check();if(process.env.TEST_WORLD_REFERENCE==='1')await page.locator('#cw-reference').selectOption('world');
 for(const axis of ['X','Y']){await page.locator('#cw-spacing'+axis).fill('1000');await page.locator('#cw-spacing'+axis).press('Enter')}
 assert.match(await page.locator('#cw-stats').textContent(),/45368 panels/);p=await project();assert.equal(p.areas[0].curtain.spacingX,1000);assert.equal(p.areas[0].curtain.spacingY,1000);
 console.log('45368-panel enable and edits:',Date.now()-start,'ms');
 await page.locator('#view-area').click();await page.waitForTimeout(150);
 const counts=await page.evaluate(()=>window.__renderCounts());assert.equal(counts.instances,45368);assert.ok(counts.meshes<10);
 const box=await page.locator('#viewport canvas').boundingBox();await page.mouse.click(box.x+box.width*.5+3,box.y+box.height*.5+3);
 assert.match(await page.locator('#cw-selected-info').textContent(),/P\d+/);assert.equal(await page.locator('#cw-panel-override').isDisabled(),false);
 await page.locator('#cw-panel-override').selectOption('glass');assert.equal(Object.values((await project()).areas[0].curtain.overrides)[0],'glass');
 await page.locator('#area-width').fill('53000');await page.locator('#resize-area').click();assert.match(await page.locator('#cw-stats').textContent(),/22684 panels/);assert.equal((await project()).areas[0].curtain.spacingX,1000);
 await page.locator('#undo').click();assert.match(await page.locator('#cw-stats').textContent(),/45368 panels/);
 await page.reload();await page.waitForSelector('#cw-stats');assert.match(await page.locator('#cw-stats').textContent(),/45368 panels/);
 const rotated=await page.evaluate(async()=>{
  const THREE=await import('three'),{rectangle,worldPoint,cross}=await import('/geometry.js'),{buildCurtainLayout}=await import('/curtain.js'),{renderCurtain}=await import('/curtain-render.js'),{rectangleFrame,hitPanelKey}=await import('/curtain-batch.js');
  const a=rectangle({width:60000,height:30000,angle:125,x:500,y:1000});a.holes=[[[10000,10000],[20000,10000],[20000,20000],[10000,20000]]];a.curtain={enabled:true,angle:23,spacingX:1000,spacingY:1000};
  const layout=buildCurtainLayout(a),surfaces=new THREE.Group(),frames=new THREE.Group(),outlines=new THREE.Group(),normal=cross(a.u,a.v),matrix=new THREE.Matrix4().makeBasis(new THREE.Vector3(...a.u),new THREE.Vector3(...a.v),new THREE.Vector3(...normal));matrix.setPosition(new THREE.Vector3(...a.base));
  renderCurtain(a,layout,{surfaces,frames,outlines,matrix,selectedPanelKey:null});surfaces.updateMatrixWorld(true);
  const panel=layout.panels.find(p=>rectangleFrame(p.rings)),f=rectangleFrame(panel.rings),ray=new THREE.Raycaster();
  function hits(point){const target=new THREE.Vector3(...worldPoint(a,point)),n=new THREE.Vector3(...normal);ray.set(target.clone().addScaledVector(n,10000),n.negate());return ray.intersectObjects(surfaces.children)}
  const result={panels:layout.panels.length,objects:surfaces.children.length,picked:hitPanelKey(hits([f.x,f.y])[0])===panel.key,holeHits:hits([15000,15000]).length};
  for(const group of [surfaces,frames,outlines])group.traverse(o=>{if(o.isInstancedMesh)o.dispose();o.geometry?.dispose();o.material?.dispose()});
  return result;
 });
 assert.ok(rotated.panels>1000);assert.ok(rotated.objects<rotated.panels/4);assert.equal(rotated.picked,true);assert.equal(rotated.holeHits,0);
 assert.deepEqual(errors,[]);console.log('PASS: numeric Area resize, holes, atomic invalid input, 45368-panel scene, instance picking, panel override, resize with fixed spacing, Undo and reload.');
}finally{await browser?.close();server.kill()}})().catch(e=>{console.error(e);process.exitCode=1});
