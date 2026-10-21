import json
import re
from pathlib import Path


root = Path(__file__).resolve().parent
rows = [json.loads(line) for line in (root / "merged10_ocr.ndjson").read_text(encoding="utf-8").splitlines()]


def words(row):
    result = []
    for line in row["tsv"].splitlines():
        parts = line.split("\t")
        if len(parts) < 12 or parts[0] != "5":
            continue
        result.append(
            {
                "text": parts[11].strip(),
                "x": int(parts[6]),
                "y": int(parts[7]),
                "w": int(parts[8]),
                "h": int(parts[9]),
                "conf": float(parts[10]),
            }
        )
    return result


def region_text(items, x1, y1, x2, y2):
    found = [item for item in items if x1 <= item["x"] <= x2 and y1 <= item["y"] <= y2 and item["text"]]
    found.sort(key=lambda item: (item["y"] // 12, item["x"]))
    return " ".join(item["text"] for item in found)


records = []
for row in rows:
    items = words(row)
    title = region_text(items, 2200, 1650, 2500, 1800)
    full = row["text"]
    drawing_match = re.search(r"MEP[- ]?PART[- ]?(\d{3})", title, re.I)
    if not drawing_match:
        drawing_match = re.search(r"MEP[- ]?PART[- ]?(\d{3})", full, re.I)
    drawing = drawing_match.group(1) if drawing_match else None

    part_region = region_text(items, 2300, 590, 2630, 690)
    part_match = re.search(r"300\s*([0-9]{2,4})\s*HK", part_region.replace("O", "0"), re.I)
    if not part_match:
        part_match = re.search(r"300\s*([0-9]{2,4})\s*HK", full.replace("O", "0"), re.I)
    part_length = int(part_match.group(1)) if part_match else None

    bands = {}
    for name, y1, y2 in [
        ("top", 160, 285),
        ("middle", 710, 840),
        ("section", 1160, 1300),
        ("lower", 1320, 1460),
    ]:
        selected = [
            item
            for item in items
            if 250 <= item["x"] <= 2200
            and y1 <= item["y"] <= y2
            and re.search(r"\d", item["text"])
            and item["conf"] >= 10
        ]
        selected.sort(key=lambda item: (item["y"], item["x"]))
        bands[name] = [f'{item["text"]}@{item["x"]},{item["y"]}' for item in selected]

    records.append(
        {
            "pdf_page": row["page"],
            "drawing": drawing,
            "title": title,
            "part_region": part_region,
            "part_length": part_length,
            **bands,
        }
    )

(root / "merged10_analysis.json").write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
for record in records:
    print(
        f'{record["pdf_page"]:03d}',
        record["drawing"] or "---",
        record["part_length"] or "----",
        "TOP", ",".join(record["top"]),
        "MID", ",".join(record["middle"]),
    )
