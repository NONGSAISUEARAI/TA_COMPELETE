const fs=require('node:fs'),assert=require('node:assert/strict'),{boot}=require('./helpers/schedule-harness.cjs');
const html=fs.readFileSync('Master_Schedule.html','utf8'),app=boot(html),before=app.run('JSON.stringify(state)');
function unzip(buffer){const bytes=Buffer.from(buffer),files={};let offset=0;while(bytes.readUInt32LE(offset)===0x04034b50){const size=bytes.readUInt32LE(offset+18),nameLength=bytes.readUInt16LE(offset+26),extraLength=bytes.readUInt16LE(offset+28),start=offset+30+nameLength+extraLength;files[bytes.toString('utf8',offset+30,offset+30+nameLength)]=bytes.toString('utf8',start,start+size);offset=start+size}return files}
const output=app.run('buildExcelWorkbook({calendar:true,start:"2026-11-01",end:"2026-11-30"})'),files=unzip(output.bytes),sheet=files['xl/worksheets/sheet1.xml'],styles=files['xl/styles.xml'],lastRow=output.recordCount*2+4;
assert.equal((sheet.match(/<conditionalFormatting /g)||[]).length,4);
assert(sheet.includes('<conditionalFormatting sqref="Y3:BB4"><cfRule type="expression" dxfId="0" priority="1"><formula>Y$3=TODAY()</formula>'));
assert.equal((sheet.match(new RegExp('conditionalFormatting sqref="Y5:BB'+lastRow+'"','g'))||[]).length,3);assert(sheet.includes('$S5=&quot;Plan&quot;'));assert(sheet.includes('$S5=&quot;Actual&quot;'));assert(sheet.includes('ROUNDDOWN(($N5-$M5+1)*$BC5,0)'));
assert(!sheet.includes('WEEKDAY(Y$3,2)&lt;&gt;7'));assert(styles.includes('FFC00000'));assert(styles.includes('FFC7E2DD'));assert(styles.includes('FF73B7A9'));assert(styles.includes('FFB9DBD4'));assert(styles.includes('FFFFFFFF'));
assert(sheet.includes('Plan สีอ่อน / Actual สีเต็ม / หัวแดง วันนี้'));
const xfs=(styles.match(/<cellXfs\b[^>]*>([\s\S]*?)<\/cellXfs>/)||[])[1].match(/<xf\b[^>]*\/>|<xf\b[^>]*>[\s\S]*?<\/xf>/g),borders=(styles.match(/<borders\b[^>]*>([\s\S]*?)<\/borders>/)||[])[1].match(/<border\b[^>]*\/>|<border\b[^>]*>[\s\S]*?<\/border>/g);
for(const ref of ['Y3','Y4','Y5']){const style=Number((sheet.match(new RegExp('<c r="'+ref+'" s="(\\d+)"'))||[])[1]),borderId=Number((xfs[style].match(/borderId="(\d+)"/)||[])[1]),border=borders[borderId];assert(!/<left\b[^>]*style=/.test(border),ref+' has no left vertical border');assert(!/<right\b[^>]*style=/.test(border),ref+' has no right vertical border')}
for(const border of borders){assert(!/<left\b[^>]*style=/.test(border),'all exported styles remove left borders');assert(!/<right\b[^>]*style=/.test(border),'all exported styles remove right borders')}
assert(sheet.includes('<col min="55" max="55" width="2" customWidth="1" hidden="1"/>'));assert(sheet.includes('_xlfn.NETWORKDAYS.INTL'));assert.equal(app.run('JSON.stringify(state)'),before);
const noCalendar=unzip(app.run('buildExcelWorkbook({calendar:false}).bytes'))['xl/worksheets/sheet1.xml'];
assert.equal((noCalendar.match(/<conditionalFormatting /g)||[]).length,0);assert(!noCalendar.includes('TODAY()'));assert(!noCalendar.includes('WEEKDAY(Y$3,2)=1'));
assert.equal(fs.readFileSync('Master_Schedule.html','utf8'),html);
console.log('PASS: Excel Gantt colors Sundays, overlays progress across Actual days, preserves Sunday-excluding workday formulas and removes every vertical border.');
