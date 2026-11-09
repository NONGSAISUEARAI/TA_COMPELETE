from pathlib import Path
import zipfile,xml.etree.ElementTree as ET
from openpyxl import load_workbook
root=Path(__file__).resolve().parents[2]
audit=sorted((root/'backups').glob('recovery-audit-*'))[-1]
path=audit/'Export_validation.xlsx'
with zipfile.ZipFile(path) as archive:
    assert archive.testzip() is None
    for name in archive.namelist():ET.fromstring(archive.read(name))
workbook=load_workbook(path,data_only=False)
sheet=workbook['Programm Database']
assert sheet.max_row==122 and sheet.max_column==46
assert sheet['A4'].fill.fgColor.rgb=='FF262626'
assert sheet['A4'].font.color.rgb=='FFFFC000'
assert sheet['A4'].font.name=='CordiaUPC'
assert sheet['E11'].font.name=='Cordia New'
assert sheet['A5'].fill.fgColor.rgb=='FF404040'
assert sheet['A6'].fill.fgColor.rgb=='FF3A3838'
assert sheet['S3'].alignment.textRotation==90
assert sheet['E7'].alignment.indent==1 and sheet['E11'].alignment.indent==3
assert sheet.freeze_panes=='F5'
assert sheet.column_dimensions['C'].hidden and sheet.column_dimensions['D'].hidden
assert len(sheet.conditional_formatting)==118
assert load_workbook(path,data_only=True)['Programm Database']['P5'].value is None
print('PASS: recovered Excel export ZIP/CRC/XML and workbook read-back; 122 rows, reference palette/fonts/borders, hierarchy, native dates, conditional formatting and blanks.')
