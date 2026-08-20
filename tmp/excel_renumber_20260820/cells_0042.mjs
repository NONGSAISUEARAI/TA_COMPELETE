import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";
const path = "C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx";
const wb = await SpreadsheetFile.importXlsx(await FileBlob.load(path));
const sh = wb.worksheets.getItem("0042");
for (const cell of ["R9","T9","U9","V9","T28","U28","V28","W28"]) console.log(cell, JSON.stringify({value:sh.getRange(cell).values,formula:sh.getRange(cell).formulas}));
