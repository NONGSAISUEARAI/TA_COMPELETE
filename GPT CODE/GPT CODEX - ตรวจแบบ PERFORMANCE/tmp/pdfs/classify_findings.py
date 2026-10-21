import json
from collections import defaultdict
from pathlib import Path


root = Path(__file__).resolve().parent
records = json.loads((root / "merged10_ink_components.json").read_text(encoding="utf-8"))

special = {
    1: 1,
    3: 2,
    4: 3,
    5: 8,
    6: 9,
    7: 10,
    8: 11,
    9: 4,
    10: 5,
    11: 6,
    12: 7,
    13: 13,
    14: 12,
}


def drawing_number(record):
    page = record["pdf_page"]
    if page == 2:
        return None
    if page in special:
        return special[page]
    return page - 1


def ranges(numbers):
    numbers = sorted(set(numbers))
    result = []
    if not numbers:
        return result
    start = previous = numbers[0]
    for number in numbers[1:]:
        if number != previous + 1:
            result.append((start, previous))
            start = number
        previous = number
    result.append((start, previous))
    return result


categories = defaultdict(list)
page_categories = {}
for record in records:
    drawing = drawing_number(record)
    if drawing is None:
        continue
    totals = defaultdict(int)
    for component in record["components"]:
        x1, y1, x2, y2 = component["bbox_raw"]
        x = (x1 + x2) / 2
        y = (y1 + y2) / 2
        pixels = component["pixels"]
        if x >= 560 and 500 <= y < 720:
            category = "cross_section_dim"
        elif 380 <= x < 560 and 450 <= y < 700:
            category = "long_section_dim"
        elif x < 380 and y >= 650:
            category = "plan_chain_dim"
        elif 380 <= x < 560 and y >= 700:
            category = "overall_length_dim"
        else:
            category = "other"
        totals[category] += pixels
    present = sorted(category for category, total in totals.items() if total >= 18)
    page_categories[drawing] = {category: totals[category] for category in present}
    for category in present:
        categories[category].append(drawing)

for category, numbers in categories.items():
    formatted = [f"{start:03d}" if start == end else f"{start:03d}-{end:03d}" for start, end in ranges(numbers)]
    print(category, ", ".join(formatted))

(root / "merged10_classified_findings.json").write_text(
    json.dumps(page_categories, ensure_ascii=False, indent=2), encoding="utf-8"
)
