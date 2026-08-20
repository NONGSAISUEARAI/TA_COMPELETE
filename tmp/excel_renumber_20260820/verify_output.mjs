import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const outputPath = "C:/TA/TA_COMPELETE/tmp/excel_renumber_20260820/IT3-M3-2026-0035_renumbered.xlsx";
const input = await FileBlob.load(outputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
for (const expected of Array.from({ length: 21 }, (_, i) => String(49 + i).padStart(4, "0"))) {
  const sheet = workbook.worksheets.getItem(expected);
  const t1 = sheet.getRange("T1").values[0][0];
  if (t1 !== `IT3-M3-2026-${expected}`) throw new Error(`${expected}: expected T1, got ${t1}`);
}
for (const oldName of ["0046", "0047", "0048"]) {
  try {
    workbook.worksheets.getItem(oldName);
    throw new Error(`Old sheet ${oldName} still exists`);
  } catch (error) {
    if (String(error.message).includes("still exists")) throw error;
  }
}
console.log("Verified sheets 0049-0069 and their T1 values.");
