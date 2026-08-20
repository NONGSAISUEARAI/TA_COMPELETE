import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";
const path = "C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx";
const wb = await SpreadsheetFile.importXlsx(await FileBlob.load(path));
const sh = wb.worksheets.getItem("0042");
for (const range of ["A1:AW35", "A36:AW80", "A81:AW141", "A142:AW203"]) {
 console.log(JSON.stringify({range, values: sh.getRange(range).values, formulas: sh.getRange(range).formulas}));
}
