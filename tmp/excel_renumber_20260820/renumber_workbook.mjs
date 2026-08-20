import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx";
const outputPath = "C:/TA/TA_COMPELETE/tmp/excel_renumber_20260820/IT3-M3-2026-0035_renumbered.xlsx";

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const changes = Array.from({ length: 21 }, (_, index) => {
  const oldNumber = String(46 + index).padStart(4, "0");
  const newNumber = String(49 + index).padStart(4, "0");
  return { oldNumber, newNumber };
});

for (const { oldNumber } of changes) {
  const sheet = workbook.worksheets.getItem(oldNumber);
  sheet.name = `__renumber_${oldNumber}`;
}

for (const { oldNumber, newNumber } of changes) {
  const sheet = workbook.worksheets.getItem(`__renumber_${oldNumber}`);
  sheet.name = newNumber;
  sheet.getRange("T1").values = [[`IT3-M3-2026-${newNumber}`]];
}

const check = await workbook.inspect({ kind: "sheet", include: "id,name", maxChars: 8000 });
console.log(check.ndjson);
for (const name of ["0049", "0050", "0069"]) {
  const sheet = workbook.worksheets.getItem(name);
  console.log(JSON.stringify({ sheet: name, t1: sheet.getRange("T1").values }));
}

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "formula error scan",
});
console.log(errors.ndjson);

const preview = await workbook.render({ sheetName: "0049", range: "A1:AW35", scale: 1, format: "png" });
await fs.writeFile("C:/TA/TA_COMPELETE/tmp/excel_renumber_20260820/preview_0049.png", new Uint8Array(await preview.arrayBuffer()));

const xlsx = await SpreadsheetFile.exportXlsx(workbook);
await xlsx.save(outputPath);
