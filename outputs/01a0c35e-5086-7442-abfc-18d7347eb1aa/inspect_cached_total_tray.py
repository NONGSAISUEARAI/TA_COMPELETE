"""Count formula results available for a values-only recovery workbook."""

from collections import Counter
from pathlib import Path

from openpyxl import load_workbook


source = Path(__file__).resolve().parent / "TOTAL_TRAY_REV03_backup_2026-11-20.xlsm"
formulas = load_workbook(source, data_only=False, read_only=False)
values = load_workbook(source, data_only=True, read_only=False)

for formula_sheet, value_sheet in zip(formulas.worksheets, values.worksheets):
    counts = Counter()
    missing_examples = []
    for coordinate, cell in formula_sheet._cells.items():
        if cell.data_type == "f" or type(cell.value).__name__ == "ArrayFormula":
            counts["formulas"] += 1
            cached = value_sheet._cells.get(coordinate)
            if cached is None or cached.value is None:
                counts["missing_cached_result"] += 1
                counts["missing_" + type(cell.value).__name__] += 1
                if len(missing_examples) < 5:
                    missing_examples.append((cell.coordinate, str(cell.value)[:130]))
            elif cached.value == "":
                counts["empty_cached_result"] += 1
            else:
                counts["present_cached_result"] += 1
    print(formula_sheet.title, dict(counts), "missing_examples", missing_examples)

formulas.close()
values.close()
