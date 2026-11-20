from pathlib import Path

import pdfplumber


SOURCE = Path(r"C:\TA\PPLINE CKST\C1-C2_Finishes-Reflected Ceiling Plan\PP-LINE_CL-PART\SOLID C06\FL-PJ-26-031-ALU-PANEL-PART-[001-004](1).pdf")


with pdfplumber.open(SOURCE) as pdf:
    for page_number, page in enumerate(pdf.pages, start=1):
        words = page.extract_words(extra_attrs=["fontname", "size"])
        print(f"--- PAGE {page_number} {page.width}x{page.height} ---")
        for word in words:
            if (
                word["text"].upper().startswith("FINISH")
                or any(code in word["text"] for code in ("P0070", "05611", "E0114", "9103"))
            ):
                print(word)
