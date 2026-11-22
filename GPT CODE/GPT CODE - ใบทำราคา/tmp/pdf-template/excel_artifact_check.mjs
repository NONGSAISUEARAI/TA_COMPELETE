import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const source='C:/TA/TA_COMPELETE/GPT CODE/GPT CODE - ใบทำราคา/ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx';
const dir='C:/TA/TA_COMPELETE/GPT CODE/GPT CODE - ใบทำราคา/tmp/pdf-template';
const args=process.argv.slice(2);
const input=args[0]||source;
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(input));
console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:1000})).ndjson);
console.log((await wb.inspect({kind:'table',range:"'1'!A7:M9",include:'values,formulas',maxChars:1800,tableMaxRows:3,tableMaxCols:13})).ndjson);
if(!args.length){
  console.log(wb.help('form controls',{search:'checkbox|control|VML',include:'index,notes',maxChars:1500}).ndjson);
  wb.recalculate();
  await (await SpreadsheetFile.exportXlsx(wb)).save(dir+'/excel-template-artifact-roundtrip.xlsx');
}
for(const sheet of args.length?['1','2']:['1']){
  const png=await wb.render({sheetName:sheet,range:'A1:Z45',scale:1.2,format:'png'});
  await fs.writeFile(dir+`/excel-${args.length?'export':'source'}-${sheet}.png`,new Uint8Array(await png.arrayBuffer()));
}
