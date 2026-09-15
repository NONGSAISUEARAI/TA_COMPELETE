import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "../../outputs/pp17_pp20_c03/Material_Quantity_C03_PP17-PP20.xlsx";
const previewDir = "./pre_edit_previews";
await fs.mkdir(previewDir, { recursive: true });

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const summary = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 7000,
  tableMaxRows: 18,
  tableMaxCols: 6,
});
console.log(summary.ndjson);

const formulas = await workbook.inspect({
  kind: "formula",
  sheetId: "PP17",
  range: "A1:G20",
  maxChars: 4000,
  options: { maxResults: 50 },
});
console.log(formulas.ndjson);

for (const station of ["PP17", "PP18", "PP19", "PP20"]) {
  const preview = await workbook.render({
    sheetName: station,
    range: "A1:G16",
    scale: 1.2,
    format: "png",
  });
  await fs.writeFile(`${previewDir}/${station}.png`, new Uint8Array(await preview.arrayBuffer()));
}
