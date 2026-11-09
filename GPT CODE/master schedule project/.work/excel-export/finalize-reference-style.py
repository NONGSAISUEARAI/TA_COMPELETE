from pathlib import Path
from copy import deepcopy
import json, zipfile, xml.etree.ElementTree as ET
p=Path(__file__).parent
root=p.parents[1]
ns={'m':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
pack=json.loads((p/'template.json').read_text(encoding='utf-8'))
with zipfile.ZipFile(root/'Program & Actual Drawing Schedul By Tawan 09-11-26.xlsx') as source:
    original=ET.fromstring(source.read('xl/styles.xml'))
    styles=ET.fromstring(pack['files']['xl/styles.xml'])
    fonts=styles.find('m:fonts',ns)
    fonts.remove(fonts[0]);fonts.insert(0,deepcopy(original.find('m:fonts',ns)[0]))
    ET.register_namespace('',ns['m'])
    pack['files']['xl/styles.xml']=ET.tostring(styles,encoding='unicode')
    pack['files']['xl/theme/theme1.xml']=source.read('xl/theme/theme1.xml').decode('utf-8-sig')
(p/'template.json').write_text(json.dumps(pack,ensure_ascii=False),encoding='utf-8')
print('Preserved reference Normal font and theme for native column sizing.')
