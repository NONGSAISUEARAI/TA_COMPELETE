import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/outputs/01a0c35e-5086-7442-abfc-18d7347eb1aa/MTO_MRT_PL-2065V_LOT2_header_cleaned.xlsx";
const outputDir = "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/outputs/01a0c35e-5086-7442-abfc-18d7347eb1aa";
const outputPath = `${outputDir}/MTO_MRT_PL-2065V_LOT2_sortable.xlsx`;

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
const source = workbook.worksheets.getItem("PL-2065V_New (2)");
const target = workbook.worksheets.add("Sortable Data");

target.getRange("B1:AH5").copyFrom(source.getRange("B1:AH5"), "all");

const sourceValues = source.getRange("B6:AH2393").values;
const sourceRows = [];
for (let i = 0; i < sourceValues.length; i += 1) {
  const row = sourceValues[i] ?? [];
  if (row.some((value) => value !== null && value !== "")) {
    sourceRows.push({ sourceRow: i + 6, values: [...row] });
  }
}

let currentType = null;
for (const row of sourceRows) {
  if (row.values[0] !== null && row.values[0] !== "") currentType = row.values[0];
  else row.values[0] = currentType;
}

for (let block = 0; block < 92; block += 1) {
  const sourceStart = 6 + block * 26;
  const sourceEnd = sourceStart + 19;
  const targetStart = 6 + block * 20;
  const targetEnd = targetStart + 19;
  target.getRange(`B${targetStart}:AH${targetEnd}`).copyFrom(source.getRange(`B${sourceStart}:AH${sourceEnd}`), "all");
}

target.getRange(`B6:AH${5 + sourceRows.length}`).values = sourceRows.map((row) => row.values);
target.freezePanes.freezeRows(5);
target.getRange(`B1:AH${5 + sourceRows.length}`).format.verticalAlignment = "center";
target.getRange(`B6:B${5 + sourceRows.length}`).format.horizontalAlignment = "center";
target.getRange("B:B").format.columnWidth = 12;
target.getRange("C:C").format.columnWidth = 15;
target.getRange("D:D").format.columnWidth = 36;

workbook.recalculate();

const verification = await workbook.inspect({
  kind: "table",
  sheetId: "Sortable Data",
  range: `B1:AH${5 + sourceRows.length}`,
  include: "values,formulas",
  tableMaxRows: 12,
  tableMaxCols: 33,
  maxChars: 9000,
});
console.log(verification.ndjson);

const missingTypes = sourceRows.filter((row) => row.values[0] === null || row.values[0] === "").length;
const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",
  sheetId: "Sortable Data",
  options: { useRegex: true, maxResults: 300 },
  summary: "formula error scan on sortable sheet",
});
console.log(JSON.stringify({ dataRows: sourceRows.length, missingTypes, lastRow: 5 + sourceRows.length }));
console.log(errors.ndjson);

const preview = await workbook.render({
  sheetName: "Sortable Data",
  range: "B1:AH30",
  scale: 1,
  format: "png",
});
await fs.mkdir(outputDir, { recursive: true });
await fs.writeFile(`${outputDir}/sortable_data_preview.png`, new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(outputPath);
