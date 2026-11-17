import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url));
const source = fs.readFileSync(path.join(dir, '../CountV1-6.lsp'), 'utf8');
let depth = 0, quoted = false, comment = false, escape = false, start = -1;
const forms = [];
for (let i = 0; i < source.length; i++) {
  const c = source[i];
  if (c === '\n') comment = false;
  if (comment) continue;
  if (quoted) {
    if (escape) escape = false;
    else if (c === '\\') escape = true;
    else if (c === '"') quoted = false;
  } else if (c === ';') comment = true;
  else if (c === '"') quoted = true;
  else if (c === '(') { if (depth++ === 0) start = i; }
  else if (c === ')') {
    if (--depth < 0) throw new Error('Extra closing parenthesis');
    if (depth === 0) forms.push(source.slice(start, i + 1));
  }
}
if (depth || quoted) throw new Error('Unclosed form/string');
const functions = forms.filter(f => /^\(defun count:/i.test(f));
fs.writeFileSync(path.join(dir, 'count-core-generated.lsp'), functions.join('\n\n') + '\n');
console.log(`Syntax balanced; extracted ${functions.length} production functions for Core Console.`);
