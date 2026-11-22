from pathlib import Path
import re
import zipfile

root=Path(__file__).resolve().parents[2]
source=next((root/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106_height17_ready').glob('*.xlsm'))
dest=Path(__file__).with_name('html-export-copy.xlsm')
removed=0
with zipfile.ZipFile(source) as zin, zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as zout:
    for info in zin.infolist():
        data=zin.read(info.filename)
        if info.filename.startswith('xl/worksheets/') and info.filename.endswith('.xml'):
            data,count=re.subn(rb'<sheetProtection\b[^>]*/>',b'',data)
            removed+=count
        if info.filename=='xl/workbook.xml':
            data=re.sub(rb'<workbookProtection\b[^>]*/>',b'',data)
        zout.writestr(info,data)
print('Prepared temporary export copy; protection records removed:',removed)
