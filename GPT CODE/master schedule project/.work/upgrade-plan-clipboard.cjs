const fs=require('node:fs'),assert=require('node:assert/strict');
const file='Master_Schedule.html',before=fs.readFileSync(file,'utf8'),start=before.indexOf('// Plan templates stay in this page;'),end=before.indexOf('\nrender();saveStatus();\n</script>',start);
assert(start>0&&end>start);let after=before.slice(0,start)+fs.readFileSync('.work/plan-clipboard.js','utf8').trimEnd()+before.slice(end);
const anchor="if(editingId&&(taskChildren(editingId).length||state.tasks.find(t=>t.id===editingId).nodeType==='section')){const summary=summarizeTask";
assert.equal(after.split(anchor).length,2);
after=after.replace(anchor,"if(!pendingPlanPaste&&editingId&&(taskChildren(editingId).length||state.tasks.find(t=>t.id===editingId).nodeType==='section')){const summary=summarizeTask");
// Product form preparation normally preserves its existing rollup. A paste instead uses the copied form value.
const prepare="prepareDatabaseTaskValues(values)}catch(error){$('task-error').textContent=error.message;return}if(!values.name";
assert.equal(after.split(prepare).length,2);
after=after.replace(prepare,"prepareDatabaseTaskValues(values);if(pendingPlanPaste)values.progress=$('f-progress').value.trim()===''?null:Number($('f-progress').value)}catch(error){$('task-error').textContent=error.message;return}if(!values.name");
after=after.replace('title="คัดลอกแผนและงานย่อยจากหน้าต่างนี้"','title="คัดลอกข้อมูลทุกช่องและงานย่อย รวม Plan, Actual และไฟล์อ้างอิง"');
const data=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/;assert.equal(after.match(data)[1],before.match(data)[1]);
fs.writeFileSync('backups/Master_Schedule_before_full_copy_'+Date.now()+'.html',before);fs.writeFileSync(file,after);console.log('Upgraded full task copy; saved schedule records unchanged.');
