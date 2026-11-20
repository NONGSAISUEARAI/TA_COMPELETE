import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const input = process.argv[2];
if (!input) throw new Error('Pass the RFQ XLSM path');
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(input));
const preview = await workbook.render({ sheetName: '1', range: 'A1:Z45', scale: 1.5, format: 'png' });
const output = path.join(path.dirname(input), 'preview_26094.png');
await fs.writeFile(output, new Uint8Array(await preview.arrayBuffer()));
console.log(output);
