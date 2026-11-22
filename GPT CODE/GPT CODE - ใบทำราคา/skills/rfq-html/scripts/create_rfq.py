"""Create a separate RFQ HTML from a reusable master; standard library only."""
import argparse
import copy
import html as html_module
import json
import math
from pathlib import Path
import re

MODEL_RE = re.compile(r'(<script\b[^>]*\bid=["\']template-model["\'][^>]*>)(.*?)(</script>)', re.S)


def read_model(text):
    match = MODEL_RE.search(text)
    if not match:
        raise ValueError('Template has no template-model JSON')
    return json.loads(match.group(2))


def file_base(value):
    value = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '-', str(value))
    value = re.sub(r'\.(html?|pdf|xlsx)$', '', value, flags=re.I)
    return re.sub(r'\s+', ' ', value).rstrip('. ').strip()


def put_model(text, model):
    serialized = json.dumps(model, ensure_ascii=False, separators=(',', ':')).replace('<', '\\u003c')
    text, count = MODEL_RE.subn(lambda m: m.group(1) + serialized + m.group(3), text, count=1)
    if count != 1:
        raise ValueError('Template model replacement failed')
    escaped = lambda value: html_module.escape(str(value), quote=False)
    text = re.sub(r'<title>.*?</title>', lambda _: '<title>' + escaped(model['fileNaming']['baseName']) + '</title>', text, count=1, flags=re.S)
    text = re.sub(r'(<header\b[^>]*>\s*<h1>).*?(</h1>)', lambda m: m.group(1) + escaped(model['headers']['documentNo']) + m.group(2), text, count=1, flags=re.S)
    text = re.sub(r'(<option value="document">).*?(</option>)', lambda m: m.group(1) + f'ใบขอราคา {len(model["current"])} รายการ' + m.group(2), text, count=1, flags=re.S)
    text = re.sub(r'(<span\b[^>]*\bid="summary"[^>]*>).*?(</span>)', lambda m: m.group(1) + m.group(2), text, count=1, flags=re.S)
    # Clear stale preview values in the template's editable header spans as well.
    text = re.sub(r'(<span\b[^>]*\bdata-header="([^"]+)"[^>]*>).*?(</span>)', lambda m: m.group(1) + escaped(model['headers'].get(m.group(2), '')) + m.group(3), text, flags=re.S)
    return text


def clean_row(source, template_model, number, warnings):
    if not isinstance(source, dict):
        raise ValueError(f'Row {number} must be an object')
    unknown = set(source) - set(template_model['columns'])
    if unknown:
        raise ValueError(f'Row {number}: unknown fields {sorted(unknown)}')
    row = {key: '' for key in template_model['columns']}
    row.update(source)
    row['no'] = str(number)
    row['materialCode'] = str(row['materialCode']).strip()
    code = row['materialCode']
    if code and code not in template_model['materials']:
        raise ValueError(f'Row {number}: unknown materialCode {code!r}')
    material = template_model['materials'].get(code, '')
    if row['material'] and row['material'] != material:
        raise ValueError(f'Row {number}: material must agree with materialCode')
    row['material'] = material
    if not code:
        warnings.append(f'Row {number}: material code is blank')
    qty = row['qty']
    if qty is None or str(qty).strip() == '':
        row['qty'] = ''
        warnings.append(f'Row {number}: quantity is blank')
    else:
        if isinstance(qty, bool):
            raise ValueError(f'Row {number}: invalid quantity')
        qty = float(str(qty).replace(',', ''))
        if not math.isfinite(qty) or qty < 0:
            raise ValueError(f'Row {number}: quantity must be finite and nonnegative')
        row['qty'] = int(qty) if qty.is_integer() else qty
    return row


def create(template, payload):
    model = read_model(template)
    unknown = set(payload) - {'headers', 'rows', 'secondary', 'checks', 'pageChecks', 'pageCount', 'materialName', 'fileName'}
    if unknown:
        raise ValueError(f'Unknown input fields: {sorted(unknown)}')
    headers = payload.get('headers', {})
    if set(headers) - set(model['headers']):
        raise ValueError('Unknown header fields')
    model['headers'] = {key: '' for key in model['headers']}
    model['headers'].update({key: str(value) for key, value in headers.items()})
    if not model['headers']['documentNo']:
        raise ValueError('headers.documentNo is required')
    warnings = []
    rows = [clean_row(row, model, i, warnings) for i, row in enumerate(payload.get('rows', []), 1)]
    secondary = []
    for page_rows in payload.get('secondary', []):
        if len(page_rows) > len(model['secondaryRowTops']) - 1:
            raise ValueError('Too many secondary rows on one page')
        secondary.append([clean_row(row, model, i, warnings) for i, row in enumerate(page_rows, 1)])
    pages = max(1, math.ceil(len(rows) / 20), len(secondary), int(payload.get('pageCount', 1)))
    checks = {key: False for key in model['defaultChecks']}
    check_overrides = payload.get('checks', {})
    if set(check_overrides) - set(checks) or any(type(value) is not bool for value in check_overrides.values()):
        raise ValueError('checks must use known names and Boolean values')
    checks.update(check_overrides)
    page_checks = payload.get('pageChecks', [])
    if len(page_checks) > pages:
        raise ValueError('pageChecks has more entries than pages')
    resolved_checks = []
    for i in range(pages):
        overrides = page_checks[i] if i < len(page_checks) else {}
        if set(overrides) - set(checks) or any(type(v) is not bool for v in overrides.values()):
            raise ValueError(f'Invalid pageChecks on page {i+1}')
        resolved_checks.append({**checks, **overrides})
    material_name = str(payload.get('materialName', ''))
    project = re.sub(r'^\s*โครงการ\s*', '', model['headers']['project']).strip()
    automatic = file_base(f'{model["headers"]["documentNo"]}_โครงการ {project} {material_name}')
    name = file_base(payload.get('fileName') or automatic)
    model.update(current=rows, document=copy.deepcopy(rows), original=[], new=[], secondary=secondary, pageCount=pages, pageChecks=resolved_checks, defaultChecks=checks, mode='document')
    model['headers']['pageNumber'] = f'1/{pages}'
    model['documentTitle'] = model['headers']['documentNo']
    model['fileNaming'] = {'materialName': material_name, 'baseName': name, 'manual': bool(payload.get('fileName'))}
    model['downloadFilename'] = name + '.html'
    return put_model(template, model), {
        'items': len(rows) + sum(len(p) for p in secondary),
        'quantity': sum(float(row['qty'] or 0) for row in rows + [r for p in secondary for r in p]),
        'pages': pages, 'filename': name, 'warnings': warnings,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--template', type=Path, default=Path(__file__).resolve().parents[1] / 'assets/BU2-DE-26xxx-MASTER.html')
    args = parser.parse_args()
    source = args.template.resolve()
    output = args.output.resolve()
    if source == output or output.name.upper().endswith('-MASTER.HTML'):
        parser.error('Output must be a new document, never the master')
    if output.exists():
        parser.error(f'Output already exists: {output}')
    payload = json.loads(args.input.read_text(encoding='utf-8-sig'))
    result, report = create(source.read_text(encoding='utf-8'), payload)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('x', encoding='utf-8') as f:
        f.write(result)
    report['output'] = str(output)
    print(json.dumps(report, ensure_ascii=True, indent=2))


if __name__ == '__main__':
    main()
