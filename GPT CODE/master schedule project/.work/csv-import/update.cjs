const fs=require('node:fs'),assert=require('node:assert/strict'),vm=require('node:vm');
const p='Master_Schedule.html',before=fs.readFileSync(p,'utf8'),pattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/,raw=before.match(pattern)[1];JSON.parse(raw);
const code='const CSV_VBA_TEXT='+JSON.stringify(fs.readFileSync('Export_MasterSchedule_CSV.bas','utf8')).replace(/</g,'\\u003c')+';\n'+fs.readFileSync('.work/csv-import/feature.js','utf8')+'\n';
const next=before.replace(/const CSV_VBA_TEXT=[^\n]*;\n[\s\S]*?(?=function snapshot\(\))/,code);assert.equal(next.match(pattern)[1],raw);for(const m of next.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g))if(!m[1].includes('application/json'))new vm.Script(m[2]);fs.writeFileSync(p,next);
