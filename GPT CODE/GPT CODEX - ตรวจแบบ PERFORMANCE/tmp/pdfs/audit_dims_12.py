import json
import re
from collections import defaultdict
from pathlib import Path

import pdfplumber


ROOT = Path(__file__).resolve().parent
PDF = Path(r"C:\Users\tawan.t\Downloads\12.pdf")
SOURCE = json.loads((ROOT / "12_analysis.json").read_text(encoding="utf-8"))


def part_code(text):
    compact = re.sub(r"\s+", "", text)
    match = re.search(r"(?<!\d)(\d{6,7})HK", compact)
    if not match:
        return None, None, None
    code = match.group(1)
    return code, int(code[:3]), int(code[3:])


def number(text):
    if re.fullmatch(r"\d+(?:\.\d+)?", text):
        return float(text)
    return None


results = []
with pdfplumber.open(PDF) as document:
    for index, page in enumerate(document.pages):
        page_no = index + 1
        code, expected_width, expected_length = part_code(SOURCE[index]["text"])
        words = page.extract_words(keep_blank_chars=False)
        numeric = [(number(word["text"]), word) for word in words]
        numeric = [(value, word) for value, word in numeric if value is not None and word["x0"] < 1980]

        long_values = [
            value for value, word in numeric
            if word.get("upright", True) and abs(word["top"] - 630.95) < 3
        ]
        cross_values = [
            value for value, word in numeric
            if word.get("upright", True)
            and abs(word["top"] - 1046.51) < 3
            and word["x0"] > 1000
        ]

        rows = defaultdict(list)
        for value, word in numeric:
            if not word.get("upright", True) or word["top"] >= 500:
                continue
            key = round(word["top"] / 3) * 3
            rows[key].append((value, word))

        chain_candidates = []
        for top, items in rows.items():
            if len(items) < 3:
                continue
            ordered = sorted(items, key=lambda item: item[1]["x0"])
            span = ordered[-1][1]["x1"] - ordered[0][1]["x0"]
            values = [item[0] for item in ordered]
            total = sum(values)
            if span > 300 and total > 150:
                chain_candidates.append(
                    {"top": top, "values": values, "sum": round(total, 3), "span": round(span, 1)}
                )

        chain_candidates.sort(key=lambda item: item["span"], reverse=True)
        main_chain = chain_candidates[0] if chain_candidates else None

        issues = []
        if expected_length is None or expected_width is None:
            issues.append("part_code_unreadable")
        else:
            if not long_values:
                issues.append("long_overall_missing")
            elif all(abs(value - expected_length) > 0.1 for value in long_values):
                issues.append("long_overall_mismatch")
            if not cross_values:
                issues.append("cross_width_missing")
            elif all(abs(value - expected_width) > 0.1 for value in cross_values):
                issues.append("cross_width_mismatch")
            if main_chain and abs(main_chain["sum"] - expected_length) > 0.11:
                issues.append("chain_sum_mismatch")

        results.append(
            {
                "drawing": page_no,
                "part_code": code,
                "expected_width": expected_width,
                "expected_length": expected_length,
                "long_values": long_values,
                "cross_values": cross_values,
                "main_chain": main_chain,
                "issues": issues,
            }
        )
        if page_no % 20 == 0:
            print(f"checked {page_no}", flush=True)

(ROOT / "12_dimension_audit.json").write_text(
    json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
)

print("issues")
for item in results:
    if item["issues"]:
        print(item)
