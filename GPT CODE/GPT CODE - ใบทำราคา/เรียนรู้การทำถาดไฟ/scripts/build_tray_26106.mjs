import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const source='C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/PP-LINE_FL-PART/ALUMINIUM TRAY/BU2-DE-26060_โครงการ MRT PURPLE LINE 4 STATION (PP17 - PP20).xlsx';
const dir='outputs/rfq_26106'; await fs.mkdir(dir,{recursive:true});
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(source));
const sh=wb.worksheets.getItem('1');
const pre=await wb.render({sheetName:'1',range:'A1:Z45',scale:1.5,format:'png'}); await fs.writeFile(dir+'/before.png',new Uint8Array(await pre.arrayBuffer()));
const edits={Z1:'BU2-DE-26106',V3:4,W3:12,X3:69,C44:46346,H44:null,Z45:'1/1'};
for(let r=7;r<=22;r++) {let old=sh.getRange('B'+r).values[0][0]; const m=old.match(/^(.*?)\s*\((AL-TRAY.*)\)$/); if(!m)throw Error(old); edits['B'+r]=m[1].trim()+' / '+m[2];}
for(const [a,v] of Object.entries(edits))sh.getRange(a).values=[[v]];
wb.recalculate();
console.log((await wb.inspect({kind:'table',range:"'1'!W7:W22",maxChars:3000,tableMaxRows:16,tableMaxCols:1})).ndjson);
await fs.writeFile(dir+'/edits.json',JSON.stringify(edits));
await (await SpreadsheetFile.exportXlsx(wb)).save(dir+'/edited_cells.xlsx');
const post=await wb.render({sheetName:'1',range:'A1:Z45',scale:1.5,format:'png'}); await fs.writeFile(dir+'/after.png',new Uint8Array(await post.arrayBuffer()));
