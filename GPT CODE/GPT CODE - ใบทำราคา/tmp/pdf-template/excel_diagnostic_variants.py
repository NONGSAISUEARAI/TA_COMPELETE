from zipfile import ZipFile,ZIP_DEFLATED
from pathlib import Path
from xml.etree import ElementTree as E
root=Path(__file__).resolve().parents[2];tmp=Path(__file__).parent
with ZipFile(root/'ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx') as original,ZipFile(tmp/'native-qa.xlsx') as generated:
    with ZipFile(tmp/'native-sheet-only.xlsx','w',ZIP_DEFLATED) as z:
        for part in original.namelist():z.writestr(part,generated.read('xl/worksheets/rfq1-sheet1.xml') if part=='xl/worksheets/sheet1.xml' else original.read(part))
    for mode in ['vml','controls']:
        with ZipFile(tmp/f'native-native-{mode}.xlsx','w',ZIP_DEFLATED) as z:
            for part in original.namelist():
                data=original.read(part)
                if part=='xl/worksheets/sheet1.xml':data=generated.read('xl/worksheets/rfq1-sheet1.xml')
                if mode=='vml' and part=='xl/drawings/vmlDrawing1.vml':data=generated.read('xl/drawings/rfq1-vmlDrawing1.vml')
                if mode=='controls' and part in [f'xl/ctrlProps/ctrlProp{i}.xml' for i in range(1,10)]:data=generated.read('xl/ctrlProps/rfq1-'+part.rsplit('/',1)[1])
                z.writestr(part,data)
    # Exclude duplicate revision UIDs and restore valid pane selections.
    with ZipFile(tmp/'native-no-revision.xlsx','w',ZIP_DEFLATED) as z:
        for part in generated.namelist():
            data=generated.read(part)
            if part.startswith('xl/worksheets/') and part.endswith('.xml'):
                text=data.decode('utf-8')
                import re
                text=re.sub(r'\s+xr:uid="[^"]*"','',text)
                for pane,cell in [('topRight','B1'),('bottomLeft','A7'),('bottomRight','B7')]:
                    text=re.sub(r'(<selection[^>]*pane="'+pane+r'"[^>]*activeCell=")[^"]*("[^>]*sqref=")[^"]*(")',lambda m:m.group(1)+cell+m.group(2)+cell+m.group(3),text)
                data=text.encode('utf-8')
            z.writestr(part,data)
print('Created two isolated diagnostic copies')
with ZipFile(tmp/'native-qa.xlsx') as generated:
    names={}
    for page in [1,2]:
        names[f'rfq{page}-sheet1.xml']=f'sheet{page}.xml'
        names[f'rfq{page}-drawing1.xml']=f'drawing{page}.xml'
        names[f'rfq{page}-vmlDrawing1.vml']=f'vmlDrawing{page}.vml'
        names[f'rfq{page}-printerSettings1.bin']=f'printerSettings{page}.bin'
        for i in range(1,10):names[f'rfq{page}-ctrlProp{i}.xml']=f'ctrlProp{(page-1)*9+i}.xml'
    with ZipFile(tmp/'native-standard-names.xlsx','w',ZIP_DEFLATED) as z:
        for part in generated.namelist():
            data=generated.read(part);newpart=part
            for old,new in names.items():newpart=newpart.replace(old,new)
            if part.endswith(('.xml','.rels','.vml')):
                text=data.decode('utf-8')
                for old,new in names.items():text=text.replace(old,new)
                data=text.encode('utf-8')
            z.writestr(newpart,data)
    clean='''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><bookViews><workbookView activeTab="0"/></bookViews><sheets><sheet name="1" sheetId="1" r:id="rIdRFQ1"/><sheet name="2" sheetId="2" r:id="rIdRFQ2"/></sheets><definedNames><definedName name="_xlnm.Print_Area" localSheetId="0">'1'!$A$1:$Z$45</definedName><definedName name="_xlnm.Print_Area" localSheetId="1">'2'!$A$1:$Z$45</definedName></definedNames><calcPr fullCalcOnLoad="1"/></workbook>'''
    with ZipFile(tmp/'native-clean-book.xlsx','w',ZIP_DEFLATED) as z:
        for part in generated.namelist():z.writestr(part,clean.encode('utf-8') if part=='xl/workbook.xml' else generated.read(part))
    for pages in [1,2]:
        app='''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Microsoft Excel</Application><HeadingPairs><vt:vector size="2" baseType="variant"><vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant><vt:variant><vt:i4>'''+str(pages)+'''</vt:i4></vt:variant></vt:vector></HeadingPairs><TitlesOfParts><vt:vector size="'''+str(pages)+'''" baseType="lpstr">'''+''.join(f'<vt:lpstr>{i}</vt:lpstr>' for i in range(1,pages+1))+'''</vt:vector></TitlesOfParts></Properties>'''
        workbook=clean
        if pages==1:
            workbook=workbook.replace('<sheet name="2" sheetId="2" r:id="rIdRFQ2"/>','')
            workbook=workbook.replace('<definedName name="_xlnm.Print_Area" localSheetId="1">\'2\'!$A$1:$Z$45</definedName>','')
        with ZipFile(tmp/f'native-app-{pages}.xlsx','w',ZIP_DEFLATED) as z:
            for part in generated.namelist():
                data=generated.read(part)
                if part=='xl/workbook.xml':data=workbook.encode('utf-8')
                if part=='docProps/app.xml':data=app.encode('utf-8')
                z.writestr(part,data)
