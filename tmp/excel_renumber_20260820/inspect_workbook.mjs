import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx";
const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const sheets = await workbook.inspect({ kind: "sheet", include: "id,name", maxChars: 12000 });
console.log(sheets.ndjson);
for (const name of Array.from({ length: 21 }, (_, i) => String(46 + i).padStart(4, "0"))) {
  try {
    const sheet = workbook.worksheets.getItem(name);
    console.log(JSON.stringify({ sheet: name, t1: sheet.getRange("T1").values, used: sheet.getUsedRange().address }));
  } catch { }
}
