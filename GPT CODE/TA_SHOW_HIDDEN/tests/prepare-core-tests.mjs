// Extract the exact pure production functions. Core Console has native DXF /
// command support but no ActiveX document, so it cannot load vl-load-com.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url));
const source = fs.readFileSync(path.join(dir, '../TA_SHOW_HIDDEN.lsp'), 'utf8');
const functions = ['TA:SHW:Require', 'TA:SHW:WipeVertices'].map(name => {
  const start = source.indexOf(`(defun ${name} `);
  if (start < 0) throw new Error(`Missing production function ${name}`);
  let depth = 0, string = false, comment = false, escaped = false;
  for (let i = start; i < source.length; i++) {
    const c = source[i];
    if (c === '\n') comment = false;
    if (comment) continue;
    if (string) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') string = false;
    } else if (c === ';') comment = true;
    else if (c === '"') string = true;
    else if (c === '(') depth++;
    else if (c === ')' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`Unclosed production function ${name}`);
});
fs.writeFileSync(path.join(dir, 'core-production-generated.lsp'),
  '; Generated from the production file by prepare-core-tests.mjs. Do not edit.\n'
  + functions.join('\n\n') + '\n', 'utf8');
console.log('Prepared exact production WIPEOUT conversion for native AutoCAD tests.');
