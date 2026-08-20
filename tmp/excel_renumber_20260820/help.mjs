import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";
const input = await FileBlob.load("C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx");
const wb = await SpreadsheetFile.importXlsx(input);
console.log(wb.help("worksheet name", { include: "index,examples,notes", maxChars: 3000 }).ndjson);
