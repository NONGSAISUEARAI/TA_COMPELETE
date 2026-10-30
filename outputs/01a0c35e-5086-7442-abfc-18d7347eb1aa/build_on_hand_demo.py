from pathlib import Path

from openpyxl import load_workbook
from openpyxl.workbook.properties import CalcProperties


source = Path(r"C:\Users\tawan.t\Downloads\Item_Category_FG_Full_Spill_Example.xlsx")
output = Path(r"C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE\outputs\01a0c35e-5086-7442-abfc-18d7347eb1aa\Item_Category_FG_On_Hand_Example.xlsx")

workbook = load_workbook(source)
sheet = workbook["Total On Hand"]
category_sheet = workbook["Item Category"]

for address in ("A1", "A2", "D1", "D2", "E2"):
    if sheet[address].value is not None:
        raise ValueError(f"Target cell is not empty: {address}")

formula = category_sheet["D255"].value
if not isinstance(formula, str) or "FILTER(" not in formula:
    raise ValueError("Expected source formula is missing")
formula = formula.replace("'Total On Hand'!", "").replace("$A255", "$A2")

sheet["A1"] = "Category prefix"
sheet["A2"] = "FG30503"
sheet["D1"] = "Matching item numbers →"
sheet["D2"] = formula
sheet.column_dimensions["A"].width = 19
sheet.column_dimensions["D"].width = 23
sheet.column_dimensions["E"].width = 23

if workbook.calculation is None:
    workbook.calculation = CalcProperties(calcMode="auto", fullCalcOnLoad=True, forceFullCalc=True)
else:
    workbook.calculation.fullCalcOnLoad = True
    workbook.calculation.forceFullCalc = True
workbook.save(output)

saved = load_workbook(output, data_only=False)
saved_sheet = saved["Total On Hand"]
if saved_sheet["A2"].value != "FG30503" or saved_sheet["D2"].value != formula:
    raise ValueError("Saved example does not match intended cells")
if saved_sheet["E2"].value is not None:
    raise ValueError("Spill destination is blocked")

matches = sorted({
    str(cell.value)
    for row in sheet.iter_rows(min_row=2, max_row=3506, min_col=3, max_col=3)
    for cell in row
    if cell.value is not None and str(cell.value).startswith("FG30503")
})
print("OUTPUT", output)
print("FORMULA", formula)
print("EXPECTED_MATCHES", matches)
