import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const sourcePath = String.raw`C:\TA\PPLINE CKST\C1&C2_0121-1 Update (29.01.26) PPedit\COMBINE DWG PANEL FOR ASPG PM\20260729_PART SIZE PERFORMANCE LOUVER  MRT PURPLE LINE R3 (1) - FOR GPT.xlsm`;
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(sourcePath));
const summary = workbook.worksheets.getItem("สรุปชุดเฟรม REV03");
const pre = workbook.worksheets.getItem("pre summary aspg");

const normalize = (value) => String(value ?? "").trim().replace(/\s+/g, " ").toUpperCase();
const toNumber = (value) => Number.isFinite(Number(value)) ? Number(value) : null;
const summaryRows = summary.getRange("A5:M243").values;
const preRows = pre.getRange("A3:M634").values;

const lot1Rows = preRows.map((row, index) => ({
  excelRow: index + 3,
  no: row[0],
  panel: row[1],
  type: normalize(row[2]),
  wRound: toNumber(row[4]),
  h: toNumber(row[5]),
  set: toNumber(row[6]) ?? 0,
  station: row[7],
  lot: normalize(row[8]),
  color: normalize(row[9]),
  summaryName: normalize(row[12]),
})).filter((row) => row.lot === "LOT1");

const typeBuckets = [
  { index: 9, color: "RAL-7045", type: "DOUBLE BLANK" },
  { index: 10, color: "RAL-7045", type: "SINGLE BLANK" },
  { index: 11, color: "RAL-1001", type: "DOUBLE BLANK" },
  { index: 12, color: "RAL-1001", type: "SINGLE BLANK" },
];
const colorBuckets = [
  { indexes: [9, 10], color: "RAL-7045" },
  { indexes: [11, 12], color: "RAL-1001" },
];

const output = [];
const validations = [];
for (const row of summaryRows) {
  const summaryNo = toNumber(row[0]);
  const summaryName = normalize(row[1]);
  const x = toNumber(row[2]);
  const y = toNumber(row[3]);
  if (summaryNo === null || summaryNo <= 0 || !summaryName || x === null || y === null) continue;

  for (const bucket of typeBuckets) {
    const expected = toNumber(row[bucket.index]) ?? 0;
    const matches = lot1Rows.filter((item) =>
      item.summaryName === summaryName && item.color === bucket.color && item.type === bucket.type
    );
    const actual = matches.reduce((sum, item) => sum + item.set, 0);
    if (expected > 0 || actual > 0) {
      validations.push({ summaryNo, summaryName, color: bucket.color, type: bucket.type, expected, actual });
    }
  }

  for (const bucket of colorBuckets) {
    const expected = bucket.indexes.reduce((sum, index) => sum + (toNumber(row[index]) ?? 0), 0);
    if (expected <= 0) continue;
    const matches = lot1Rows.filter((item) => item.summaryName === summaryName && item.color === bucket.color);
    if (matches.length === 0) {
      output.push({ summaryNo, x, y, summaryColor: bucket.color, preNo: "ไม่พบ", panel: "-", wRound: "-", h: "-", set: "-", station: "-", lot: "-", preColor: "-" });
    } else {
      for (const match of matches) {
        output.push({ summaryNo, x, y, summaryColor: bucket.color, preNo: match.no, panel: match.panel, wRound: match.wRound, h: match.h, set: match.set, station: match.station, lot: "Lot1", preColor: match.color });
      }
    }
  }
}

output.sort((a, b) => a.summaryNo - b.summaryNo || a.summaryColor.localeCompare(b.summaryColor) || Number(a.preNo) - Number(b.preNo));
const mismatches = validations.filter((item) => item.expected !== item.actual);
const matchedPreNos = new Set(output.filter((item) => item.preNo !== "ไม่พบ").map((item) => String(item.preNo)));
const uncoveredLot1 = lot1Rows.filter((item) => !matchedPreNos.has(String(item.no)));
const duplicatePreNos = [...matchedPreNos].filter((no) => output.filter((item) => String(item.preNo) === no).length !== 1);
const noMatchRows = output.filter((item) => item.preNo === "ไม่พบ");

console.log("| NO. | X | Y | COLOR | NO | NAME-PANEL (set-A) | W round | H | SET | STATION | LOT | COLOR |\n|---:|---:|---:|---|---:|---|---:|---:|---:|---|---|---|");
for (const row of output) {
  console.log(`| ${row.summaryNo} | ${row.x} | ${row.y} | ${row.summaryColor} | ${row.preNo} | ${row.panel} | ${row.wRound} | ${row.h} | ${row.set} | ${row.station} | ${row.lot} | ${row.preColor} |`);
}
console.log("QC", JSON.stringify({
  summaryColorGroups: new Set(output.map((row) => `${row.summaryNo}|${row.summaryColor}`)).size,
  outputRows: output.length,
  lot1SourceRows: lot1Rows.length,
  validationGroups: validations.length,
  mismatches,
  noMatchRows,
  uncoveredLot1,
  duplicatePreNos,
}, null, 2));
