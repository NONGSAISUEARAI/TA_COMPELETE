import fs from "node:fs/promises";
import path from "node:path";
import { Workbook } from "file:///C:/Users/tawan.t/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const root = process.argv[2];
const outputName = "comment_approve_status.csv";
if (!root) throw new Error("Usage: node build_comment_approve_csv.mjs <root>");
const outputPath = path.join(root, outputName);

async function collectFiles(directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true });
  const results = [];
  for (const entry of entries) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) results.push(...await collectFiles(fullPath));
    else if (entry.isFile()) results.push(fullPath);
  }
  return results;
}

function csvEscape(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

if (await fs.stat(outputPath).then(() => true).catch(() => false)) {
  throw new Error(`Refusing to overwrite existing file: ${outputPath}`);
}

const allFiles = await collectFiles(root);
const rows = allFiles
  .filter((file) => /_FROM_CKST\]_(COMMENT|APPROVE)/i.test(file))
  .map((file) => {
    const relativePath = path.relative(root, file);
    const status = /_FROM_CKST\]_APPROVE/i.test(relativePath) ? "APPROVE" : "COMMENT";
    const station = relativePath.match(/^\[([^\]]+)\]/)?.[1] ?? "";
    const entrance = relativePath.match(/\[(PP\d+)_ENT(\d+)\]/i)?.[2] ?? "";
    const date = relativePath.match(/_(\d{8})[\\/][^\\/]+$/)?.[1] ?? "";
    return [station, entrance, status, date, path.basename(file), relativePath];
  })
  .sort((a, b) => a[0].localeCompare(b[0]) || Number(a[1] || 0) - Number(b[1] || 0) || a[2].localeCompare(b[2]) || a[3].localeCompare(b[3]) || a[4].localeCompare(b[4]));

const headers = ["Station", "Entrance", "Status", "Date", "FileName", "RelativePath"];
const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Status");
sheet.getRangeByIndexes(0, 0, rows.length + 1, headers.length).values = [headers, ...rows];
const inspected = await workbook.inspect({ kind: "region", sheetId: "Status", range: `A1:F${rows.length + 1}`, maxChars: 1000 });
if (!inspected) throw new Error("Unable to verify status table");

const csvText = [headers, ...rows].map((row) => row.map(csvEscape).join(",")).join("\r\n") + "\r\n";
await fs.writeFile(outputPath, "\ufeff" + csvText, "utf8");
console.log(JSON.stringify({ outputPath, total: rows.length, comment: rows.filter((row) => row[2] === "COMMENT").length, approve: rows.filter((row) => row[2] === "APPROVE").length }));
