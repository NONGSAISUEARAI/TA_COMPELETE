const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),{pathToFileURL}=require('node:url'),{chromium}=require('playwright');
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
 const page=await browser.newPage({viewport:{width:1450,height:1050}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.resolve('Master_Schedule.html')).href);
 await page.locator('#unlock-editor').click();await page.locator('#unlock-password').fill('123123');await page.waitForFunction(()=>isEditor);
 const ids=await page.evaluate(()=>{const source=state.tasks.find(t=>databaseLevel(t)===3&&databaseProduct(t).product==='C04'),dest=state.tasks.find(t=>databaseLevel(t)===3&&databaseProduct(t).product==='C05');return [source.id,dest.id]});
 const data=await page.evaluate(()=>JSON.stringify(state));
 await page.evaluate(id=>openTask(id),ids[0]);assert.equal(await page.locator('#paste-task-plan').isDisabled(),true);
 await page.locator('#f-start').fill('2026-11-16');await page.locator('#f-end').fill('2026-11-20');
 await page.locator('#f-actualStart').fill('2026-11-02');await page.locator('#f-actualEnd').fill('2026-11-03');await page.locator('#f-progress').fill('37');
 for(const [key,value] of Object.entries({currentInfo:'ตรวจครบ',unit:'แผ่น',quantity:'0',workStatus:'ดำเนินการ',action:'ขอราคา',approvedDate:'2026-11-12',remark:'หมายเหตุ QA'}))await page.locator('#f-'+key).fill(value);
 await page.evaluate(()=>{taskFileDraft={rootName:'QA',address:'C:/QA',source:'local',files:[{name:'drawing.pdf',path:'drawing.pdf',selected:true,size:10,modified:0}]};$('task-file-address').value='C:/QA';taskFileDirty=true;renderTaskFiles()});await page.locator('#copy-task-plan').click();
 await page.locator('#task-dialog .close').click();await page.evaluate(id=>openTask(id),ids[1]);await page.locator('#paste-task-plan').click();
 assert.equal(await page.locator('#f-start').inputValue(),'2026-11-16');assert.equal(await page.locator('#f-product').inputValue(),'C05');
 assert.equal(await page.locator('#f-actualStart').inputValue(),'2026-11-02');assert.equal(await page.locator('#f-progress').inputValue(),'37');assert.equal(await page.locator('#f-quantity').inputValue(),'0');assert.equal(await page.locator('#f-remark').inputValue(),'หมายเหตุ QA');assert.match(await page.locator('#task-file-count').innerText(),/1/);
 assert.equal(await page.evaluate(()=>JSON.stringify(state)),data);
 fs.mkdirSync('outputs/plan-clipboard',{recursive:true});await page.screenshot({path:'outputs/plan-clipboard/desktop.png'});
 for(const width of [700,390]){await page.setViewportSize({width,height:900});for(const selector of ['#copy-task-plan','#paste-task-plan','#task-dialog .close']){const box=await page.locator(selector).boundingBox();assert(box&&box.x>=0&&box.x+box.width<=width,selector+' fits '+width)} }
 await page.screenshot({path:'outputs/plan-clipboard/mobile.png'});
 await page.locator('#task-dialog .close').click();assert.equal(await page.evaluate(()=>JSON.stringify(state)),data);
 await page.setViewportSize({width:1450,height:1050});await page.evaluate(id=>openTask(id),ids[1]);await page.locator('#paste-task-plan').click();await page.locator('#task-form button[type=submit]').click();
 assert.equal(await page.locator('#task-dialog').isVisible(),false);assert.equal(await page.evaluate(id=>state.tasks.find(t=>t.id===id).start,ids[1]),'2026-11-16');
 const saved=await page.evaluate(id=>state.tasks.find(t=>t.id===id),ids[1]);assert.equal(saved.actualStart,'2026-11-02');assert.equal(saved.progress,37);assert.equal(saved.quantity,0);assert.equal(saved.remark,'หมายเหตุ QA');assert.equal(saved.fileCatalog.files[0].selected,true);
 assert.deepEqual(errors,[]);console.log('PASS: Edge full-field copy/paste and Save, Actual/progress/documents/selected files, target C05 identity, cancellation, desktop/mobile buttons, no browser errors.');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
