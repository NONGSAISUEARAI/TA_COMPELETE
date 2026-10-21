from pathlib import Path

import pdfplumber


PDF = Path(r"C:\Users\tawan.t\Downloads\merged (13).pdf")

records = []
with pdfplumber.open(PDF) as document:
    for drawing, page in enumerate(document.pages, 1):
        outline_candidates = []
        for line in page.lines:
            top = page.height - max(line.get("y0", 0), line.get("y1", 0))
            length = line.get("x1", 0) - line.get("x0", 0)
            if 805 <= top <= 813 and length > 100 and line.get("x1", 0) < 1980:
                outline_candidates.append(line)
        outline = max(outline_candidates, key=lambda line: line["x1"] - line["x0"])

        paints = [
            word
            for word in page.extract_words(keep_blank_chars=False)
            if word["text"] == "Paint" and 790 <= word["top"] <= 860 and word["x0"] < 1980
        ]
        paints.sort(key=lambda word: word["x0"])
        if not paints:
            records.append((drawing, None, None, round(outline["x0"], 1), round(outline["x1"], 1)))
            continue
        left = paints[0]
        right = paints[-1]
        left_gap = outline["x0"] - left["x1"]
        right_gap = right["x0"] - outline["x1"]
        records.append((drawing, round(left_gap, 1), round(right_gap, 1), round(outline["x0"], 1), round(outline["x1"], 1)))

print("missing", [record for record in records if record[1] is None])
present = [record for record in records if record[1] is not None]
print("detached", [record for record in present if record[1] > 50 or record[2] > 50])
print("largest gaps", sorted(present, key=lambda record: max(record[1], record[2]), reverse=True)[:30])
