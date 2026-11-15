const fs=require('fs'),path=require('path'),assert=require('assert/strict'),{pathToFileURL}=require('url'),{chromium}=require('playwright');
(async()=>{
 const source=path.resolve('Master_Schedule.html'),original=fs.readFileSync(source),browser=await chromium.launch({channel:'msedge',headless:true});
 try{
  const page=await browser.newPage({viewport:{width:1600,height:1000}}),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto(pathToFileURL(source).href);await page.locator('#tasks tr').first().waitFor();
  const before=await page.evaluate(()=>JSON.stringify(state));
  await page.locator('#calendar-from').fill('2026-11-01');await page.locator('#calendar-to').fill('2026-11-30');await page.locator('#calendar-apply').click();assert.equal(await page.locator('#weeks .week').count(),6);assert.match(await page.locator('#calendar-range-note').innerText(),/ช่วงที่เลือก/);assert.equal(await page.evaluate(()=>JSON.stringify(state)),before);
  await page.locator('#calendar-to').fill('2026-10-01');await page.locator('#calendar-apply').click();assert.match(await page.locator('#calendar-range-note').innerText(),/ต้องไม่อยู่ก่อน/);assert.equal(await page.locator('#weeks .week').count(),6);await page.locator('#calendar-to').fill('2026-11-30');await page.locator('#calendar-apply').click();
  fs.mkdirSync('outputs/editor-range',{recursive:true});await page.locator('#table-section').scrollIntoViewIfNeeded();await page.screenshot({path:'outputs/editor-range/calendar-range.png'});
  await page.locator('#unlock-editor').click();await page.locator('#unlock-password').fill('123123');await page.locator('#unlock-form button[type="submit"]').click();
  const id=await page.evaluate(()=>state.tasks.find(t=>databaseLevel(t)===3&&t.name==='ELEVATION PANEL KEY')?.id||leafTasks()[0].id);
  await page.evaluate(id=>openTask(id),id);await page.locator('#task-dialog').waitFor({state:'visible'});
  const cols=()=>page.locator('#task-dialog .form-body').evaluate(e=>getComputedStyle(e).gridTemplateColumns.split(' ').length);
  assert.equal(await cols(),3);
  assert.equal(await page.locator('#f-name').isVisible(),true);assert.equal(await page.locator('#f-start').isVisible(),true);assert.equal(await page.locator('#f-currentInfo').isVisible(),true);
  const check=async()=>{const r=await page.locator('#task-dialog').evaluate(dialog=>{const body=dialog.querySelector('.form-body'),b=dialog.getBoundingClientRect(),f=dialog.querySelector('.dialog-footer').getBoundingClientRect();return{dialogWidth:b.width,viewport:innerWidth,horizontalOverflow:body.scrollWidth>body.clientWidth+2,footerVisible:f.bottom<=innerHeight,duplicateIds:[...dialog.querySelectorAll('[id]')].map(n=>n.id).filter((id,i,a)=>a.indexOf(id)!==i)}});assert.equal(r.horizontalOverflow,false);assert.equal(r.footerVisible,true);assert.deepEqual(r.duplicateIds,[]);return r};
  await check();await page.screenshot({path:'outputs/editor-range/editor-desktop.png'});
  await page.setViewportSize({width:1024,height:768});assert.equal(await cols(),2);await check();await page.screenshot({path:'outputs/editor-range/editor-ipad.png'});
  await page.setViewportSize({width:390,height:844});assert.equal(await cols(),1);await check();await page.screenshot({path:'outputs/editor-range/editor-phone.png'});
  await page.setViewportSize({width:1600,height:1000});const old=await page.locator('#f-owner').inputValue();await page.locator('#f-owner').fill('Layout QA');await page.locator('#task-form button[type="submit"]').click();assert.equal(await page.locator('#task-dialog').isVisible(),false);assert.equal(await page.evaluate(id=>state.tasks.find(t=>t.id===id).owner,id),'Layout QA');
  await page.evaluate(()=>openGroup(state.groups[0].id));await page.locator('#group-dialog').waitFor({state:'visible'});assert.equal(await page.locator('#group-dialog .form-body').evaluate(e=>getComputedStyle(e).gridTemplateColumns.split(' ').length),3);await page.screenshot({path:'outputs/editor-range/editor-group.png'});await page.locator('#group-dialog [data-close="group-dialog"]').first().click();
  assert.deepEqual(errors,[]);assert.deepEqual(fs.readFileSync(source),original);console.log(JSON.stringify({result:'PASS',scope:'Viewer date window, invalid range, 3/2/1 columns, no horizontal overflow, footer visibility, preserved input IDs and save behavior, group editor, original unchanged',errors}));
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
