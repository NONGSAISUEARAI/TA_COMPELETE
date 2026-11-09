const {chromium}=require('playwright'),path=require('path'),fs=require('fs'),assert=require('assert/strict');
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
 const page=await browser.newPage({viewport:{width:1640,height:1000}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(require('url').pathToFileURL(path.resolve('Master_Schedule.html')).href);
 await page.locator('#tasks tr').first().waitFor();assert.equal(await page.locator('#tasks tr').count(),38);
 assert.equal(await page.locator('tr[data-task="pj25-031-c02-work-1"] [data-date-row="plan"]').count(),2);
 assert.equal(await page.locator('tr[data-task="pj25-031-c02-work-1"] [data-add-task-child]').count(),0);
 await page.evaluate(()=>{isEditor=true;applyRole();openTask(null,'pj25-031')});
 assert.equal(await page.locator('#f-product').isVisible(),true);assert.equal(await page.locator('#f-name').isVisible(),false);
 await page.locator('#f-product').fill('C11');await page.locator('#task-form button[type="submit"]').click();
 assert.equal(await page.locator('#task-dialog').isVisible(),false);assert.equal(await page.locator('#tasks tr').count(),39);
 await page.evaluate(()=>openTask(null,null,'pj25-031-product-c04'));
 await page.locator('#f-name').fill('BROWSER TEST');await page.locator('#f-start').fill('2026-11-09');await page.locator('#f-end').fill('2026-11-14');
 await page.locator('#f-actualStart').fill('2026-11-10');await page.locator('#f-actualEnd').fill('2026-11-12');
 await page.locator('#task-form button[type="submit"]').click();assert.equal(await page.locator('#task-dialog').isVisible(),false);
 assert.equal(await page.evaluate(()=>state.tasks.find(t=>t.name==='BROWSER TEST').actualStart),'2026-11-10');
 await page.evaluate(()=>{openTask('pj25-031-product-c04')});await page.locator('#f-product').fill('C04A');await page.locator('#task-form button[type="submit"]').click();
 assert.equal(await page.evaluate(()=>drawingFieldsFor(state.tasks.find(t=>t.name==='BROWSER TEST')).product),'C04A');
 await page.reload();await page.locator('#tasks tr').first().waitFor();
 // Use the saved HTML data, dismissing any browser-local draft recovery prompt.
 await page.evaluate(()=>{localStorage.clear()});await page.reload();await page.locator('#tasks tr').first().waitFor();
 assert.equal(await page.locator('#tasks tr').count(),38);
 await page.locator('#tasks').evaluate(el=>el.closest('table').scrollIntoView());
 const inline=await page.locator('tr[data-task="pj25-031-product-c02"] .db-title-line').evaluate(el=>{const a=el.querySelector('.group-toggle').getBoundingClientRect(),b=el.querySelector('summary').getBoundingClientRect();return Math.abs(a.top-b.top)<12&&b.left>=a.right});assert(inline,'Product file count sits beside title');
 fs.mkdirSync('outputs/database',{recursive:true});await page.screenshot({path:'outputs/database/Master_Schedule_Rev03.png',fullPage:false});
 assert.deepEqual(errors,[]);console.log(JSON.stringify({result:'PASS',browser:'Headless Microsoft Edge',scope:'Saved HTML render, 38 rows, LV2/LV3 add forms, required fields, independent Plan/Actual dates, product rename, reload',errors}));
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
