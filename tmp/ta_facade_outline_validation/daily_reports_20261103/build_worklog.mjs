import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import os from 'node:os';

const root = 'C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE';
const dir = path.join(root, 'outputs/daily_reports/2026-11-03');
const machineName = process.env.COMPUTERNAME?.trim() || os.hostname();
const filenamePrefix = machineName.replace(/[<>:"/\\|?*\u0000-\u001f]/g, '_').replace(/[. ]+$/g, '') || 'COMPUTER';
const mdPath = path.join(dir, `${filenamePrefix}_FO_WORKLOG_2026-11-03.md`);
const txtPath = path.join(dir, `${filenamePrefix}_FO_WORKLOG_2026-11-03.txt`);
const templatePath = fs.existsSync(mdPath) ? mdPath : path.join(dir, 'FO_WORKLOG_2026-11-03.md');
const normalize = text => text.replace(/\r\n/g, '\n').replace(/^\uFEFF/, '');
const read = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const sourcePath = 'GPT CODE/TA_FACADE_OUTLINE/TA_FACADE_OUTLINE.lsp';
const source = read(sourcePath);
const version = source.match(/;;; TA_FACADE_OUTLINE v([0-9.]+)/)?.[1];
const preset = source.slice(0, source.indexOf(';;; TA_FACADE_OUTLINE')).trimEnd();
const results = read('GPT CODE/TA_FACADE_OUTLINE/tests/results.txt');
const pass = [...results.matchAll(/^PASS /gm)].length;
if (pass !== 93 || /^FAIL /m.test(results) || !results.includes('TOTAL PASS=93 FAIL=0')) {
  throw new Error('Expected a completed 93/0 test report.');
}
if (!version) throw new Error('Missing source version.');

let md = normalize(fs.readFileSync(templatePath, 'utf8'));
md = /^ชื่อคอมพิวเตอร์ที่ใช้สร้างไฟล์:/m.test(md)
  ? md.replace(/^ชื่อคอมพิวเตอร์ที่ใช้สร้างไฟล์:.*$/m, `ชื่อคอมพิวเตอร์ที่ใช้สร้างไฟล์: ${machineName}`)
  : md.replace(/^วันที่ .+$/m, `$&\n\nชื่อคอมพิวเตอร์ที่ใช้สร้างไฟล์: ${machineName}`);
const presetBlock = `<!-- PRESET_START -->\n\n\`\`\`lisp\n${preset}\n\`\`\`\n\n<!-- PRESET_END -->`;
md = md.includes('<!-- CURRENT_PRESET -->')
  ? md.replace('<!-- CURRENT_PRESET -->', presetBlock)
  : md.replace(/<!-- PRESET_START -->[\s\S]*?<!-- PRESET_END -->/, presetBlock);

const appendices = [
  [`A. โค้ด AutoLISP v${version} เต็มไฟล์`, sourcePath, 'lisp'],
  ['B. Fixture รูปทรงรอยต่อเกือบทับกัน', 'GPT CODE/TA_FACADE_OUTLINE/tests/fixtures/near_coincident_panels.lsp', 'lisp'],
  ['C. ผลทดสอบทั้งหมด 93 กรณี', 'GPT CODE/TA_FACADE_OUTLINE/tests/results.txt', 'text'],
  ['D. ผลเทียบ exception ใน ESTIMATE_C06_REV02.dwg', 'outputs/fo_c06_trial/trial-results.txt', 'text'],
  ['E. ผลทดลองชุด Block/Pline ผสม', 'outputs/fo_c06_trial/mixed-results.txt', 'text'],
  ['F. ผลรัน c:FO หลังแก้ test.dwg', 'outputs/fo_test_debug/validation.txt', 'text'],
  ['G. โค้ดชุดทดสอบ AutoLISP เต็มไฟล์', 'GPT CODE/TA_FACADE_OUTLINE/tests/TA_FACADE_OUTLINE_tests.lsp', 'lisp'],
  ['H. สคริปต์รัน Core Console', 'GPT CODE/TA_FACADE_OUTLINE/tests/run.scr', 'text'],
  ['I. ตัวตรวจวงเล็บและสตริง', 'GPT CODE/TA_FACADE_OUTLINE/tests/check-syntax.mjs', 'javascript'],
];
let appendixText = '<!-- APPENDICES_START -->\n';
for (const [title, relative, language] of appendices) {
  const absolute = `${root}/${relative}`;
  const raw = fs.readFileSync(absolute);
  const digest = crypto.createHash('sha256').update(raw).digest('hex').toUpperCase();
  const content = normalize(raw.toString('utf8')).trimEnd();
  appendixText += `\n## ${title}\n\nไฟล์: ${absolute}\n\nSHA-256 ของไฟล์ต้นทาง: ${digest}\n\n\`\`\`${language}\n${content}\n\`\`\`\n`;
}
appendixText += '\n<!-- APPENDICES_END -->';
md = md.includes('<!-- APPENDICES -->')
  ? md.replace('<!-- APPENDICES -->', appendixText)
  : md.replace(/<!-- APPENDICES_START -->[\s\S]*?<!-- APPENDICES_END -->/, appendixText);
md = md.trimEnd() + '\n';

function plainText(markdown) {
  let fence = false;
  const output = [];
  for (let line of markdown.split('\n')) {
    if (/^```/.test(line)) { fence = !fence; continue; }
    if (fence) { output.push(line); continue; }
    if (/^<!--.*-->$/.test(line)) continue;
    line = line.replace(/^#{1,6}\s+/, '')
      .replace(/\[([^\]]+)\]\(<([^>]+)>\)/g, '$1 ($2)')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1 ($2)')
      .replace(/\*\*([^*]+)\*\*/g, '$1')
      .replace(/`([^`]+)`/g, '$1');
    output.push(line);
  }
  if (fence) throw new Error('Unbalanced Markdown code fence.');
  return output.join('\n').replace(/\n{4,}/g, '\n\n\n').trimEnd() + '\n';
}
const txt = plainText(md);
for (const text of [md, txt]) {
  if (text.includes('\uFFFD')) throw new Error('Found a Unicode replacement character.');
  if (text.includes('<!-- CURRENT_PRESET -->') || text.includes('<!-- APPENDICES -->')) throw new Error('Unresolved template.');
  for (const expected of ['9.14321644', '17.73057036', '9.18687046', '0.78835193', '38.968', '0.688', 'TOTAL PASS=93 FAIL=0']) {
    if (!text.includes(expected)) throw new Error(`Missing fact: ${expected}`);
  }
  if (!text.includes(source.trimEnd())) throw new Error('The full LISP snapshot was altered.');
}

for (const match of md.slice(0, md.indexOf('<!-- APPENDICES_START -->')).matchAll(/\]\((?:<)?(C:\/[^\n)>]+)(?:>)?\)/g)) {
  if (!fs.existsSync(match[1])) throw new Error(`Broken local link: ${match[1]}`);
}

fs.writeFileSync(mdPath, md, 'utf8');
fs.writeFileSync(txtPath, '\uFEFF' + txt.replace(/\n/g, '\r\n'), 'utf8');
for (const file of [mdPath, txtPath]) {
  const data = fs.readFileSync(file);
  console.log(JSON.stringify({ file, bytes: data.length, lines: normalize(data.toString('utf8')).split('\n').length,
    sha256: crypto.createHash('sha256').update(data).digest('hex').toUpperCase() }));
}
console.log(`Verified: UTF-8 Thai; full v${version} source; all 93 test results; native DWG logs; local links.`);
