import json
import re
from collections import defaultdict
from pathlib import Path

import pdfplumber
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parent
PDF = Path(r"C:\Users\tawan.t\Downloads\merged (13).pdf")
OUT = ROOT / "merged13_analysis.json"


def numeric_value(text):
    cleaned = text.replace(",", "")
    if re.fullmatch(r"\d+(?:\.\d+)?", cleaned):
        return float(cleaned)
    return None


def parse_code(text):
    compact = re.sub(r"\s+", "", text)
    match = re.search(r"(?<!\d)(\d{6,7})HK", compact)
    if not match:
        return None, None, None
    code = match.group(1)
    return code, int(code[:3]), int(code[3:])


reader = PdfReader(str(PDF))
records = []

with pdfplumber.open(PDF) as document:
    for pdf_page, page in enumerate(document.pages, 1):
        pypdf_text = reader.pages[pdf_page - 1].extract_text() or ""
        compact = re.sub(r"\s+", "", pypdf_text)
        drawing_match = re.search(r"PJ25-031-HK-MEP-PART-(\d{3})", compact)
        drawing = int(drawing_match.group(1)) if drawing_match else None
        code, expected_width, expected_length = parse_code(pypdf_text)

        words = page.extract_words(keep_blank_chars=False)
        numbers = []
        for word in words:
            value = numeric_value(word["text"])
            if value is not None and word["x0"] < 1980:
                numbers.append((value, word))

        horizontal_rows = defaultdict(list)
        vertical_cols = defaultdict(list)
        for value, word in numbers:
            if word.get("upright", True) and word["top"] < 700:
                horizontal_rows[round(word["top"] / 3) * 3].append((value, word))
            elif not word.get("upright", True) and word["top"] < 500:
                vertical_cols[round(word["x0"] / 3) * 3].append((value, word))

        horizontal_chains = []
        for top, items in horizontal_rows.items():
            if len(items) < 3:
                continue
            ordered = sorted(items, key=lambda item: item[1]["x0"])
            span = ordered[-1][1]["x1"] - ordered[0][1]["x0"]
            values = [item[0] for item in ordered]
            total = sum(values)
            if span > 300 and total > 150:
                horizontal_chains.append(
                    {
                        "top": top,
                        "values": values,
                        "sum": round(total, 3),
                        "span": round(span, 1),
                    }
                )
        horizontal_chains.sort(key=lambda row: row["span"], reverse=True)

        vertical_chains = []
        for x0, items in vertical_cols.items():
            if len(items) < 3:
                continue
            ordered = sorted(items, key=lambda item: item[1]["top"])
            span = ordered[-1][1]["bottom"] - ordered[0][1]["top"]
            values = [item[0] for item in ordered]
            total = sum(values)
            if span > 80 and total > 50:
                vertical_chains.append(
                    {
                        "x0": x0,
                        "values": values,
                        "sum": round(total, 3),
                        "span": round(span, 1),
                    }
                )
        vertical_chains.sort(key=lambda row: row["span"], reverse=True)

        standalone_values = [value for value, _ in numbers]
        width_count = (
            sum(abs(value - expected_width) < 0.11 for value in standalone_values)
            if expected_width is not None
            else 0
        )
        length_count = (
            sum(abs(value - expected_length) < 0.11 for value in standalone_values)
            if expected_length is not None
            else 0
        )

        main_h = horizontal_chains[0] if horizontal_chains else None
        main_v = vertical_chains[0] if vertical_chains else None
        issues = []
        if drawing is None:
            issues.append("drawing_number_missing")
        if code is None:
            issues.append("part_code_missing")
        if expected_length is not None:
            if length_count < 2:
                issues.append("length_overall_missing_or_mismatch")
            if main_h and abs(main_h["sum"] - expected_length) > 0.11:
                issues.append("horizontal_chain_mismatch")
        if expected_width is not None:
            if width_count < 2:
                issues.append("width_overall_missing_or_mismatch")
            if main_v and abs(main_v["sum"] - expected_width) > 0.11:
                issues.append("vertical_chain_mismatch")

        records.append(
            {
                "pdf_page": pdf_page,
                "drawing": drawing,
                "part_code": code,
                "expected_width": expected_width,
                "expected_length": expected_length,
                "width_count": width_count,
                "length_count": length_count,
                "paint_count": len(re.findall(r"Paint", pypdf_text, flags=re.I)),
                "horizontal_chains": horizontal_chains,
                "vertical_chains": vertical_chains,
                "issues": issues,
                "text": pypdf_text,
            }
        )
        if pdf_page % 20 == 0:
            print(f"checked {pdf_page}", flush=True)

OUT.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")

print("pages", len(records))
print("mapping", [(r["pdf_page"], r["drawing"]) for r in records if r["pdf_page"] != r["drawing"]])
print("missing identifiers", [(r["pdf_page"], r["drawing"], r["part_code"]) for r in records if r["drawing"] is None or r["part_code"] is None])
print("suspects")
for record in records:
    if record["issues"]:
        print({k: record[k] for k in ["pdf_page", "drawing", "part_code", "expected_width", "expected_length", "width_count", "length_count", "horizontal_chains", "vertical_chains", "issues"]})
print("paint count unusual", [(r["drawing"], r["paint_count"]) for r in records if r["paint_count"] not in (6, 7)])
