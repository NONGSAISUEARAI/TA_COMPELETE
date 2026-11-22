import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const data=JSON.parse(await fs.readFile(new URL('./source.json',import.meta.url),'utf8'));
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(data.sourcePath));
const sh=wb.worksheets.getItem('SOOM2609011 bak');
console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:1500})).ndjson);
const before=await wb.render({sheetName:sh.name,range:'A1:E9',scale:1.5,format:'png'});
await fs.writeFile(new URL('./before.png',import.meta.url),new Uint8Array(await before.arrayBuffer()));
const additions={
 PP17ENT1:[[3050,2,'K2'],[3550,44,'K3']],
 PP17ENT2:[[3050,3,'L2'],[3550,72,'L3']],
 PP18ENT2:[[3750,5,'N4'],[4050,7,'N5'],[4250,4,'N6']],
 PP18ENT3:[[3750,22,'O4'],[4550,38,'O7'],[4750,26,'O8']],
 PP18ENT4:[[3550,4,'P3'],[4050,10,'P5'],[4550,40,'P7'],[4750,4,'P8']],
 IV01:[[3750,6,'J4'],[4750,58,'J8']], VS01:[[3050,24,'T2']]
};
const groups=data.rows.flatMap((row,i)=>row[0]?[{name:row[0],start:i+1}]:[]);
const plan=[]; let shift=0;
for(let i=0;i<groups.length;i++){
 const g=groups[i];const end=(groups[i+1]?.start??97)-1;
 const last=data.rows.slice(g.start-1,end).reduce((a,r,j)=>r.slice(1).some(v=>v!==null&&(typeof v!=='string'||v.trim()!==''))?g.start+j:a,g.start);
 const extra=additions[g.name]??[];
 const needed=Math.max(0,last+extra.length+1-end);
 plan.push({...g,end,last,newStart:g.start+shift,shift,extra,needed});shift+=needed;
}
// Move only the A:E blocks, working from the bottom to preserve source cells.
for(const g of [...plan].reverse()){
 if(g.shift)sh.getRange(`A${g.newStart}:E${g.end+g.shift}`).copyFrom(sh.getRange(`A${g.start}:E${g.end}`),'all');
}
// Restore source values exactly and put the new entries after each station's accessories.
const entries=[];
for(const g of plan){
 const end=g.end+g.shift+g.needed;
 sh.getRange(`A${g.newStart}:E${end}`).clear({applyTo:'contents'});
 const original=data.rows.slice(g.start-1,g.end);
 sh.getRange(`A${g.newStart}:E${g.end+g.shift}`).values=original;
 for(let i=0;i<g.extra.length;i++){
  const [len,qty,ref]=g.extra[i],r=g.last+g.shift+i+1;
  sh.getRange(`A${r}:E${r}`).copyFrom(sh.getRange(`A${g.newStart+2}:E${g.newStart+2}`),'all');
  sh.getRange(`A${r}:E${r}`).values=[[null,'Alu.6.0mm.(thk) Angle 50x50mm. SCT-Die No.0756-1.554 Kg./m.\n392B5749-TH1_(PC) (S)',len,null,qty]];
  sh.getRange(`E${r}`).formulas=[[`=${ref}`]];
  sh.getRange(`B${r}`).format.wrapText=true;
  sh.getRange(`A${r}:E${r}`).format.rowHeight=62;
  sh.getRange(`C${r}`).setNumberFormat('0.00');
  sh.getRange(`E${r}`).setNumberFormat('#,##0');
  entries.push({station:g.name,row:r,length:len,qty,ref});
 }
}
wb.recalculate();
for(const e of entries){const actual=sh.getRange(`E${e.row}`).values[0][0];if(actual!==e.qty)throw Error(`Quantity mismatch ${JSON.stringify(e)}: ${actual}`);}
console.log(JSON.stringify({entries,total:entries.reduce((a,e)=>a+e.qty,0),rowsAdded:shift}));
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!',options:{useRegex:true,maxResults:10},maxChars:1200})).ndjson);
for(const g of plan.filter(x=>x.extra.length)){
 const p=await wb.render({sheetName:sh.name,range:`A${g.newStart}:E${g.last+g.shift+g.extra.length}`,scale:1.3,format:'png'});
 await fs.writeFile(new URL(`./${g.name}.png`,import.meta.url),new Uint8Array(await p.arrayBuffer()));
}
await fs.writeFile(new URL('./plan.json',import.meta.url),JSON.stringify({plan,entries}));
await (await SpreadsheetFile.exportXlsx(wb)).save('outputs/01a1e514/APSG ACESSORIES TO SOOM - station groups.xlsx');
