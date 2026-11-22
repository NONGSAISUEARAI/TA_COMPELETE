from pathlib import Path
import re
root=Path(__file__).resolve().parents[2]
target=root/'outputs/rfq_26106_from_template/BU2-DE-26106.html'
html=target.read_text(encoding='utf-8')
start=html.index('// Standalone PDF export.')
end=html.index('\nsyncFileName();',start)
html=html[:start]+Path(__file__).with_name('direct_pdf_export.js').read_text(encoding='utf-8')+html[end:]
target.write_text(html,encoding='utf-8')
script=re.search(r'<script>\s*(const model=.*?)</script>',html,re.S).group(1)
Path(__file__).with_name('direct_pdf_check.js').write_text(script,encoding='utf-8')
print('Updated embedded PDF export')
