import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";
const path = "C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx";
const wb = await SpreadsheetFile.importXlsx(await FileBlob.load(path));
const sh = wb.worksheets.getItem("0042");
console.log((await wb.inspect({kind:"table", sheetId:"0042", range:"A1:AW141", include:"values,formulas", tableMaxRows:141, tableMaxCols:49, tableMaxCellChars:120, maxChars:18000})).ndjson);
console.log(wb.help("worksheet copy", {include:"index,examples,notes", maxChars:3500}).ndjson);
