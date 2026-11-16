const fs=require('node:fs'),assert=require('node:assert/strict'),{boot}=require('./helpers/schedule-harness.cjs');
const html=fs.readFileSync('Master_Schedule.html','utf8'),block=(html.match(/<style id="timeline-no-vertical-lines">([\s\S]*?)<\/style>/)||[])[1];
assert(block,'timeline override exists');assert(block.includes('.week,.day-head{border-left:0!important;border-right:0!important}'));assert(block.includes('.today-line{display:none!important}'));
assert(!block.includes('1px,transparent'));assert.equal((block.match(/background-image:linear-gradient/g)||[]).length,2);
const app=boot(html),before=app.run('JSON.stringify(state)');app.run('render()');assert.equal(app.run('JSON.stringify(state)'),before);assert.equal(fs.readFileSync('Master_Schedule.html','utf8'),html);
console.log('PASS: HTML timeline hides every vertical guide while preserving weekend bands and render state.');
