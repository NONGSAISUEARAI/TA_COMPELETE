Attribute VB_Name = "Test_CUTTING_LIST"
Option Explicit

Private checks As Long
Private failures As Long
Private log As String
Private scenario As String

Public Function RunCuttingListTests() As String
    Dim ws As Worksheet
    On Error GoTo UnexpectedError
    checks = 0: failures = 0: log = ""
    Set ws = ThisWorkbook.Worksheets(1)
    TestSummaryLayout ws
    TestDynamicItems ws
    TestExample ws
    TestGroupsAndMaterials ws
    TestInputsAndErrors ws
    TestKerfAndRemainders ws
    TestDynamicSpill ws
    TestRandomConservation ws
    If failures = 0 Then
        RunCuttingListTests = "PASS: " & checks & " assertions across dynamic Item cells/report width, six tail columns, summary reconciliation, grouping, limits, spill/recalculation and 40 randomized cases"
    Else
        RunCuttingListTests = "FAIL: " & failures & "/" & checks & log
    End If
    Exit Function
UnexpectedError:
    RunCuttingListTests = "FAIL: error " & Err.Number & " in " & scenario & ": " & Err.Description & log
End Function

Private Sub TestSummaryLayout(ByVal ws As Worksheet)
    Dim actual As Variant, again As Variant, row As Long, key As Long
    Dim qty As Long, cutLength As Double
    scenario = "PACK_SUMMARY style report with unchanged arguments"
    Example ws
    actual = CUTTING_LIST(ws.Range("A1:E5"), 6000, 3, 10, 10, 300, True)
    If Not Shape(actual, 34, 15) Then Exit Sub
    Equal actual(1, 1), "SUMMARY REPORT", "summary title"
    Equal actual(2, 2), 18000, "summary stock"
    Equal actual(3, 2), 16400, "summary cut length"
    Equal actual(4, 2), 16400, "summary required length"
    Equal actual(5, 2), 3, "summary bars"
    Equal actual(6, 2), 8, "summary source qty"
    Equal actual(7, 2), 8, "summary used qty"
    Equal actual(8, 2), "", "zero remaining is blank"
    Equal actual(9, 2), 24, "summary kerf"
    Equal actual(10, 2), 60, "summary trim"
    Equal actual(11, 2), 1516, "summary gap"
    Equal actual(12, 2), 8.42, "summary percent is 0 to 100"
    Equal actual(13, 2), 1516, "summary reusable"
    Equal actual(14, 2), "", "summary zero scrap blank"
    Equal actual(16, 1), "Target used list", "target section"
    Equal actual(17, 3), "Target (mm)", "target heading"
    Equal actual(18, 2), "MIXED", "pooled group label"
    Equal actual(18, 4), 2, "first material stock bars"
    Equal actual(18, 5), 12000, "first material stock total"
    Equal actual(18, 6), 10800, "first material cut total"
    Equal actual(18, 9), 1142, "first material gap"
    Equal actual(18, 10), 9.52, "first material gap percent"
    Equal actual(19, 4), 1, "second material stock bars"
    Equal actual(21, 1), "Item used list", "item section"
    Equal actual(22, 6), "Remaining", "item compare heading"
    For row = 23 To 28
        Equal actual(row, 4), actual(row, 5), "item source used qty"
        Equal actual(row, 6), "", "item zero remaining blank"
        Equal actual(row, 7), actual(row, 8), "item length reconciliation"
        qty = qty + CLng(actual(row, 4))
        cutLength = cutLength + CDbl(actual(row, 7))
    Next row
    Equal qty, actual(6, 2), "item qty reconciles summary"
    Equal cutLength, actual(4, 2), "item lengths reconcile summary"
    Equal actual(30, 1), "CUTTING PLAN", "plan section"
    Equal actual(31, 14), "Used (%)", "plan percentage heading"
    Equal actual(32, 14), 90, "numeric utilization percentage"
    Equal actual(31, 5), "Item1", "first item heading"
    Equal actual(31, 7), "Item3", "last item heading"
    Equal actual(32, 5), 2200, "first numeric cut"
    Equal actual(32, 6), 1600, "second numeric cut"
    Equal actual(32, 7), 1600, "repeated cut in separate cell"
    Equal actual(32, 2), "MIXED", "bar group trace label"
    Equal actual(34, 7), "", "shorter bar item padding is blank"
    CheckItemCells actual, 31
    Equal actual(15, 12), "", "empty report cells stay blank"
    again = CUTTING_LIST(ws.Range("A1:E5"), 6000, 3, 10, 10, 300, True)
    For row = 1 To UBound(actual, 1)
        For key = 1 To UBound(actual, 2)
            Equal again(row, key), actual(row, key), "deterministic report"
        Next key
    Next row

    scenario = "empty report and zero allowances"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2").Value2 = 1000: ws.Range("B2").Value2 = 0
    actual = CUTTING_LIST(ws.Range("A1:B2"), 6000, 0)
    If Shape(actual, 23, 13) Then
        Equal actual(2, 2), "", "no stock blank"
        Equal actual(16, 1), "Target used list", "empty target section"
        Equal actual(19, 1), "Item used list", "empty item section"
        Equal actual(22, 1), "CUTTING PLAN", "empty plan section"
        Equal actual(23, 5), "Item1", "empty plan has one item heading"
        Equal actual(23, 13), "Remnant", "empty plan retains tail columns"
    End If
    ws.Range("B2").Value2 = 2
    ws.Range("A3").Value2 = 1000: ws.Range("B3").Value2 = 1
    actual = CUTTING_LIST(ws.Range("A1:B3"), 6000, 0, 0, 0, 5000)
    If Shape(actual, 26, 15) Then
        Equal actual(9, 2), "", "zero kerf blank in summary"
        Equal actual(10, 2), "", "zero trim blank in summary"
        Equal actual(13, 2), "", "no reusable blank"
        Equal actual(14, 2), 3000, "scrap summary"
        Equal actual(22, 4), 3, "duplicate demand lengths aggregate"
        Equal actual(22, 5), 3, "duplicate demand actually cut"
        Equal actual(26, 11), 0, "numeric zero kerf retained in plan"
    End If
