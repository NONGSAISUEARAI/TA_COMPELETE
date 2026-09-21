import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/tawan.t/Downloads/MTO_MRT สายม่วงใต้ PL-2065V_V.20260916 LOT 2.xlsx";
const outputDir = "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/outputs/01a0c35e-5086-7442-abfc-18d7347eb1aa";
const outputPath = `${outputDir}/MTO_MRT_PL-2065V_LOT2_header_cleaned.xlsx`;

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
const sheet = workbook.worksheets.getItem("PL-2065V_New (2)");
const used = sheet.getUsedRange();
const values = used.values;
const duplicateHeaderRows = [];

for (let i = 0; i < values.length; i += 1) {
  const row = values[i] ?? [];
  const rowNumber = i + 1;
  if (rowNumber > 5 && row[1] === "Type" && row[2] === "Louver Type" && row[3] === "Description") {
    duplicateHeaderRows.push(rowNumber);
  }
}

for (const headerRow of duplicateHeaderRows) {
  sheet.getRange(`B${headerRow - 3}:AH${headerRow}`).clear({ applyTo: "contents" });
}

workbook.recalculate();

const remainingHeaders = await workbook.inspect({
  kind: "match",
  searchTerm: "^Type$",
  sheetId: "PL-2065V_New (2)",
  range: "B1:B2391",
  options: { useRegex: true, maxResults: 200 },
  summary: "remaining main header labels",
});
console.log(JSON.stringify({ duplicateHeaderCount: duplicateHeaderRows.length, first: duplicateHeaderRows[0], last: duplicateHeaderRows.at(-1) }));
console.log(remainingHeaders.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",
  sheetId: "PL-2065V_New (2)",
  options: { useRegex: true, maxResults: 300 },
  summary: "formula error scan after clearing duplicate headers",
});
console.log(errors.ndjson);

const preview = await workbook.render({
  sheetName: "PL-2065V_New (2)",
  range: "B1:AH34",
  scale: 1,
  format: "png",
});
await fs.mkdir(outputDir, { recursive: true });
await fs.writeFile(`${outputDir}/header_cleaned_preview.png`, new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(outputPath);
