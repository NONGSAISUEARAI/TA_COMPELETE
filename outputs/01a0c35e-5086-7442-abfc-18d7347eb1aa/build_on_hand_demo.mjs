import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const dir = path.dirname(fileURLToPath(import.meta.url));
const inputPath = 'C:\\Users\\tawan.t\\Downloads\\Item_Category_FG_Full_Spill_Example.xlsx';
const outputPath = path.join(dir, 'Item_Category_FG_On_Hand_Example.xlsx');
const beforePath = path.join(dir, 'On_Hand_before.png');
const afterPath = path.join(dir, 'On_Hand_after.png');

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
const sheet = workbook.worksheets.getItem('Total On Hand');

const before = await workbook.render({ sheetName: 'Total On Hand', range: 'A1:H6', scale: 1.5, format: 'png' });
await fs.writeFile(beforePath, new Uint8Array(await before.arrayBuffer()));

sheet.getRange('A1').values = [['Category prefix']];
sheet.getRange('A2').values = [['FG30503']];
sheet.getRange('D1').values = [['Matching item numbers →']];
sheet.getRange('D2').formulas = [[
  '=IF($A2="","",IFERROR(TRANSPOSE(SORT(UNIQUE(FILTER($C$2:$C$3506,(LEFT($C$2:$C$3506,LEN($A2))=$A2)*($C$2:$C$3506<>""))))),""))',
]];
sheet.getRange('A1:A2').format.columnWidth = 19;
sheet.getRange('D1:E2').format.columnWidth = 23;

workbook.recalculate();
for (const range of ['A1:E3', 'C1025:C1030']) {
  const check = await workbook.inspect({ kind: 'table', range: `Total On Hand!${range}`, include: 'values,formulas', tableMaxRows: 6, tableMaxCols: 5, maxChars: 3000 });
  console.log(range, check.ndjson);
}
const after = await workbook.render({ sheetName: 'Total On Hand', range: 'A1:H6', scale: 1.5, format: 'png' });
await fs.writeFile(afterPath, new Uint8Array(await after.arrayBuffer()));

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log('OUTPUT', outputPath);
