import fs from 'node:fs/promises';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const path = 'C:/Users/tawan.t/Documents/ChatGPT/ใบทำราคา/outputs/rfq_preview_2pages_20261006/RFQ_HK_MEP_ตัวอย่าง_2หน้า_40รายการ.xlsx';
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(path));
const sheet = workbook.worksheets.getItemAt(0);
console.log((await workbook.inspect({ kind: 'sheet', include: 'id,name', maxChars: 1000 })).ndjson);
for (const [number, range] of [[1, 'A1:Z45'], [2, 'A90:Z134']]) {
  const preview = await workbook.render({ sheetName: sheet.name, range, scale: 1.5, format: 'png' });
  await fs.writeFile(`outputs/rfq_preview_2pages_20261006/page${number}.png`, new Uint8Array(await preview.arrayBuffer()));
  console.log(`rendered page${number}.png`);
}
