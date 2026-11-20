from pathlib import Path

from pypdf import PdfReader
from pypdf.generic import ContentStream


SOURCE = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PANEL-PART-[001-004](1).pdf")


reader = PdfReader(SOURCE)


def inspect_stream(stream_object, resources, prefix):
    stream = ContentStream(stream_object, reader)
    for operands, operator in stream.operations:
        if operator == b"Tj":
            text = str(operands[0])
        elif operator == b"TJ":
            text = "".join(str(item) for item in operands[0] if isinstance(item, str))
        else:
            text = ""
        if "FINISH" in text.upper() or any(code in text for code in ("P0070", "05611", "E0114", "9103")):
            print(prefix, operator, repr(text), repr(operands))
        if operator == b"Do" and resources and "/XObject" in resources:
            name = operands[0]
            xobjects = resources["/XObject"].get_object()
            if name in xobjects:
                xobj = xobjects[name].get_object()
                if xobj.get("/Subtype") == "/Form":
                    inspect_stream(xobj, xobj.get("/Resources", resources), prefix + f"/{name}")


for page_number, page in enumerate(reader.pages, start=1):
    print(f"--- PAGE {page_number} ---")
    inspect_stream(page.get_contents(), page.get("/Resources"), f"p{page_number}")