End Sub

Private Sub TestDynamicItems(ByVal ws As Worksheet)
    Dim actual As Variant, col As Long
    scenario = "more than forty numeric item columns and shrinking width"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2").Value2 = 10: ws.Range("B2").Value2 = 50
    actual = CUTTING_LIST(ws.Range("A1:B2"), 1000, 0)
    If Shape(actual, 26, 62) Then
        Equal actual(25, 54), "Item50", "no fixed forty item limit"
        For col = 5 To 54
            Equal actual(26, col), 10, "one piece per numeric cell"
        Next col
        Equal actual(26, 56), 50, "fifty pieces"
        Equal actual(26, 57), 500, "sum of fifty item cells"
        Equal actual(26, 60), 500, "remainder with fifty items"
        CheckItemCells actual, 25
    End If
    ws.Range("B2").Value2 = 10
    actual = CUTTING_LIST(ws.Range("A1:B2"), 1000, 0)
    If Shape(actual, 26, 22) Then
        Equal actual(25, 14), "Item10", "width shrinks to actual max"
        Equal actual(25, 17), "Cut total (mm)", "tail follows last item"
        CheckItemCells actual, 25
    End If

    scenario = "unequal pieces per bar, six tail columns and single group"
    ws.Range("A2").Value2 = 2000: ws.Range("B2").Value2 = 4
    actual = CUTTING_LIST(ws.Range("A1:B2"), 6000, 0)
    If Shape(actual, 27, 15) Then
        Equal actual(26, 9), 3, "first bar has three items"
        Equal actual(27, 9), 1, "second bar has one item"
        Equal actual(27, 6), "", "Item2 blank in shorter bar"
        Equal actual(27, 7), "", "Item3 blank in shorter bar"
        Equal actual(26, 2), "", "ungrouped bar label blank"
        Equal actual(26, 10), 6000, "cut total tail"
        Equal actual(26, 11), 0, "kerf tail"
        Equal actual(26, 12), 0, "trim tail"
        Equal actual(26, 13), 0, "remainder tail"
        Equal actual(26, 14), 100, "used percent tail"
        Equal actual(26, 15), "NONE", "remnant tail"
        CheckItemCells actual, 25
    End If
    Reset ws
    ws.Range("B1").Value2 = "P17"
    ws.Range("B2").Value2 = "M1"
    ws.Range("A3").Value2 = 1000: ws.Range("B3").Value2 = 2
    actual = CUTTING_LIST(ws.Range("A1:B3"), 6000, 3, 10, 10, 4000)
    If Shape(actual, 26, 14) Then
        Equal actual(26, 2), "P17", "single group label"
        Equal actual(26, 12), 3974, "remainder after kerfs and trims"
        Equal actual(26, 14), "SCRAP", "remnant classification retained"
    End If

    scenario = "dynamic width and total result cell limits"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2").Value2 = 1: ws.Range("B2").Value2 = 16373
    ErrorCode CUTTING_LIST(ws.Range("A1:B2"), 1000000, 0), 2036, "too many Item columns for Excel"
    ws.Range("A2").Value2 = 6000: ws.Range("B2").Value2 = 1500
    ws.Range("A3").Value2 = 1: ws.Range("B3").Value2 = 1500
    ErrorCode CUTTING_LIST(ws.Range("A1:B3"), 6000, 0), 2036, "wide report memory guard"
