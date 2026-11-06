import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "outputs/01a1b038-cf6c-7d81-8845-ef2d0af26296";
const outputPath = `${outputDir}/Misc_Material_Takeoff_by_Station_and_RAL_v2.xlsx`;
const previewPath = `${outputDir}/Misc_Material_Takeoff_preview.png`;

const areas = [
  ["PP17", "ENT1", 656, 364], ["PP17", "ENT2", 444, 239],
  ["PP18", "ENT1", 10, 3], ["PP18", "ENT2", 324, 175],
  ["PP18", "ENT3", 560, 329], ["PP18", "ENT4", 338, 676],
  ["PP19", "ENT1", 216, 432], ["PP19", "ENT2", 150, 300],
  ["PP19", "ENT3", 452, 904], ["IV01", "-", 256, 512],
  ["VS01", "-", 102, 204],
];
const materials = [
  ["ALU.BK-HK-R-01", 50, 0, "pc."],
  ["ALU.BK-HK-L-01", 50, 0, "pc."],
  ["ALU-BK-EQ-L50x50-(L=50 mm.)", 50, 1, "pc."],
  ["HEX BOLT M8 (set)", null, 1, "set"],
  ["HEX BOLT M8 for ST (set)", null, 1, "set"],
];

const wb = Workbook.create();
const summary = wb.worksheets.add("Summary");
const detail = wb.worksheets.add("Detail");
summary.showGridLines = false;
detail.showGridLines = false;
summary.tabColor = "#1F4E78";
detail.tabColor = "#9DC3E6";

// Detail: source data split into PP and ENT columns.
detail.getRange("A1:H1").merge();
detail.getRange("A1").values = [["Miscellaneous material takeoff"]];
detail.getRange("A3:H3").values = [["PP", "ENT", "Area", "Material", "L (mm)", "Quantity", "Unit", "Total length (m)"]];
const detailRows = [];
for (const [pp, ent, hookQty, eqQty] of areas) {
  const areaName = ent === "-" ? pp : `${pp}${ent}`;
  for (const [name, len, qtyType, unit] of materials) {
    detailRows.push([pp, ent, areaName, name, len, qtyType === 0 ? hookQty : eqQty, unit, null]);
  }
}
detail.getRange(`A4:H${3 + detailRows.length}`).values = detailRows;
detail.getRange("H4").formulas = [["=IF(E4=\"\",\"\",E4*F4/1000)"]];
detail.getRange(`H4:H${3 + detailRows.length}`).fillDown();

// Summary: horizontal stations ordered IV, PP, VS, without total columns.
summary.getRange("A1:M1").merge();
summary.getRange("A1").values = [["Miscellaneous material summary by station"]];
const stationDefs = [
  ["IV01", "-"], ["PP17", "ENT1"], ["PP17", "ENT2"],
  ["PP18", "ENT1"], ["PP18", "ENT2"], ["PP18", "ENT3"], ["PP18", "ENT4"],
  ["PP19", "ENT1"], ["PP19", "ENT2"], ["PP19", "ENT3"], ["VS01", "-"],
];

// ALU brackets are separated by paint color: PP19 is RAL-1001; all others are RAL-7045.
summary.getRange("A3:M3").merge(); summary.getRange("A3").values = [["ALU bracket quantities by paint color"]];
summary.getRange("A4:A5").merge(); summary.getRange("A4").values = [["Material"]];
summary.getRange("B4:B5").merge(); summary.getRange("B4").values = [["Color"]];
summary.getRange("C4:C5").merge(); summary.getRange("C4").values = [["IV01"]];
summary.getRange("D4:E4").merge(); summary.getRange("D4").values = [["PP17"]];
summary.getRange("F4:I4").merge(); summary.getRange("F4").values = [["PP18"]];
summary.getRange("J4:L4").merge(); summary.getRange("J4").values = [["PP19"]];
summary.getRange("M4:M5").merge(); summary.getRange("M4").values = [["VS01"]];
summary.getRange("D5:L5").values = [["ENT1", "ENT2", "ENT1", "ENT2", "ENT3", "ENT4", "ENT1", "ENT2", "ENT3"]];
const paintRows = [
  ["ALU.BK-HK-R-01", "RAL-7045"], ["ALU.BK-HK-R-01", "RAL-1001"],
  ["ALU.BK-HK-L-01", "RAL-7045"], ["ALU.BK-HK-L-01", "RAL-1001"],
  ["ALU-BK-EQ-L50x50-(L=50 mm.)", "RAL-7045"], ["ALU-BK-EQ-L50x50-(L=50 mm.)", "RAL-1001"],
];
summary.getRange("A6:B11").values = paintRows;
for (let i = 0; i < paintRows.length; i++) {
  const row = 6 + i;
  const [material, color] = paintRows[i];
  const formulas = stationDefs.map(([pp, ent]) => {
    const stationColor = pp === "PP19" ? "RAL-1001" : "RAL-7045";
    if (color !== stationColor) return "=\"\"";
    return `=SUMIFS(Detail!$F$4:$F$58,Detail!$A$4:$A$58,"${pp}",Detail!$B$4:$B$58,"${ent}",Detail!$D$4:$D$58,"${material}")`;
  });
  summary.getRange(`C${row}:M${row}`).formulas = [formulas];
}

