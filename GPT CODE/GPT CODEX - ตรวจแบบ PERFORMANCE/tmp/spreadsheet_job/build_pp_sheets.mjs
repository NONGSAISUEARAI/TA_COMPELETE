import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const outputDir = "../../outputs/pp17_pp20_c03";
const previewDir = "./darkmode_previews";
const outputPath = `${outputDir}/Material_Quantity_C03_PP17-PP20.xlsx`;
const stations = ["PP17", "PP18", "PP19", "PP20"];

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

const input = await FileBlob.load(outputPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const palette = {
  canvas: "#0B1220",
  surface: "#111827",
  surfaceAlt: "#172033",
  header: "#1E3A5F",
  border: "#334155",
  strongBorder: "#64748B",
  text: "#E5E7EB",
  muted: "#94A3B8",
  title: "#F8FAFC",
  cyan: "#38BDF8",
  amberFill: "#3A2E0F",
  amberText: "#FCD34D",
  greenFill: "#123A35",
  greenText: "#A7F3D0",
  blueFill: "#172A46",
  blueText: "#BFDBFE",
};

for (const station of stations) {
  const sheet = workbook.worksheets.getItem(station);
  sheet.showGridLines = false;
  sheet.tabColor = "#1E3A5F";

  sheet.getRange("A1:G16").format = {
    fill: palette.canvas,
    font: { name: "Arial", size: 10, color: palette.text },
    verticalAlignment: "center",
  };

  sheet.getRange("A2:E2").format = {
    fill: palette.surface,
    font: { name: "Arial", size: 14, bold: true, color: palette.title },
    borders: { bottom: { style: "medium", color: palette.cyan } },
  };

  sheet.getRange("A3:A4").format = {
    fill: palette.surface,
    font: { name: "Arial", size: 10, bold: true, color: "#CBD5E1" },
  };
  sheet.getRange("B3").format = {
    fill: palette.amberFill,
    font: { name: "Arial", size: 10, bold: true, color: palette.amberText },
    numberFormat: "0.00",
    horizontalAlignment: "right",
    borders: { preset: "outside", style: "thin", color: "#B0892E" },
  };
  sheet.getRange("C3:E4").format = {
    fill: palette.surface,
    font: { name: "Arial", size: 9, italic: true, color: palette.muted },
  };

  sheet.getRange("A5:E5").format = {
    fill: palette.header,
    font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
    rowHeight: 34,
    borders: {
      insideVertical: { style: "thin", color: palette.strongBorder },
      bottom: { style: "medium", color: palette.cyan },
    },
  };

  for (let row = 6; row <= 16; row += 1) {
    const rowFill = row % 2 === 0 ? palette.surface : palette.surfaceAlt;
    sheet.getRange(`A${row}:A${row}`).format = {
      fill: rowFill,
      font: { name: "Arial", size: 10, color: palette.text },
      verticalAlignment: "center",
      borders: { bottom: { style: "thin", color: palette.border } },
    };
    sheet.getRange(`B${row}:B${row}`).format = {
      fill: rowFill,
      font: { name: "Arial", size: 10, color: "#FDE68A" },
      numberFormat: "0.00",
      horizontalAlignment: "right",
      verticalAlignment: "center",
      borders: { bottom: { style: "thin", color: palette.border } },
    };
  }

  sheet.getRange("C6:C16").format = {
    fill: "#1B2A33",
    font: { name: "Arial", size: 10, bold: true, color: "#67E8F9" },
    numberFormat: "0.000",
    horizontalAlignment: "right",
    verticalAlignment: "center",
    rowHeight: 22,
    borders: { insideHorizontal: { style: "thin", color: palette.border } },
  };
  sheet.getRange("D6:D16").format = {
    fill: palette.greenFill,
    font: { name: "Arial", size: 10, bold: true, color: palette.greenText },
    numberFormat: "#,##0.000",
    horizontalAlignment: "right",
    verticalAlignment: "center",
    rowHeight: 22,
    borders: { insideHorizontal: { style: "thin", color: palette.border } },
  };
  sheet.getRange("E6:E16").format = {
    fill: palette.blueFill,
    font: { name: "Arial", size: 10, bold: true, color: palette.blueText },
    numberFormat: "#,##0.00",
    horizontalAlignment: "right",
    verticalAlignment: "center",
    rowHeight: 22,
    borders: { insideHorizontal: { style: "thin", color: palette.border } },
  };

  sheet.getRange("F2:G2").format = {
    fill: palette.header,
    font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    borders: {
      insideVertical: { style: "thin", color: palette.strongBorder },
      bottom: { style: "thin", color: palette.cyan },
    },
  };
  sheet.getRange("F3:G3").format = {
    fill: palette.amberFill,
    font: { name: "Arial", size: 10, bold: true, color: palette.amberText },
    numberFormat: [["General", "0.00"]],
    borders: { bottom: { style: "thin", color: "#6B5B2A" } },
  };
  sheet.getRange("F4:G4").format = {
    fill: palette.greenFill,
    font: { name: "Arial", size: 10, bold: true, color: palette.greenText },
    numberFormat: [["General", "0.00"]],
    borders: { bottom: { style: "medium", color: "#34D399" } },
  };
  sheet.getRange("F3:F4").format.horizontalAlignment = "center";
  sheet.getRange("G3:G4").format.horizontalAlignment = "right";
}

workbook.recalculate();

for (const station of stations) {
  const check = await workbook.inspect({
    kind: "table",
    range: `${station}!A2:G16`,
    include: "values,formulas",
    tableMaxRows: 18,
    tableMaxCols: 8,
  });
  console.log(check.ndjson);

  const preview = await workbook.render({
    sheetName: station,
    range: "A1:G16",
    scale: 1.2,
    format: "png",
  });
  await fs.writeFile(`${previewDir}/${station}.png`, new Uint8Array(await preview.arrayBuffer()));
}

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",
  options: { useRegex: true, maxResults: 100 },
  summary: "final formula error scan",
});
console.log(errors.ndjson);

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(`SAVED ${outputPath}`);
