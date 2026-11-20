import fs from 'node:fs/promises';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const base = 'C:/Users/tawan.t/Documents/ChatGPT/ใบทำราคา/outputs/rfq_native_controls_20261006';
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(`${base}/BU2-DE-26092 - MRT PURPLE LINE 4 STATION ABOVE GROUND_20261006-1621.xlsm`));
for (let number = 1; number <= 10; number++) {
  const preview = await workbook.render({ sheetName: String(number), range: 'A1:Z45', scale: 1.5, format: 'png' });
  await fs.writeFile(`${base}/sheet_${number}.png`, new Uint8Array(await preview.arrayBuffer()));
  console.log(`rendered sheet ${number}`);
}
