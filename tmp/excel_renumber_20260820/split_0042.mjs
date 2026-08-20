import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/TA/PPLINE CKST/C1-C2_Finishes-Reflected Ceiling Plan/Generic/Gen C10/MCK C10 PP17 PP19/IT3-M3-2026-0035_ใบขอตัวอย่างสินค้าสั่งทำพิเศษ MRT PPLINE MCK C10________TEST_______________ - Copy.xlsx";
const outputPath = "C:/TA/TA_COMPELETE/tmp/excel_renumber_20260820/IT3-M3-2026-0035_split_0042.xlsx";

const plans = [
  { sheetName: "0071", total: 4910, rows: [{ sourceRow: 9 }, { sourceRow: 12 }, { sourceRow: 13 }, { sourceRow: 14 }, { sourceRow: 15 }, { sourceRow: 16 }, { sourceRow: 17 }] },
  { sheetName: "0072", total: 3451.5, rows: [{ sourceRow: 11 }, { sourceRow: 18 }, { sourceRow: 19 }] },
  { sheetName: "0073", total: 4830, rows: [{ sourceRow: 10, quantity: 7 }] },
  { sheetName: "0074", total: 4830, rows: [{ sourceRow: 10, quantity: 7 }] },
];

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));
const source = workbook.worksheets.getItem("0042");

for (const plan of plans) {
  const target = workbook.worksheets.add(plan.sheetName);
  target.getRange("A1:AW203").copyFrom(source.getRange("A1:AW203"), "all");
  target.getRange("A9:AW22").clear({ applyTo: "contents" });

  for (const [index, item] of plan.rows.entries()) {
    const destRow = 9 + index;
    target.getRange(`A${destRow}:AW${destRow}`).copyFrom(source.getRange(`A${item.sourceRow}:AW${item.sourceRow}`), "all");
    if (item.quantity !== undefined) target.getRange(`R${destRow}`).values = [[item.quantity]];
  }

  target.getRange("T1").values = [[`IT3-M3-2026-${plan.sheetName}`]];
  target.getRange("V28").values = [[plan.total]];
  target.getRange("V28").format.numberFormat = '#,### "B"';
}

for (const plan of plans) {
  const sheet = workbook.worksheets.getItem(plan.sheetName);
  console.log(JSON.stringify({ sheet: plan.sheetName, t1: sheet.getRange("T1").values[0][0], total: sheet.getRange("V28").values[0][0] }));
}

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "formula error scan for 0042 split sheets",
});
console.log(errors.ndjson);

for (const name of ["0071", "0072", "0073", "0074"]) {
  const preview = await workbook.render({ sheetName: name, range: "A1:AW35", scale: 1, format: "png" });
  await fs.writeFile(`C:/TA/TA_COMPELETE/tmp/excel_renumber_20260820/preview_${name}.png`, new Uint8Array(await preview.arrayBuffer()));
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
