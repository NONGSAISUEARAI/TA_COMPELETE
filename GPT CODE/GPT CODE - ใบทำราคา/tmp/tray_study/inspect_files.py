import json, zipfile, hashlib
from pathlib import Path
from collections import Counter
from xml.etree import ElementTree as E
from pypdf import PdfReader

root = Path(__file__).resolve().parents[2] / 'เรียนรู้การทำถาดไฟ'
ns = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
for folder in sorted((root/'outputs').iterdir()):
    if not folder.is_dir(): continue
    for file in sorted(folder.glob('*')):
        if file.suffix not in ('.xlsx', '.xlsm') or file.name.startswith(('edited_', 'verification')): continue
        with zipfile.ZipFile(file) as z:
            shared = []
            if 'xl/sharedStrings.xml' in z.namelist():
                shared = [''.join(x.itertext()) for x in E.fromstring(z.read('xl/sharedStrings.xml'))]
            def cells(part):
                tree = E.fromstring(z.read(part))
                vals = {}
                for c in tree.findall('.//s:c', ns):
                    if c.get('t') == 'inlineStr': val = ''.join(t.text or '' for t in c.findall('.//s:t', ns))
                    else:
                        val = c.findtext('s:v', default='', namespaces=ns)
                        if c.get('t') == 's': val = shared[int(val)] if val else ''
                    vals[c.get('r')] = val
                return tree, vals
            wb = E.fromstring(z.read('xl/workbook.xml'))
            sheets = []
            for i, sh in enumerate(wb.find('s:sheets',ns), 1):
                tree, v = cells(f'xl/worksheets/sheet{i}.xml')
                rows = [r for r in range(7,27) if v.get(f'A{r}')]
                if not rows: continue
                heights = Counter(r.get('ht','default') for r in tree.findall('s:sheetData/s:row',ns) if 7 <= int(r.get('r')) <= 26)
                sheets.append({'sheet':sh.get('name'),'state':sh.get('state','visible'), 'header':{a:v.get(a) for a in ['Z1','Z2','C2','C3','V3','W3','X3','C44','Z45']},'items':len(rows),'qty':sum(float(v.get(f'W{r}') or 0) for r in rows),'widths':dict(Counter(v.get(f'K{r}') for r in rows)),'thk':dict(Counter(v.get(f'I{r}') for r in rows)),'J_nonempty':sum(bool(v.get(f'J{r}')) for r in rows),'row_heights':dict(heights),'first':{a:v.get(a) for a in ['B7','E7','F7','G7','P7','S7','T7','U7','V7','W7','X7','Z7']}})
            print(json.dumps({'folder':folder.name,'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()[:16],'macros':'xl/vbaProject.bin' in z.namelist(),'sheets':sheets},ensure_ascii=False))
    for file in folder.glob('*.pdf'):
        doc = PdfReader(file)
        print(json.dumps({'pdf_folder':folder.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()[:16],'pages':len(doc.pages),'text_start':doc.pages[0].extract_text()[:900]},ensure_ascii=False))

src = json.loads((root/'outputs/rfq_26106_rev01/source_table.json').read_text(encoding='utf-8'))
print(json.dumps({'source_items':len(src),'source_qty':sum(sum(r[4]) for r in src),'station_qty':dict(zip(['PP17','PP18','PP19','PP20'],[sum(sum(r[4][:3]) for r in src),sum(r[4][3] for r in src),sum(sum(r[4][4:6]) for r in src),sum(r[4][6] for r in src)])),'color_qty':{c:sum(sum(r[4]) for r in src if r[3]==c) for c in sorted({r[3] for r in src})}},ensure_ascii=False))

final=next((root/'outputs/rfq_26106_height17_ready').glob('*.xlsm'))
with zipfile.ZipFile(final) as z:
    shared=[]
    if 'xl/sharedStrings.xml' in z.namelist():
        shared=[''.join(x.itertext()) for x in E.fromstring(z.read('xl/sharedStrings.xml'))]
    expected=json.loads((root/'outputs/rfq_26106_corrected/sorted_source.json').read_text(encoding='utf-8'))
    checked=0
    for page in (1,2):
        _,v=cells(f'xl/worksheets/sheet{page}.xml')
        for j,rec in enumerate(expected[(page-1)*20:page*20]):
            r=7+j
            assert float(v[f'K{r}'])==249
            assert float(v[f'M{r}'])==rec['w1']+rec['w2']
            assert float(v[f'W{r}'])==sum(rec['qty'])
            assert (v.get(f'P{r}') or v.get(f'S{r}'))==rec['finish']
            assert f'PJ25-031AL-TRAY-LT-VA-{checked+1:02}' in v[f'B{r}']
            checked+=1
    print('MATCHED_SOURCE_ROWS',checked)
    for n in ['xl/drawings/vmlDrawing1.vml']:
        t=E.fromstring(z.read(n))
        for shape in t:
            caption=' '.join(''.join(shape.itertext()).split())
            if caption:
                print(json.dumps({'shape':shape.get('id'),'caption':caption},ensure_ascii=False))
    for n in z.namelist():
        if n.startswith('xl/ctrlProps/') and n.endswith('.xml'):
            print(n, z.read(n).decode('utf-8')[:650])