End Sub

Private Sub CheckItemCells(ByVal report As Variant, ByVal headerRow As Long)
    Dim lastCol As Long, maxItems As Long, suffix As Long, row As Long, col As Long
    Dim count As Long, total As Double, expectedCount As Long, heads As Variant
    lastCol = UBound(report, 2)
    maxItems = lastCol - 12
    suffix = maxItems + 5
    Equal report(headerRow, 1), "Material", "plan material heading"
    Equal report(headerRow, 2), "Group", "plan group heading"
    Equal report(headerRow, 3), "Bar", "plan bar heading"
    Equal report(headerRow, 4), "Stock (mm)", "plan stock heading"
    For col = 1 To maxItems
        Equal report(headerRow, col + 4), "Item" & col, "sequential Item heading"
    Next col
    heads = Array("Cut total (mm)", "Kerf loss (mm)", "Trim loss (mm)", _
        "Remainder (mm)", "Used (%)", "Remnant")
    For col = 0 To 5
        Equal report(headerRow, lastCol - 5 + col), heads(col), "six tail headings"
    Next col
    For row = headerRow + 1 To UBound(report, 1)
        count = 0: total = 0
        expectedCount = CLng(report(row, suffix + 1))
        For col = 1 To maxItems
            If col <= expectedCount Then
                Check VarType(report(row, col + 4)) = vbDouble, "Item is numeric Double, not text"
                Check CDbl(report(row, col + 4)) > 0, "positive cut length"
                count = count + 1
                total = total + CDbl(report(row, col + 4))
            Else
                Equal report(row, col + 4), "", "unused Item cell blank"
            End If
        Next col
        Equal count, expectedCount, "numeric item count equals Pieces"
        Equal total, report(row, lastCol - 5), "SUM of numeric Items equals Cut total"
        Equal report(row, 4), total + CDbl(report(row, lastCol - 4)) _
            + CDbl(report(row, lastCol - 3)) + CDbl(report(row, lastCol - 2)), "item cells reconcile stock"
    Next row
End Sub

