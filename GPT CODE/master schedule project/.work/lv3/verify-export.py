from pathlib import Path
import zipfile, xml.etree.ElementTree as ET, json
from openpyxl import load_workbook
root = Path(__file__).resolve().parents[2]
file = root / 'outputs/database/Master_Schedule_PJ25-031.xlsx'
with zipfile.ZipFile(file) as archive:
    assert archive.testzip() is None
    for name in archive.namelist():
        ET.fromstring(archive.read(name))
w = load_workbook(file, data_only=False)
s = w['Programm Database']
assert s.max_row == 42 and s.max_column == 50
assert s['T4'].value == 'Task ID' and s['U4'].value == 'Project ID' and s['V4'].value == 'Product ID'
assert s['A4'].fill.fgColor.rgb == 'FF262626'
assert s['A4'].font.color.rgb == 'FFFFC000' and s['A4'].font.name == 'CordiaUPC'
assert s['E5'].font.name == 'Cordia New'
assert s['A5'].fill.fgColor.rgb == 'FF404040' and s['A6'].fill.fgColor.rgb == 'FF3A3838'
assert s['W3'].alignment.textRotation == 90
assert s['E5'].alignment.indent == 0
assert s.freeze_panes == 'F5'
assert all(s.column_dimensions[c].hidden for c in ['C','D','S','T','U','V'])
assert len(s.conditional_formatting) == 38
ids=set()
for r in range(5,43,2):
    assert s.cell(r,18).value == 'Plan' and s.cell(r+1,18).value == 'Actual'
    assert all(s.cell(r,c).value and s.cell(r,c).value==s.cell(r+1,c).value for c in range(1,6))
    assert all(s.cell(r,c).value and s.cell(r,c).value==s.cell(r+1,c).value for c in range(19,23))
    assert s.cell(r,20).value not in ids
    ids.add(s.cell(r,20).value)
    assert s.cell(r,12).value is None and s.cell(r+1,12).value is None
assert len(ids)==19
assert load_workbook(file,data_only=True)['Programm Database']['P5'].value is None
print(json.dumps({'result':'PASS','rows':42,'phaseRows':38,'works':19,'columns':50,'checks':'ZIP/CRC/XML, all five business fields, stable IDs, native blank dates, reference colors/fonts, hidden metadata, calendar/Gantt'},ensure_ascii=False))
