from pathlib import Path
import base64,json,subprocess,hashlib
from pypdf import PdfReader
from PIL import Image

root=Path(__file__).resolve().parents[2]
source=next((root/'เรียนรู้การทำถาดไฟ/outputs/rfq_26106_height17_ready').glob('*.pdf'))
runtime=Path(r'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1119-907-0_26.1119.907.0_x64__3k8sg7r9htsxt\dependencies')
out=root/'outputs/pdf26106-html';out.mkdir(parents=True,exist_ok=True)
reader=PdfReader(source)
assert len(reader.pages)==2
for page in reader.pages:
    assert float(page.mediabox.width)==792 and float(page.mediabox.height)==612
subprocess.run([str(runtime/'native/poppler/Library/bin/pdftoppm.exe'),'-png','-r','216',str(source),str(out/'page')],check=True,capture_output=True)
images=sorted(out.glob('page-*.png'))
assert len(images)==2
b64=lambda value:base64.b64encode(value).decode('ascii')
module=runtime/'node/node_modules/pdfjs-dist/build/pdf.min.mjs'
worker=runtime/'node/node_modules/pdfjs-dist/build/pdf.worker.min.mjs'
assets={'module':b64(module.read_bytes()),'worker':b64(worker.read_bytes()),'pdf':b64(source.read_bytes())}
text=Path(__file__).with_name('pdf_viewer_template.html').read_text(encoding='utf-8')
for i,image in enumerate(images,1):
    with Image.open(image) as picture:
        assert picture.size==(2376,1836),picture.size
    text=text.replace(f'__PAGE{i}_IMAGE__','data:image/png;base64,'+b64(image.read_bytes()))
text=text.replace('__ASSET_JSON__',json.dumps(assets,separators=(',',':')))
assert '__PAGE' not in text and '__ASSET' not in text
output=out/'BU2-DE-26106-from-PDF.html';output.write_text(text,encoding='utf-8')
print(json.dumps({'pages':2,'pdf_points':[792,612],'ratio':'22:17','fallback_pixels':[2376,1836],'html_bytes':output.stat().st_size,'pdf_sha256':hashlib.sha256(source.read_bytes()).hexdigest()},indent=2))