Private Function Plan(ByVal source As Range, ByVal stock As Double, ByVal kerf As Double, _
    Optional ByVal trimStart As Double = 0, Optional ByVal trimEnd As Double = 0, _
    Optional ByVal minReusable As Double = 0, Optional ByVal mixGroups As Boolean = False) As Variant
    Dim report As Variant, result() As Variant, firstRow As Long, r As Long, c As Long
    Dim suffix As Long
    report = CUTTING_LIST(source, stock, kerf, trimStart, trimEnd, minReusable, mixGroups)
    If IsError(report) Then
        Plan = report
        Exit Function
    End If
    For r = 1 To UBound(report, 1)
        If CStr(report(r, 1)) = "CUTTING PLAN" Then
            firstRow = r + 1
            Exit For
        End If
    Next r
    If firstRow = 0 Then Err.Raise 5, , "Missing CUTTING PLAN section"
    CheckItemCells report, firstRow
    suffix = UBound(report, 2) - 7
    ReDim result(1 To UBound(report, 1) - firstRow + 1, 1 To 12)
    For r = firstRow To UBound(report, 1)
        'Normalize numeric plan columns for the existing independent demand checks.
        result(r - firstRow + 1, 1) = report(r, 1)
        result(r - firstRow + 1, 2) = report(r, 3)
        result(r - firstRow + 1, 3) = ""
        result(r - firstRow + 1, 4) = report(r, suffix)
        result(r - firstRow + 1, 5) = report(r, suffix + 1)
        result(r - firstRow + 1, 6) = report(r, 4)
        For c = 7 To 12
            result(r - firstRow + 1, c) = report(r, suffix + c - 5)
        Next c
    Next r
    Plan = result
End Function

Private Sub TestExample(ByVal ws As Worksheet)
    Dim actual As Variant
    scenario = "guide example and alternative packing"
    Example ws
    actual = Plan(ws.Range("A1:E5"), 6000, 3, 10, 10, 300, True)
    If Not Shape(actual, 4, 12) Then Exit Sub
    Equal actual(1, 1), "Material", "header"
    Equal actual(1, 12), "Remnant", "last header"
    Equal SumColumn(actual, 5), 8, "pieces"
    Equal SumColumn(actual, 7), 16400, "cut length"
    Equal SumColumn(actual, 8), 24, "kerfs"
    Equal SumColumn(actual, 9), 60, "trims"
    Equal SumColumn(actual, 10), 1516, "remainder"
    CheckBalance actual
    CompareDemand ws.Range("A1:E5"), actual
    Check InStr(1, CStr(actual(2, 4)), "P17", vbTextCompare) > 0, "group trace retained"
    Check InStr(1, CStr(actual(2, 4)), "P18", vbTextCompare) > 0, "mixed group trace retained"
    Equal ws.Range("B3").Value2, 3, "source unchanged"
End Sub

Private Sub TestGroupsAndMaterials(ByVal ws As Worksheet)
    Dim actual As Variant
    scenario = "separate groups and distinct materials"
    Reset ws
    ws.Range("B1").Value2 = "P17": ws.Range("C1").Value2 = "P18"
    ws.Range("B2:C2").Value2 = "SAME"
    ws.Range("A3").Value2 = 2000: ws.Range("B3:C3").Value2 = 1
    actual = Plan(ws.Range("A1:C3"), 6000, 0)
    If Shape(actual, 3, 12) Then
        Equal actual(2, 2), 1, "first group bar"
        Equal actual(3, 2), 1, "second group bar resets"
    End If
    actual = Plan(ws.Range("A1:C3"), 6000, 0, 0, 0, 0, True)
    Shape actual, 2, 12
    ws.Range("C2").Value2 = "OTHER"
    actual = Plan(ws.Range("A1:C3"), 6000, 0, 0, 0, 0, True)
    Shape actual, 3, 12

    scenario = "merged group, case insensitive code, source offset"
    ws.Range("B1:C1").Merge
    ws.Range("B2").Value2 = "same": ws.Range("C2").Value2 = "SAME"
    actual = Plan(ws.Range("A1:C3"), 6000, 0)
    If Shape(actual, 2, 12) Then Equal actual(2, 5), 2, "merged header pool"
    ws.Range("B1:C1").UnMerge
    ws.Range("A1:C3").Copy Destination:=ws.Range("F8")
    actual = Plan(ws.Range("F8:H10"), 6000, 0)
    Shape actual, 2, 12

    scenario = "one material header only and sparse trailing range"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2").Value2 = 1000: ws.Range("B2").Value2 = 2
    actual = Plan(ws.Range("A1:F20"), 6000, 3)
    If Shape(actual, 2, 12) Then Equal actual(2, 4), "1000 x 2", "ungrouped details"
