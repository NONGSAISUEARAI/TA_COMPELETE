import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const inputPath = process.argv[2];
if (!inputPath) throw new Error('Usage: node render_rfq_26092_rev01.mjs <xlsm>');

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
const outputDir = path.dirname(inputPath);
for (let page = 1; page <= 9; page += 1) {
  const preview = await workbook.render({
    sheetName: String(page),
    range: 'A1:Z45',
    scale: 1.5,
    format: 'png',
  });
  const outputPath = path.join(outputDir, `rev01_page_${page}.png`);
  await fs.writeFile(outputPath, new Uint8Array(await preview.arrayBuffer()));
  console.log(`RENDERED=${outputPath}`);
}
