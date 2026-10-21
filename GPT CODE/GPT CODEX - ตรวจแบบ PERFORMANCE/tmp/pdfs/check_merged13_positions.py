import json
import re
from collections import Counter
from pathlib import Path

import pdfplumber


PDF = Path(r"C:\Users\tawan.t\Downloads\merged (13).pdf")
ANALYSIS = json.loads(Path(r"tmp/pdfs/merged13_analysis.json").read_text(encoding="utf-8"))


def value_of(text):
    text = text.replace(",", "")
    if re.fullmatch(r"\d+(?:\.\d+)?", text):
        return float(text)
    return None


results = []
with pdfplumber.open(PDF) as document:
    for record, page in zip(ANALYSIS, document.pages):
        length = record["expected_length"]
        width = record["expected_width"]
        matches_length = []
        matches_width = []
        for word in page.extract_words(keep_blank_chars=False):
            value = value_of(word["text"])
            if value is None or word["x0"] >= 1980:
                continue
            item = {
                "text": word["text"],
                "x0": round(word["x0"], 1),
                "top": round(word["top"], 1),
                "upright": word.get("upright", True),
            }
            if abs(value - length) < 0.11:
                matches_length.append(item)
            if abs(value - width) < 0.11:
                matches_width.append(item)
        results.append(
            {
                "drawing": record["drawing"],
                "length": length,
                "width": width,
                "length_words": matches_length,
                "width_words": matches_width,
            }
        )

Path(r"tmp/pdfs/merged13_positions.json").write_text(
    json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
)

print("length top patterns", Counter(tuple(round(x["top"] / 3) * 3 for x in r["length_words"]) for r in results))
print("length occurrence outliers", [(r["drawing"], r["length_words"]) for r in results if len(r["length_words"]) != 2])
print("width occurrence outliers", [(r["drawing"], r["width_words"]) for r in results if len(r["width_words"]) != 1])
