const fs=require('fs'),assert=require('assert/strict');let html=fs.readFileSync('Master_Schedule.html','utf8');assert(!html.includes('function datePastePlan('));const data=html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1];
const marker=html.lastIndexOf('render();saveStatus();');html=html.slice(0,marker)+fs.readFileSync('.work/date-clipboard.js','utf8')+'\n'+html.slice(marker);
html=html.replace("$('batch-date-error').textContent='';refreshBatchDateUI();", "$('batch-date-error').textContent='';refreshBatchDateUI();cell.focus({preventScroll:true});");
html=html.replace('Shift+คลิก Start/End เพื่อแก้วันที่หลายรายการ', 'Ctrl+C / Ctrl+V คัดลอก–วางวันที่ · Shift+คลิก Start/End เพื่อแก้วันที่หลายรายการ');
html=html.replace('วันอาทิตย์จะเลื่อนไปวันจันทร์ · เปลี่ยนเฉพาะ Plan หรือ Actual ของรายการที่เลือก','Ctrl+C / Ctrl+V คัดลอก–วางวันที่ · รองรับ 2 คอลัมน์ Start / End จาก Excel · วันอาทิตย์เลื่อนไปวันจันทร์');
assert.equal(html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1],data);fs.writeFileSync('Master_Schedule.html',html);console.log('Added native date copy/paste events, TSV Start/End, selection and date validation. Data unchanged.');
