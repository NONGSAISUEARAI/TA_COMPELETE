import fs from 'node:fs/promises';
import path from 'node:path';
import { SpreadsheetFile, Workbook } from '@oai/artifact-tool';

const outputDir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/(?=[A-Za-z]:)/, ''));
const sourcePath = 'C:\\Users\\tawan.t\\Documents\\GitHub\\TA_COMPELETE\\300HK_matched_187_with_gaps.tsv';
const outputPath = path.join(outputDir, '300HK_matched_AB.xlsx');
const previewPath = path.join(outputDir, '300HK_matched_AB_preview.png');

const rows = (await fs.readFile(sourcePath, 'utf8')).replace(/^\uFEFF/, '').trimEnd().split(/\r?\n/).map(line => line.split('\t'));
if (rows.length !== 188 || rows.some(row => row.length !== 3)) throw new Error('Unexpected TSV shape');
const matrix = rows.map(row => [row[1], row[2]]);
if (matrix.filter((row, index) => index > 0 && row[0] === '-').length !== 17) throw new Error('Expected 17 unmatched entries');

const workbook = Workbook.create();
const sheet = workbook.worksheets.add('Matched data');
sheet.showGridLines = false;
sheet.getRange('A1:B188').values = matrix;
sheet.getRange('A1:B188').format.font = { name: 'Arial', size: 10, color: '#1F2937' };
sheet.getRange('A1:B188').format.verticalAlignment = 'center';
sheet.getRange('A1:B1').format = {
  fill: '#1F2937',
  font: { name: 'Arial', size: 10, bold: true, color: '#FFFFFF' },
  verticalAlignment: 'center',
  rowHeight: 27,
};
sheet.getRange('A1:A188').format.columnWidth = 91;
sheet.getRange('B1:B188').format.columnWidth = 91;
sheet.getRange('A2:B188').format.rowHeight = 21;
sheet.getRange('A2:B188').setNumberFormat('@');
sheet.freezePanes.freezeRows(1);

for (let index = 1; index < matrix.length; index++) {
  if (matrix[index][0] === '-') {
    const cell = sheet.getRange(`A${index + 1}`);
    cell.format.fill = '#FEF3C7';
    cell.format.font = { name: 'Arial', size: 10, bold: true, color: '#92400E' };
  }
}

workbook.recalculate();
const first = await workbook.inspect({ kind: 'table', range: 'Matched data!A1:B5', include: 'values', tableMaxRows: 5, tableMaxCols: 2, maxChars: 2500 });
const last = await workbook.inspect({ kind: 'table', range: 'Matched data!A184:B188', include: 'values', tableMaxRows: 5, tableMaxCols: 2, maxChars: 2500 });
console.log('FIRST', first.ndjson);
console.log('LAST', last.ndjson);

const preview = await workbook.render({ sheetName: 'Matched data', range: 'A1:B15', scale: 1.3, format: 'png' });
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log('OUTPUT', outputPath);
