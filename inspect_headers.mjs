import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/tawan.t/Downloads/MTO_MRT สายม่วงใต้ PL-2065V_V.20260916 LOT 2.xlsx";
const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const overview = await workbook.inspect({
  kind: "sheet,region",
  sheetId: "PL-2065V_New (2)",
  range: "B1:Z32",
  maxChars: 5000,
});
console.log(overview.ndjson);
console.log(workbook.help("range.delete", { include: "index,examples,notes", maxChars: 4000 }).ndjson);
const preview = await workbook.render({
  sheetName: "PL-2065V_New (2)",
  range: "B1:Z32",
  scale: 1,
  format: "png",
});
await fs.writeFile("header_before.png", new Uint8Array(await preview.arrayBuffer()));
