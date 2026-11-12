const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

(async () => {
  const source = path.resolve('Master_Schedule.html');
  const output = path.resolve('Master_Schedule_iPad_Viewer.html');
  const original = fs.readFileSync(source, 'utf8');
  const data = JSON.parse(original.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1]);
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1024, height: 1366 } });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(pathToFileURL(source).href);
    await page.locator('#tasks tr').first().waitFor();
    await page.evaluate(() => {
      localStorage.clear();
      collapsedGroups.clear();
      document.getElementById('show-drawing-details').checked = true;
      drawingCoreHidden = false;
      render();
    });
    assert.deepEqual(errors, []);
    assert.equal(await page.locator('#tasks > tr').count(), data.groups.length + data.tasks.length);
    await page.evaluate(() => {
      // Capture the existing renderer's complete table, including all Plan/Actual
      // dates, file names and summary calculations. The result needs no script.
      document.querySelectorAll('script,dialog,.access-panel,.actions,.save-panel,.filters,.help,.restore,.project-link,.reorder-hint,#toast,.group-actions,.group-arrow,.group-toggle-all').forEach(el => el.remove());
      document.querySelector('#table-section > .toolbar p').textContent = 'แสดงงานทั้งหมด · เลื่อนซ้าย–ขวาเพื่อดูวันแผน วันทำจริง และกราฟ';
      document.querySelectorAll('button').forEach(button => {
        const label = document.createElement('span');
        label.className = button.className;
        label.innerHTML = button.innerHTML;
        button.replaceWith(label);
      });
      document.querySelectorAll('[role="button"]').forEach(el => {
        el.removeAttribute('role'); el.removeAttribute('tabindex');
      });
      const note = document.createElement('p');
      note.className = 'ipad-viewer-note';
      note.textContent = 'ฉบับดูข้อมูลสำหรับ iPad · แสดงข้อมูลที่บันทึกในไฟล์ต้นฉบับตอนสร้างสำเนานี้ · เลื่อนตารางซ้าย–ขวาเพื่อดูทุกคอลัมน์ · แก้ไขและค้นหาผ่านไฟล์ Master Schedule ต้นฉบับ';
      document.querySelector('main').prepend(note);
      const style = document.createElement('style');
      style.textContent = '.ipad-viewer-note{padding:14px 16px;background:#203c48;border:1px solid #486b79;border-radius:8px;line-height:1.7;color:#d6e9ed}.schedule-scroll{max-height:none;overflow:auto;-webkit-overflow-scrolling:touch}.col-edit{display:none!important}.group-toggle{cursor:default}.wbs-reorder{pointer-events:none}main{padding:16px}.top{padding:16px}.top-right{display:none}@media print{.ipad-viewer-note{color:#153331;background:white}}';
      document.head.append(style);
      document.title += ' · iPad Viewer';
    });
    fs.writeFileSync(output, '<!doctype html>\n' + await page.content());
    const offline = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 1024, height: 1366 } });
    const check = await offline.newPage();
    await check.goto(pathToFileURL(output).href);
    assert.equal(await check.locator('#tasks > tr').count(), data.groups.length + data.tasks.length);
    assert.equal(await check.locator('script').count(), 0);
    assert.equal(await check.locator('button').count(), 0);
    assert.match(await check.locator('#project-title').innerText(), /MRT/);
    fs.mkdirSync('outputs/ipad', { recursive: true });
    await check.screenshot({ path: 'outputs/ipad/Master_Schedule_iPad_Viewer.png' });
    assert.equal(fs.readFileSync(source, 'utf8'), original);
    console.log(JSON.stringify({ output, rows: data.groups.length + data.tasks.length, javascriptDisabled: 'PASS', originalUnchanged: true, errors }));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
