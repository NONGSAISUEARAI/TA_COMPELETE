from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ContentStream, DecodedStreamObject, DictionaryObject, NameObject, TextStringObject

ROOT = Path(__file__).resolve().parent
SOURCE = Path(r'C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\PJ25-031-ALU-PANEL-PART-001-004.pdf')
OUTPUT = ROOT.parents[2] / 'output' / 'pdf' / 'PJ25-031-ALU-PANEL-PART-001-004_FINISH-UPDATED.pdf'
OLD = ['NS-1S-P0070', 'SA-05611 (THAI PAINT)', 'NS-1S-E0114 (CORNEL)', 'SD-9103']
NEW = ['PA-1M-U0139', 'PA-1S-G0309', 'PA-1S-E0116', 'PA-2S-W0803']

reader = PdfReader(SOURCE)
assert len(reader.pages) == 4
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.pdf_header = reader.pdf_header
finish_font = writer._add_object(DictionaryObject({
    NameObject('/Type'): NameObject('/Font'),
    NameObject('/Subtype'): NameObject('/Type1'),
    NameObject('/BaseFont'): NameObject('/Helvetica-Bold'),
    NameObject('/Encoding'): NameObject('/WinAnsiEncoding'),
}))
for index, page in enumerate(writer.pages):
    content = ContentStream(page.get_contents(), writer)
    count = 0
    operations = []
    active_font = None
    for operands, operator in content.operations:
        if operator == b'Tf':
            active_font = list(operands)
        if operator != b'Tj':
            operations.append((operands, operator))
            continue
        decoded = ''.join(chr(ord(c) + 29) for c in str(operands[0]))
        if decoded == OLD[index]:
            operations.extend([
                ([NameObject('/FinishCode'), active_font[1]], b'Tf'),
                ([TextStringObject(NEW[index])], b'Tj'),
                (active_font, b'Tf'),
            ])
            count += 1
        else:
            operations.append((operands, operator))
    assert count == 1, (index + 1, count)
    content.operations = operations
    page['/Resources']['/Font'][NameObject('/FinishCode')] = finish_font
    replacement = DecodedStreamObject()
    replacement.set_data(content.get_data())
    page[NameObject('/Contents')] = writer._add_object(replacement.flate_encode())

with OUTPUT.open('wb') as output:
    writer.write(output)
result = PdfReader(OUTPUT)
assert len(result.pages) == 4
for a, b in zip(reader.pages, result.pages):
    assert list(a.mediabox) == list(b.mediabox) and a.rotation == b.rotation
    assert len(a.get('/Annots', [])) == len(b.get('/Annots', []))
with pdfplumber.open(SOURCE) as before, pdfplumber.open(OUTPUT) as after:
    for index, (a, b) in enumerate(zip(before.pages, after.pages)):
        original, edited = a.extract_text(), b.extract_text()
        expected = original.replace(OLD[index], NEW[index])
        assert re.sub(r'\s+', '', expected) == re.sub(r'\s+', '', edited), index + 1
        assert edited.count(NEW[index]) == 1
        print(f'Page {index + 1}: FINISH {NEW[index]}; all other text retained')
print(OUTPUT)