summary.getRange("A14:M14").merge(); summary.getRange("A14").values = [["Other miscellaneous materials"]];
summary.getRange("A15:A16").merge(); summary.getRange("A15").values = [["Material"]];
summary.getRange("B15:B16").merge(); summary.getRange("B15").values = [["Unit"]];
summary.getRange("C15:C16").merge(); summary.getRange("C15").values = [["IV01"]];
summary.getRange("D15:E15").merge(); summary.getRange("D15").values = [["PP17"]];
summary.getRange("F15:I15").merge(); summary.getRange("F15").values = [["PP18"]];
summary.getRange("J15:L15").merge(); summary.getRange("J15").values = [["PP19"]];
summary.getRange("M15:M16").merge(); summary.getRange("M15").values = [["VS01"]];
summary.getRange("D16:L16").values = [["ENT1", "ENT2", "ENT1", "ENT2", "ENT3", "ENT4", "ENT1", "ENT2", "ENT3"]];
const otherMaterials = materials.slice(3);
summary.getRange("A17:B18").values = otherMaterials.map(m => [m[0], m[3]]);
for (let i = 0; i < otherMaterials.length; i++) {
  const row = 17 + i;
  const material = otherMaterials[i][0].replaceAll('"', '""');
  const formulas = stationDefs.map(([pp, ent]) => `=SUMIFS(Detail!$F$4:$F$58,Detail!$A$4:$A$58,"${pp}",Detail!$B$4:$B$58,"${ent}",Detail!$D$4:$D$58,"${material}")`);
  summary.getRange(`C${row}:M${row}`).formulas = [formulas];
}

const font = "Arial";
for (const sheet of [summary, detail]) {
  const used = sheet.getUsedRange();
  used.format.font = { name: font, size: 10, color: "#222222" };
  used.format.verticalAlignment = "center";
}
for (const [sheet, titleRange, headerRange] of [[summary, "A1:M1", "A4:M5"], [detail, "A1:H1", "A3:H3"]]) {
  sheet.getRange(titleRange).format = { font: { name: font, size: 14, bold: true, color: "#1F1F1F" }, rowHeight: 28 };
  sheet.getRange(headerRange).format = {
    fill: "#1F4E78", font: { name: font, size: 10, bold: true, color: "#FFFFFF" },
    horizontalAlignment: "center", verticalAlignment: "center", wrapText: true,
    borders: { preset: "inside", style: "thin", color: "#FFFFFF" }, rowHeight: 42,
  };
}

summary.getRange("A3:M3").format = { fill: "#D9EAF7", font: { name: font, size: 11, bold: true, color: "#1F1F1F" } };
summary.getRange("A14:M14").format = { fill: "#D9EAF7", font: { name: font, size: 11, bold: true, color: "#1F1F1F" } };
summary.getRange("A15:M16").format = { fill: "#1F4E78", font: { name: font, size: 10, bold: true, color: "#FFFFFF" }, horizontalAlignment: "center", verticalAlignment: "center", wrapText: true };
summary.getRange("C6:M11").format.numberFormat = "#,##0";
summary.getRange("C17:M18").format.numberFormat = "#,##0";
summary.getRange("C6:M11").format.horizontalAlignment = "right";
summary.getRange("C17:M18").format.horizontalAlignment = "right";
summary.getRange("A4:M11").format.borders = { preset: "all", style: "thin", color: "#D9E2F3" };
summary.getRange("A15:M18").format.borders = { preset: "all", style: "thin", color: "#D9E2F3" };
summary.getRange("A:A").format.columnWidth = 32;
summary.getRange("B:B").format.columnWidth = 12;
summary.getRange("C:M").format.columnWidth = 10;
summary.getRange("A6:M11").format.rowHeight = 22;
summary.getRange("A17:M18").format.rowHeight = 22;
summary.freezePanes.freezeRows(5);
summary.freezePanes.freezeColumns(2);

detail.getRange(`E4:F${3 + detailRows.length}`).format.numberFormat = "#,##0";
detail.getRange(`H4:H${3 + detailRows.length}`).format.numberFormat = "#,##0.00";
detail.getRange(`A3:H${3 + detailRows.length}`).format.borders = { preset: "all", style: "thin", color: "#E7E6E6" };
detail.getRange("A:C").format.columnWidth = 12;
detail.getRange("D:D").format.columnWidth = 34;
detail.getRange("E:H").format.columnWidth = 16;
detail.getRange(`A4:H${3 + detailRows.length}`).format.rowHeight = 20;
detail.freezePanes.freezeRows(3);

wb.recalculate();
const check = await wb.inspect({ kind: "table", range: "Summary!A1:M18", include: "values,formulas", tableMaxRows: 22, tableMaxCols: 15 });
console.log(check.ndjson);
const errors = await wb.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!", options: { useRegex: true, maxResults: 100 }, summary: "final formula error scan" });
console.log(errors.ndjson);
await fs.mkdir(outputDir, { recursive: true });
const preview = await wb.render({ sheetName: "Summary", range: "A1:M18", scale: 1.2, format: "png" });
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));
const out = await SpreadsheetFile.exportXlsx(wb);
await out.save(outputPath);
console.log(JSON.stringify({ outputPath, previewPath }));