End Sub

Private Sub TestInputsAndErrors(ByVal ws As Worksheet)
    Dim actual As Variant
    scenario = "input validation"
    Example ws
    ErrorCode Plan(ws.Range("A1:E5"), 0, 3), 2015, "zero stock"
    ErrorCode Plan(ws.Range("A1:E5"), 6000, -1), 2015, "negative kerf"
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3, -1), 2015, "negative trim"
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3, 3000, 3000), 2015, "trims consume stock"
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 6000), 2015, "kerf consumes stock"
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 0, 0, 0, -1), 2015, "negative reusable threshold"
    ErrorCode Plan(Union(ws.Range("A1:B3"), ws.Range("D1:E3")), 6000, 0), 2023, "multi area"
    ErrorCode Plan(ws.Range("A1"), 6000, 0), 2015, "single cell"
    ErrorCode Plan(ws.Range("A1:E500000"), 6000, 0), 2036, "source resource cap"

    ws.Range("B3").Value2 = -1
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "negative quantity"
    ws.Range("B3").Value2 = 1.5
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "fractional quantity"
    ws.Range("B3").Value2 = True
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "boolean quantity"
    ws.Range("B3").Value2 = CVErr(xlErrNA)
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "error quantity"
    ws.Range("B3").Value2 = 20001
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2036, "piece resource cap"
    ws.Range("B3").Value2 = 1
    ws.Range("B2").ClearContents
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "missing material"
    Example ws
    ws.Range("A3").Value2 = "TOTAL"
    'This creates a nonnumeric body row before the next numeric length.
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "bad row label"
    Example ws
    ws.Range("A4").ClearContents
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "demand with no length"
    Example ws
    ws.Range("A3").Value2 = -1
    ErrorCode Plan(ws.Range("A1:E5"), 6000, 3), 2015, "negative length"

    scenario = "numeric text, empty strings and zero demand"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2:B2").NumberFormat = "@"
    ws.Range("A2").Value2 = "1000": ws.Range("B2").Value2 = "2"
    actual = Plan(ws.Range("A1:B3"), 6000, 0)
    If Shape(actual, 2, 12) Then Equal actual(2, 5), 2, "numeric text accepted"
    ws.Range("B2").NumberFormat = "General"
    ws.Range("B2").Formula = "="""""
    ws.Calculate
    actual = Plan(ws.Range("A1:B3"), 6000, 0)
    Shape actual, 1, 12
    ws.Range("B2").Value2 = 0
    actual = Plan(ws.Range("A1:B3"), 6000, 0)
    Shape actual, 1, 12

    scenario = "collision safe material and group keys"
    Reset ws
    ws.Range("B1").Value2 = "C": ws.Range("C1").Value2 = "BC"
    ws.Range("B2").Value2 = "AB": ws.Range("C2").Value2 = "A"
    ws.Range("A3").Value2 = 100: ws.Range("B3:C3").Value2 = 1
    actual = Plan(ws.Range("A1:C3"), 6000, 0)
    Shape actual, 3, 12
End Sub

Private Sub TestKerfAndRemainders(ByVal ws As Worksheet)
    Dim actual As Variant
    scenario = "kerf per piece, exact fits, remnant thresholds"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2").Value2 = 2997: ws.Range("B2").Value2 = 2
    actual = Plan(ws.Range("A1:B2"), 6000, 3)
    If Shape(actual, 2, 12) Then
        Equal actual(2, 8), 6, "two kerfs"
        Equal actual(2, 10), 0, "exact fit"
        Equal actual(2, 12), "NONE", "no remnant"
        CheckBalance actual
    End If
    ws.Range("A2").Value2 = 2998
    actual = Plan(ws.Range("A1:B2"), 6000, 3)
    Shape actual, 3, 12
    ws.Range("A2").Value2 = 6000: ws.Range("B2").Value2 = 1
    ErrorCode Plan(ws.Range("A1:B2"), 6000, 3), 2036, "stock sized piece with kerf cannot fit"
    actual = Plan(ws.Range("A1:B2"), 6000, 0)
    Shape actual, 2, 12
    ws.Range("A2").Value2 = 5000
    actual = Plan(ws.Range("A1:B2"), 6000, 0, 0, 0, 1000)
    If Shape(actual, 2, 12) Then Equal actual(2, 12), "REUSABLE", "threshold inclusive"
    actual = Plan(ws.Range("A1:B2"), 6000, 0, 0, 0, 1001)
    If Shape(actual, 2, 12) Then Equal actual(2, 12), "SCRAP", "below threshold"
    ws.Range("A2").Value2 = 0.1: ws.Range("B2").Value2 = 10
    actual = Plan(ws.Range("A1:B2"), 1, 0)
    If Shape(actual, 2, 12) Then
        Equal actual(2, 5), 10, "decimal pieces fit"
        CheckBalance actual
    End If
    ws.Range("A2").Value2 = 0.0000000001: ws.Range("B2").Value2 = 1
    ErrorCode Plan(ws.Range("A1:B2"), 0.00000000001, 0), 2036, "relative tolerance cannot admit oversized tiny piece"
End Sub

Private Sub TestDynamicSpill(ByVal ws As Worksheet)
    scenario = "actual worksheet spill, recalculation and blockers"
    Example ws
    ws.Range("G1").Formula2 = "=CUTTING_LIST(A1:E8,6000,3,10,10,300,TRUE)"
    ws.Calculate
    Equal ws.Range("G1").Value2, "SUMMARY REPORT", "worksheet udf header"
    Equal ws.Range("H7").Value2, 8, "worksheet pieces"
    Equal ws.Range("G34").Value2, "SD-9211", "worksheet third bar"
    Equal WorksheetFunction.Sum(ws.Range("K32:M32")), ws.Range("P32").Value2, "Excel SUM over numeric Item cells"
    ws.Range("B3").Value2 = 4
    ws.Calculate
    Equal ws.Range("H7").Value2, 9, "quantity change recalculates"
    ws.Range("A6").Value2 = 900: ws.Range("B6").Value2 = 2
    ws.Calculate
    Equal ws.Range("H7").Value2, 11, "new length row within reference"
    ws.Range("G1").ClearContents
    ws.Range("G2").Value2 = "blocked"
    ws.Range("G1").Formula2 = "=CUTTING_LIST(A1:E8,6000,3)"
    ws.Calculate
    Check IsError(ws.Range("G1").Value2), "blocked spill returns Excel error"
    ws.Range("G2").ClearContents
    ws.Calculate
    Equal ws.Range("G1").Value2, "SUMMARY REPORT", "spill recovers after clearing blocker"
    ws.Range("G1").ClearContents
    ws.Range("XFC1").Formula2 = "=CUTTING_LIST(A1:E8,6000,3)"
    ws.Calculate
    ErrorCode ws.Range("XFC1").Value2, 2036, "output beyond right edge"
    ws.Range("XFC1").ClearContents

    scenario = "worksheet Item width grows and shrinks on recalculation"
    Reset ws
    ws.Range("B1").Value2 = "M1"
    ws.Range("A2").Value2 = 1000: ws.Range("B2").Value2 = 2
    ws.Range("G1").Formula2 = "=CUTTING_LIST(A1:B2,6000,0)"
    ws.Range("AA1").Formula2 = "=COLUMNS(G1#)"
    ws.Calculate
    Equal ws.Range("AA1").Value2, 14, "two Items spill fourteen columns"
    ws.Range("B2").Value2 = 4
    ws.Calculate
    Equal ws.Range("AA1").Value2, 16, "four Items grow spill to sixteen columns"
    Equal WorksheetFunction.Sum(ws.Range("K26:N26")), 4000, "four numeric Item cells"
    Equal ws.Range("V26").Value2, "REUSABLE", "tail moved with added Items"
    ws.Range("B2").Value2 = 1
    ws.Calculate
    Equal ws.Range("AA1").Value2, 13, "one Item shrinks spill to thirteen columns"
    Check IsEmpty(ws.Range("V26").Value2), "old wide spill cells cleared"
    ws.Range("G1").ClearContents
    ws.Range("AA1").ClearContents

    scenario = "caller width uses actual Item column count"
    ws.Range("B2").Value2 = 2
    ws.Cells(1, 16371).Formula2 = "=CUTTING_LIST(A1:B2,6000,0)"
    ws.Calculate
    Equal ws.Cells(1, 16371).Value2, "SUMMARY REPORT", "fourteen columns fit at right edge"
    ws.Range("B2").Value2 = 3
    ws.Calculate
    ErrorCode ws.Cells(1, 16371).Value2, 2036, "fifteen columns exceed actual caller width"
    ws.Cells(1, 16371).ClearContents
End Sub

Private Sub TestRandomConservation(ByVal ws As Worksheet)
    Dim trial As Long, r As Long, c As Long, actual As Variant
    Dim stock As Double, kerf As Double, trim As Double, seed As Single
    scenario = "40 independent demand reconcilations"
    seed = Rnd(-1)
    Randomize 731
    For trial = 1 To 40
        Reset ws
        ws.Range("B1").Value2 = "P1": ws.Range("D1").Value2 = "P2"
        ws.Range("B2").Value2 = "M1": ws.Range("C2").Value2 = "M2"
        ws.Range("D2").Value2 = "M1": ws.Range("E2").Value2 = "M2"
        stock = 3000 + Int(Rnd() * 3000)
        kerf = Int(Rnd() * 5)
        trim = Int(Rnd() * 20)
        For r = 3 To 10
            ws.Cells(r, 1).Value2 = 100 + 173 * (r - 3)
            For c = 2 To 5
                ws.Cells(r, c).Value2 = Int(Rnd() * 5)
            Next c
        Next r
        actual = Plan(ws.Range("A1:E10"), stock, kerf, trim, trim, 300, trial Mod 2 = 0)
        If IsArray(actual) Then
            CheckBalance actual
            CompareDemand ws.Range("A1:E10"), actual
            For r = 2 To UBound(actual, 1)
                Equal actual(r, 8), actual(r, 5) * kerf, "kerf count"
                Equal actual(r, 9), 2 * trim, "trim count"
                Check actual(r, 11) > 0 And actual(r, 11) <= 100, "utilization percent range"
                If trial Mod 2 = 1 Then
                    Check Not (InStr(CStr(actual(r, 4)), "P1:") > 0 And _
                        InStr(CStr(actual(r, 4)), "P2:") > 0), "no cross group mixing"
                End If
            Next r
        Else
            Check False, "random valid input must return array"
        End If
    Next trial
End Sub

Private Sub CompareDemand(ByVal source As Range, ByVal actual As Variant)
    Dim expected As Object, observed As Object, data As Variant
    Dim r As Long, c As Long, group As String, key As Variant
    Dim entries As Variant, entry As Variant, parts As Variant, colon As Long
    Dim qty As Double, length As Double, material As String
    Set expected = CreateObject("Scripting.Dictionary")
    Set observed = CreateObject("Scripting.Dictionary")
    expected.CompareMode = vbTextCompare: observed.CompareMode = vbTextCompare
    data = source.Value2
    For c = 2 To UBound(data, 2)
        If Len(CStr(data(1, c))) > 0 Then group = CStr(data(1, c))
        For r = 3 To UBound(data, 1)
            If IsNumeric(data(r, c)) And Not IsEmpty(data(r, c)) Then
                qty = CDbl(data(r, c))
                If qty > 0 Then
                    key = CStr(data(2, c)) & "|" & group & "|" & CStr(data(r, 1))
                    If Not expected.Exists(key) Then expected.Add key, 0#
                    expected(key) = expected(key) + qty
                End If
            End If
        Next r
    Next c
    For r = 2 To UBound(actual, 1)
        material = CStr(actual(r, 1))
        entries = Split(CStr(actual(r, 4)), " + ")
        For Each entry In entries
            colon = InStr(CStr(entry), ": ")
            If colon = 0 Then
                Check False, "group trace parse"
                Exit Sub
            End If
            group = Left$(CStr(entry), colon - 1)
            parts = Split(Mid$(CStr(entry), colon + 2), " x ")
            length = CDbl(parts(0)): qty = CDbl(parts(1))
            key = material & "|" & group & "|" & CStr(length)
            If Not observed.Exists(key) Then observed.Add key, 0#
            observed(key) = observed(key) + qty
        Next entry
    Next r
    Equal expected.Count, observed.Count, "unique demand keys"
    For Each key In expected.Keys
        If observed.Exists(key) Then
            Equal observed(key), expected(key), "exact quantity for " & CStr(key)
        Else
            Check False, "missing demand " & CStr(key)
        End If
    Next key
End Sub

Private Sub CheckBalance(ByVal actual As Variant)
    Dim r As Long
    For r = 2 To UBound(actual, 1)
        Equal actual(r, 6), actual(r, 7) + actual(r, 8) + actual(r, 9) + actual(r, 10), "bar length balance"
        Check CDbl(actual(r, 10)) >= 0, "nonnegative remainder"
    Next r
End Sub

Private Function SumColumn(ByVal actual As Variant, ByVal col As Long) As Double
    Dim r As Long
    For r = 2 To UBound(actual, 1)
        SumColumn = SumColumn + CDbl(actual(r, col))
    Next r
End Function

Private Sub Example(ByVal ws As Worksheet)
    Reset ws
    ws.Range("B1").Value2 = "P17": ws.Range("D1").Value2 = "P18"
    ws.Range("B2").Value2 = "S2214V": ws.Range("C2").Value2 = "SD-9211"
    ws.Range("D2").Value2 = "S2214V": ws.Range("E2").Value2 = "SD-9211"
    ws.Range("A3").Value2 = 1600: ws.Range("A4").Value2 = 2200: ws.Range("A5").Value2 = 2800
    ws.Range("B3").Value2 = 3: ws.Range("D3").Value2 = 1
    ws.Range("B4").Value2 = 1: ws.Range("D4").Value2 = 1
    ws.Range("C5").Value2 = 1: ws.Range("E5").Value2 = 1
End Sub

Private Sub Reset(ByVal ws As Worksheet)
    ws.Range("A1:Z80").UnMerge
    ws.Range("A1:Z80").Clear
End Sub

Private Function Shape(ByVal actual As Variant, ByVal rows As Long, ByVal cols As Long) As Boolean
    If Not IsArray(actual) Then
        Check False, "expected array " & rows & " x " & cols
        Exit Function
    End If
    Shape = (UBound(actual, 1) = rows And UBound(actual, 2) = cols)
    Check Shape, "shape " & rows & " x " & cols
End Function

Private Sub ErrorCode(ByVal actual As Variant, ByVal code As Long, ByVal label As String)
    If Not IsError(actual) Then
        Check False, label & " must return error"
    Else
        Equal CStr(actual), CStr(CVErr(code)), label
    End If
End Sub

Private Sub Equal(ByVal actual As Variant, ByVal expected As Variant, ByVal label As String)
    If IsError(actual) Then
        Check False, label & " unexpected Excel error"
    ElseIf IsNumeric(actual) And IsNumeric(expected) Then
        Check Abs(CDbl(actual) - CDbl(expected)) < 0.00001, label
    Else
        Check CStr(actual) = CStr(expected), label
    End If
End Sub

Private Sub Check(ByVal condition As Boolean, ByVal label As String)
    checks = checks + 1
    If Not condition Then
        failures = failures + 1
        If failures <= 20 Then log = log & vbCrLf & scenario & ": " & label
    End If
End Sub
