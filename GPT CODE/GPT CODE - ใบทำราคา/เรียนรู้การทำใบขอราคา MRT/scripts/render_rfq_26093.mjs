import fs from 'node:fs/promises';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const base = 'C:/Users/tawan.t/Documents/ChatGPT/ใบทำราคา/outputs/rfq_26093_20261007';
const workbook = await SpreadsheetFile.importXlsx(
  await FileBlob.load(`${base}/BU2-DE-26093 - MRT PURPLE LINE 4STATION (PP17 - PP20)_20261007-1325.xlsm`),
);
const preview = await workbook.render({ sheetName: '1', range: 'A1:Z45', scale: 1.5, format: 'png' });
await fs.writeFile(`${base}/preview.png`, new Uint8Array(await preview.arrayBuffer()));
console.log('rendered');
