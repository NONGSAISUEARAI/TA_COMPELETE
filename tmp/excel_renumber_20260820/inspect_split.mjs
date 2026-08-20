import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";
const path = "C:/TA/TA_COMPELETE/tmp/excel_renumber_20260820/IT3-M3-2026-0035_split_0042.xlsx";
const wb = await SpreadsheetFile.importXlsx(await FileBlob.load(path));
for (const name of ["0071","0072","0073"]) { const sh=wb.worksheets.getItem(name); console.log(name, JSON.stringify({values:sh.getRange("A9:V22").values, formulas:sh.getRange("A9:V22").formulas})); }
