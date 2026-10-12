from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import DecodedStreamObject, DictionaryObject, NameObject

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\Users\tawan.t\Downloads\FL-PJ-26-031-HK-MEP-PART-[1-170].pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-HK-MEP-PART-001-170.pdf'
OLD = 'FL-PJ-26-031'
NEW = 'PJ25-031'


def glyph_literal(text):
    value = b''.join((ord(character) - 29).to_bytes(2, 'big') for character in text)
    value = value.replace(b'\\', b'\\\\').replace(b'(', b'\\(').replace(b')', b'\\)')
    return b'(' + value + b')'


def replacements(page):
    fonts = page['/Resources']['/Font']
    drafting_fonts = [name for name, ref in fonts.items() if 'Swiss721BT-Bold' in str(ref.get_object().get('/BaseFont'))]
    assert len(drafting_fonts) == 1, drafting_fonts
    restore = str(drafting_fonts[0]).encode('ascii') + b' 17.0264 Tf'
    changes = []
    for suffix in ['', '-HK-']:
        original = glyph_literal(OLD + suffix) + b'Tj'
        replacement = b'/CodexCode 17.0264 Tf\n(' + (NEW + suffix).encode('ascii') + b') Tj\n' + restore
        changes.append((original, replacement))
    return changes


reader = PdfReader(SOURCE)
assert len(reader.pages) == 170
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
font = DictionaryObject({
    NameObject('/Type'): NameObject('/Font'),
    NameObject('/Subtype'): NameObject('/Type1'),
    NameObject('/BaseFont'): NameObject('/Helvetica-Bold'),
    NameObject('/Encoding'): NameObject('/WinAnsiEncoding'),
})
font_ref = writer._add_object(font)

for index, page in enumerate(writer.pages):
    # Edit only the two known text operators. Keeping the surrounding content
    # bytes identical preserves every line, dimension, and other drafting label.
    original = page.get_contents().get_data()
    revised = original
    for old, new in replacements(page):
        assert revised.count(old) == 1, (index + 1, revised.count(old))
        revised = revised.replace(old, new)
    page['/Resources']['/Font'][NameObject('/CodexCode')] = font_ref
    content = DecodedStreamObject()
    content.set_data(revised)
    page[NameObject('/Contents')] = writer._add_object(content.flate_encode())
    if (index + 1) % 25 == 0 or index == 169:
        print(f'Updated {index + 1}/170 pages', flush=True)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
with OUTPUT.open('wb') as output:
    writer.write(output)
print('Saved; checking all pages and signature appearances', flush=True)

result = PdfReader(OUTPUT)
assert len(result.pages) == 170
for index, (original, revised) in enumerate(zip(reader.pages, result.pages)):
    assert list(original.mediabox) == list(revised.mediabox)
    assert list(original.cropbox) == list(revised.cropbox)
    assert original.rotation == revised.rotation
    data = revised.get_contents().get_data()
    restored = data
    for old, new in replacements(original):
        assert data.count(new) == 1, index + 1
        restored = restored.replace(new, old)
    assert restored == original.get_contents().get_data(), index + 1
    assert glyph_literal(OLD)[1:-1] not in data, index + 1
    source_annotations = original.get('/Annots', [])
    output_annotations = revised.get('/Annots', [])
    assert len(source_annotations) == len(output_annotations)
    for a, b in zip(source_annotations, output_annotations):
        a, b = a.get_object(), b.get_object()
        assert a.get('/T') == b.get('/T') and list(a['/Rect']) == list(b['/Rect'])
        assert a['/AP']['/N'].get_object().get_data() == b['/AP']['/N'].get_object().get_data()
    if (index + 1) % 25 == 0 or index == 169:
        print(f'Verified {index + 1}/170 pages', flush=True)
print('340 code changes verified; remaining page content identical; signature positions and appearances preserved.', flush=True)
print(f'Output: {OUTPUT}', flush=True)
print(f'Size: {OUTPUT.stat().st_size / 1024**2:.2f} MB', flush=True)
