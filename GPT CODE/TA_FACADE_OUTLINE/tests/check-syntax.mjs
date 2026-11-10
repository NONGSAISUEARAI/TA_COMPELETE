import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url));
for (const file of ['../TA_FACADE_OUTLINE.lsp', 'TA_FACADE_OUTLINE_tests.lsp', 'TA_FACADE_FML_tests.lsp', 'TA_FACADE_FML_custom_tests.lsp', 'fixtures/near_coincident_panels.lsp']) {
  const source = fs.readFileSync(path.resolve(dir, file), 'utf8');
  let depth = 0, line = 1, string = false, comment = false, escaped = false;
  const errors = [];
  for (const c of source) {
    if (c === '\n') { line++; comment = false; }
    if (comment) continue;
    if (string) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') string = false;
    } else if (c === ';') comment = true;
    else if (c === '"') string = true;
    else if (c === '(') depth++;
    else if (c === ')' && --depth < 0) { errors.push(`extra close at ${line}`); depth = 0; }
  }
  if (depth || string) errors.push(`unclosed: depth ${depth}, string ${string}`);
  console.log(file, errors.length ? errors.join('; ') : 'balanced');
  if (errors.length) process.exitCode = 1;
}
