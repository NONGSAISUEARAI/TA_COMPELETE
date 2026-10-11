"""Read-only structural inspection. Never evaluates or loads AutoLISP."""
from pathlib import Path
from collections import defaultdict
import hashlib, json, re, sys
sys.stdout.reconfigure(encoding='utf-8')
root = Path(r'C:\TA\TA_COMPELETE\GPT CODE\GPT FOR NEXT')
source = Path(r'C:\TA\TA_COMPELETE\z00x_TA_standard_sun_func_and_MAIN.lsp')
raw = source.read_bytes()
text = raw.decode('utf-8-sig')
tokens = []
i, line = 0, 1
while i < len(text):
    ch = text[i]
    if ch.isspace():
        line += ch == '\n'
        i += 1
    elif text.startswith(';|', i):
        end = text.find('|;', i+2)
        end = len(text) if end == -1 else end+2
        line += text[i:end].count('\n')
        i = end
    elif ch == ';':
        end = text.find('\n', i)
        i = len(text) if end == -1 else end
    elif ch == '"':
        start, first_line = i, line
        i += 1
        while i < len(text):
            if text[i] == '\\': i += 2
            elif text[i] == '"':
                i += 1
                break
            else:
                line += text[i] == '\n'
                i += 1
        tokens.append(('string', text[start:i], first_line, start, i))
    elif ch in "()'":
        tokens.append((ch, ch, line, i, i+1))
        i += 1
    else:
        start = i
        while i < len(text) and not text[i].isspace() and text[i] not in "();\"'": i += 1
        tokens.append(('symbol', text[start:i], line, start, i))
stack, pairs, extra = [], {}, []
for n,tok in enumerate(tokens):
    if tok[0] == '(': stack.append(n)
    elif tok[0] == ')':
        if stack: pairs[stack.pop()] = n
        else: extra.append(tok[2])
defs, byname = [], defaultdict(list)
for n in range(len(tokens)-3):
    if tokens[n][0] == '(' and tokens[n+1][1].lower() == 'defun' and tokens[n+2][0] == 'symbol':
        end = pairs.get(n)
        if end is None: continue
        arg_start = n+3
        arg_end = pairs.get(arg_start, arg_start)
        declared = [t[1].lower() for t in tokens[arg_start+1:arg_end] if t[0]=='symbol' and t[1]!='/']
        body = tokens[arg_end+1:end]
        heads = {body[k+1][1].lower() for k in range(len(body)-1) if body[k][0]=='(' and body[k+1][0]=='symbol'}
        refs = {t[1].lower() for t in body if t[0]=='symbol' and re.match(r'^(ta|lm|tas|co|excel):',t[1],re.I)}
        info = dict(name=tokens[n+2][1],line=tokens[n][2],end_line=tokens[end][2],
                    span=tokens[end][2]-tokens[n][2]+1,declared=declared,
                    calls=sorted(heads), namespaced_refs=sorted(refs),
                    strings=[t[1] for t in body if t[0]=='string'],
                    start_offset=tokens[n][3],end_offset=tokens[end][4])
        defs.append(info)
        byname[info['name'].lower()].append(info)
prior=json.loads(Path(r'C:\Users\popul\Documents\Codex\2026-10-08\referenced-chatgpt-conversation-this-is-an\outputs\autolisp_inventory.json').read_text(encoding='utf-8'))
wanted={d['name'].lower() for d in prior['definitions'] if d['kind']=='command' and d['category']=='01'}
extra_names = ['matching_attribute_properties_maatt','matching_attribute_properties_madeepatt',
 'fillter_blockname_to_text_b2text','effectivename_to_att_EF2text','prefix-subfix_all-block_',
 'counting_blklist_','insert_by_polyline_blk2pline','insert_by_line_blk2pline',
 'insert_by_intersect_blk2in_','insert_by_centroid_blk2ct','insert_by_centroid_blk2cen',
 'insert_array_insarray','offset_block_ofblk','qblk','point_to_block_pt2blk']
wanted.update('c:'+name.lower() for name in extra_names)
selected=[d for d in defs if d['name'].lower() in wanted]
for d in selected:
    d['dependencies'] = sorted(set(d['calls'])&set(byname))
    d['missing_namespaced_refs'] = sorted(set(d['namespaced_refs'])-set(byname))
    d['same_name_lines']=[x['line'] for x in byname[d['name'].lower()]]
metadata=dict(source=str(source),sha256=hashlib.sha256(raw).hexdigest(),line_count=len(text.splitlines()),
              total_definitions=len(defs),base_category_names=len(wanted)-len(extra_names),
              reviewed_scope_definitions=len(selected),unmatched_closing_lines=extra,
              unmatched_opening_lines=[tokens[n][2] for n in stack],definitions=selected)
(root/'work').mkdir(exist_ok=True)
(root/'work'/'block-audit-metadata.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in metadata.items() if k!='definitions'},ensure_ascii=False,indent=2))
for d in selected:
    print(f'{d["line"]}-{d["end_line"]} | {d["name"]} | locals/args={len(d["declared"])} | deps={len(d["dependencies"])} | absent={d["missing_namespaced_refs"]}')
assert hashlib.sha256(source.read_bytes()).hexdigest()==metadata['sha256']
export_fields = ['name', 'line', 'end_line', 'span', 'declared', 'dependencies', 'same_name_lines']
helper_names = sorted({name for d in selected for name in d['dependencies'] if not name.startswith('c:')})
export = {k:v for k,v in metadata.items() if k!='definitions'}
export['scope_note'] = '45 prior Block-category commands plus 15 related commands; not an exhaustive semantic inventory of the entire file. Static inspection only; no CAD execution.'
export['definitions'] = [{k:d[k] for k in export_fields} for d in selected]
export['direct_helper_definitions'] = [
    {k:d[k] for k in ['name','line','end_line','declared']}
    for name in helper_names for d in byname[name]
]
export['dependency_note'] = 'Internal call-head candidates only. Indirect calls, quoted expressions, external CAD commands, document state and block schemas require manual review.'
(root/'cad-automation-portfolio'/'data'/'block-command-inventory.json').write_text(
    json.dumps(export,ensure_ascii=False,indent=2),encoding='utf-8')
