import json
import re
from collections import defaultdict
from pathlib import Path

import pdfplumber


PDF = Path(r"C:\Users\tawan.t\Downloads\12.pdf")
OUT = Path(__file__).resolve().parent / "12_validation.json"


def value_of(text):
    cleaned = text.replace(",", "")
    if re.fullmatch(r"\d+(?:\.\d+)?", cleaned):
        return float(cleaned)
    return None


records = []
with pdfplumber.open(PDF) as document:
    for page_no, page in enumerate(document.pages, 1):
        words = page.extract_words(keep_blank_chars=False)
        joined = "".join(word["text"] for word in words)
        code_match = re.search(r"(?<!\d)300(\d{3,4})HK", joined)
        drawing_match = re.search(r"PJ25-031-HK-MEP-PART-(\d{3})", joined)
        code_length = int(code_match.group(1)) if code_match else None
        drawing = int(drawing_match.group(1)) if drawing_match else None

        drawing_numbers = []
        rows = defaultdict(list)
        for word in words:
            value = value_of(word["text"])
            if value is None or word["x0"] >= 1980:
                continue
            drawing_numbers.append((value, word))
            if word.get("upright", True) and word["top"] < 700:
                key = round(word["top"] / 3) * 3
                rows[key].append((value, word))

        chain_rows = []
        for top, items in sorted(rows.items()):
            if len(items) < 2:
                continue
            x_span = max(item[1]["x1"] for item in items) - min(item[1]["x0"] for item in items)
            if x_span < 350:
                continue
            values = [item[0] for item in sorted(items, key=lambda item: item[1]["x0"])]
            chain_rows.append(
                {
                    "top": top,
                    "span": round(x_span, 1),
                    "values": values,
                    "sum": round(sum(values), 3),
                }
            )

        matching_chains = []
        if code_length is not None:
            matching_chains = [row for row in chain_rows if abs(row["sum"] - code_length) <= 0.11]

        overall_count = 0
        if code_length is not None:
            overall_count = sum(1 for value, _ in drawing_numbers if abs(value - code_length) <= 0.01)

        overlaps = []
        focus = [
            word for word in words
            if word["x0"] < 1980
            and (value_of(word["text"]) is not None or "Paint" in word["text"])
        ]
        for index, left in enumerate(focus):
            for right in focus[index + 1:]:
                x_overlap = min(left["x1"], right["x1"]) - max(left["x0"], right["x0"])
                y_overlap = min(left["bottom"], right["bottom"]) - max(left["top"], right["top"])
                if x_overlap > 1 and y_overlap > 1:
                    overlaps.append(
                        {
                            "left": left["text"],
                            "right": right["text"],
                            "x_overlap": round(x_overlap, 2),
                            "y_overlap": round(y_overlap, 2),
                        }
                    )

        records.append(
            {
                "pdf_page": page_no,
                "drawing": drawing,
                "code_length": code_length,
                "overall_count": overall_count,
                "chain_rows": chain_rows,
                "matching_chains": matching_chains,
                "text_overlaps": overlaps,
            }
        )

OUT.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")

print("pages", len(records))
print("mapping", [(item["pdf_page"], item["drawing"]) for item in records if item["drawing"] != item["pdf_page"]])
print("missing code", [item["drawing"] for item in records if item["code_length"] is None])
print("overall missing", [(item["drawing"], item["code_length"], item["overall_count"]) for item in records if item["overall_count"] < 1])
print("no matching chain", [(item["drawing"], item["code_length"], item["chain_rows"]) for item in records if not item["matching_chains"]])
print("text overlaps", [(item["drawing"], item["text_overlaps"]) for item in records if item["text_overlaps"]])
