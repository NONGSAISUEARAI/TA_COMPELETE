from pathlib import Path
import json,zipfile,xml.etree.ElementTree as ET
from datetime import datetime
from openpyxl import load_workbook
root=Path(__file__).resolve().parents[2]
folder=root/'outputs/lv4-validation'
expected=json.loads((folder/'expected.json').read_text(encoding='utf-8'))
results=[]
for name in ['synthetic-activities.xlsx','browser-export.xlsx']:
    file=folder/name
    with zipfile.ZipFile(file) as z:
        assert z.testzip() is None
        for entry in z.namelist():ET.fromstring(z.read(entry))
    book=load_workbook(file,data_only=False)
    sheet=book['Programm Database']
    assert sheet['W4'].value=='Activity' and sheet['X4'].value=='Description ID'
    assert sheet['A4'].fill.fgColor.rgb=='FF262626' and sheet['A4'].font.color.rgb=='FFFFC000'
    assert sheet['A5'].fill.fgColor.rgb=='FF404040' and sheet['A6'].fill.fgColor.rgb=='FF3A3838'
    assert sheet['E5'].font.name=='Cordia New'
    assert sheet.column_dimensions['X'].hidden and not sheet.column_dimensions['W'].hidden
    assert all(sheet.column_dimensions[c].hidden for c in ['S','T','U','V'])
    activity_ids=[]
    for r in range(5,sheet.max_row+1,2):
        assert sheet.cell(r,18).value=='Plan' and sheet.cell(r+1,18).value=='Actual'
        assert all(sheet.cell(r,c).value==sheet.cell(r+1,c).value for c in [1,2,3,4,5,19,20,21,22,23,24])
        assert all(sheet.cell(r,c).value for c in [1,2,3,4,5,20,21,22])
        if sheet.cell(r,19).value=='Activity':
            assert sheet.cell(r,23).value and sheet.cell(r,24).value
            activity_ids.append(sheet.cell(r,20).value)
        else:
            assert sheet.cell(r,23).value is None and sheet.cell(r,24).value is None
    assert len(activity_ids)==len(set(activity_ids))
    if name.startswith('synthetic'):
        assert sheet.max_column==52 and sheet.max_row==expected['recordCount']*2+4
        assert set(activity_ids)==set(expected['activityIDs'])
        assert len(sheet.conditional_formatting)==expected['recordCount']*2
        assert sheet['Y3'].alignment.textRotation==90
        assert all(sheet.cell(r,24).value==expected['descriptionID'] for r in range(5,sheet.max_row+1) if sheet.cell(r,19).value=='Activity')
        assert sheet['P5'].value.startswith('=IF(')
        assert sheet['L5'].value==datetime(2026,11,2)
        assert sheet['L6'].value==datetime(2026,11,3)
        assert load_workbook(file,data_only=True)['Programm Database']['P5'].value==2
    else:
        assert sheet.max_column==24 and len(activity_ids)==1
        assert len(sheet.conditional_formatting)==0
    results.append({'file':name,'phaseRows':sheet.max_row-4,'columns':sheet.max_column,'activities':len(activity_ids)})
print(json.dumps({'result':'PASS','scope':'ZIP/CRC/XML, Activity and Description ID pairs, native dates/formulas, reference styling, hidden metadata, calendar offsets, actual browser download','files':results}))
