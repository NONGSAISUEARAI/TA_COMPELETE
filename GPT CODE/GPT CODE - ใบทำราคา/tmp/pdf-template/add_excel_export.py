from pathlib import Path
import base64,hashlib,re,shutil,json

root=Path(__file__).resolve().parents[2]
excel=root/'ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx'
runtime=Path('C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1119-907-0_26.1119.907.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules')
library=(runtime/'jszip/dist/jszip.min.js').read_text(encoding='utf-8')
license=(runtime/'jszip/LICENSE.markdown').read_text(encoding='utf-8')
library=re.sub(r'//# sourceMappingURL=[^\r\n]*','',library).replace('</script','<\\/script')
payload=base64.b64encode(excel.read_bytes()).decode('ascii')
digest=hashlib.sha256(excel.read_bytes()).hexdigest()
script=Path(__file__).with_name('excel_export.js').read_text(encoding='utf-8')
master=root/'ฟอร์มกลาง/BU2-DE-26xxx-MASTER.html'
work=root/'outputs/rfq_26106_from_template/BU2-DE-26106.html'
for path in [master,work]:
    text=path.read_text(encoding='utf-8')
    backup=path.parent/'history'/f'{path.stem}-before-excel-export.html'
    if 'id="excel-export-library"' not in text:
        backup.parent.mkdir(exist_ok=True)
        if backup.exists():raise FileExistsError(backup)
        shutil.copy2(path,backup)
        text=text.replace('<button type="button" id="save-pdf">','<button type="button" id="save-excel">ดาวน์โหลด Excel</button><button type="button" id="save-pdf">',1)
        package=f'\n<!-- JSZip: embedded for offline Excel export.\n{license}\n-->\n<script id="excel-export-library">\n{library}\n</script>\n<script id="excel-template-data" type="application/octet-stream" data-filename="{excel.name}" data-sha256="{digest}">{payload}</script>\n'
        text=text.replace('<script id="pdf-export-library">',package+'<script id="pdf-export-library">',1)
        text=text.replace('</body>',f'<script id="rfq-excel-export">\n{script}\n</script>\n</body>',1)
        text=text.replace('(?:html?|pdf)$/i','(?:html?|pdf|xlsx)$/i')
        needle="saved.querySelector('#pages').replaceChildren();"
        assert needle in text
        text=text.replace(needle,"saved.querySelectorAll('#save-pdf,#save-excel').forEach(button=>{button.disabled=false;button.removeAttribute('aria-busy');});saved.querySelector('#file-save-status').textContent='';\n  "+needle,1)
    else:
        text=re.sub(r'(<script id="rfq-excel-export">).*?(</script>)',lambda m:m.group(1)+'\n'+script+'\n'+m.group(2),text,flags=re.S,count=1)
    assert text.count('id="save-excel"')==1 and text.count('id="excel-export-library"')==1
    path.write_text(text,encoding='utf-8')
    print(json.dumps({'file':str(path),'bytes':path.stat().st_size},ensure_ascii=True))
shutil.copy2(master,root/'skills/rfq-html/assets/BU2-DE-26xxx-MASTER.html')
assert hashlib.sha256(excel.read_bytes()).hexdigest()==digest
print('Source XLSX unchanged; master, work document and portable skill asset updated')
