Attribute VB_Name = "Test_CuttingVersions"
Option Explicit

Private checks As Long
Private failures As Long
Private details As String
Private scenario As String

Public Function RunCuttingVersionTests() As String
    Dim ws As Worksheet
    On Error GoTo UnexpectedError
    checks = 0: failures = 0: details = ""
    Set ws = ThisWorkbook.Worksheets(1)
    TestSeparatePP ws
    TestHeaderRules ws
    TestRandomParity ws
    TestWorksheetCoexistence ws
    TestReportDirection ws
    If failures = 0 Then
        RunCuttingVersionTests = "PASS: " & checks & " assertions across V/H layout, PP separation, headers, validation, 40 randomized comparisons and worksheet recalculation/bounds"
    Else
        RunCuttingVersionTests = "FAIL: " & failures & "/" & checks & details
    End If
    Exit Function
UnexpectedError:
    RunCuttingVersionTests = "FAIL: VBA error " & Err.Number & " in " & scenario & ": " & Err.Description & details
End Function

Private Sub TestSeparatePP(ByVal ws As Worksheet)
    Dim allCut As Variant, separate As Variant, row As Long, n As Long
    scenario = "same material across two PP"
    Reset ws
    ws.Range("B1").Value2 = "PP17": ws.Range("C1").Value2 = "PP18"
    ws.Range("B2:C2").Value2 = "M1"
    ws.Range("A3").Value2 = 2200: ws.Range("B3:C3").Value2 = 1
    allCut = CUTTING_LIST_V0(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, True)
    separate = CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, False)
    Equal allCut(5, 2), 1, "V0 can mix PP into one bar"
    Equal separate(5, 2), 2, "V1 requires separate bars"
    Equal separate(6, 2), 2, "source pieces"
    Equal separate(7, 2), 2, "cut pieces"
    Equal separate(8, 2), "", "no missing pieces"
    Equal separate(2, 2), 12000, "stock length across both PP"
    Equal separate(3, 2), 4400, "combined cut length"
    Equal separate(11, 2), 7554, "combined remnant length"
    n = 0
    For row = 1 To UBound(separate, 1)
        If CStr(separate(row, 1)) = "SUMMARY REPORT" Then n = n + 1
    Next row
    Equal n, 1, "one combined report only"
    CheckPlanPP separate
    CompareReports CUTTING_LIST(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, False), separate, "V1 matches separated baseline"
    ErrorCode CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 0, 0, 0, True), 2015, "V1 forbids mixing flag"
End Sub

Private Sub TestHeaderRules(ByVal ws As Worksheet)
    Dim actual As Variant
    scenario = "merged and repeated PP headers"
    Reset ws
    ws.Range("B1").Value2 = "PP17": ws.Range("D1").Value2 = "PP18"
    ws.Range("B1:C1").Merge: ws.Range("D1:E1").Merge
    ws.Range("B2:E2").Value2 = "M1"
    ws.Range("A3").Value2 = 1000: ws.Range("B3:E3").Value2 = 1
    actual = CUTTING_LIST_V1(ws.Range("A1:E3"), 6000, 3)
    Equal actual(5, 2), 2, "merged header children stay within PP"
    CheckPlanPP actual
    CompareReports CUTTING_LIST(ws.Range("A1:E3"), 6000, 3), actual, "merged baseline parity"
    ws.Range("B1:E1").UnMerge
    ws.Range("E1").Value2 = " pp17 "
    actual = CUTTING_LIST_V1(ws.Range("A1:E3"), 6000, 3)
    Equal actual(5, 2), 2, "repeated PP pooled case-insensitively"
    CheckPlanPP actual
    CompareReports CUTTING_LIST(ws.Range("A1:E3"), 6000, 3), actual, "repeated PP parity"

    scenario = "reject range without PP row or missing first PP"
    ErrorCode CUTTING_LIST_V1(ws.Range("A2:E3"), 6000, 3), 2015, "PP header row required"
    ws.Range("B1").ClearContents
    ErrorCode CUTTING_LIST_V1(ws.Range("A1:E3"), 6000, 3), 2015, "first PP label required"
End Sub

Private Sub TestRandomParity(ByVal ws As Worksheet)
    Dim trial As Long, row As Long, col As Long, baseline As Variant, actual As Variant
    Dim stock As Double, kerf As Double, trim As Double, seed As Single
    scenario = "randomized V0/V1 parity and no cross-PP bars"
    seed = Rnd(-1): Randomize 922
    For trial = 1 To 40
        Reset ws
        ws.Range("B1").Value2 = "PP17"
        ws.Range("D1").Value2 = "PP18"
        ws.Range("F1").Value2 = "PP19"
        For col = 2 To 7
            ws.Cells(2, col).Value2 = "M" & (1 + (col Mod 2))
        Next col
        For row = 3 To 8
            ws.Cells(row, 1).Value2 = 500 + 400 * (row - 3)
            For col = 2 To 7
                ws.Cells(row, col).Value2 = Int(Rnd() * 3)
            Next col
        Next row
        stock = 5000 + Int(Rnd() * 1500)
        kerf = Int(Rnd() * 5): trim = Int(Rnd() * 15)
        baseline = CUTTING_LIST(ws.Range("A1:G8"), stock, kerf, trim, trim, 300, True)
        actual = CUTTING_LIST_V0(ws.Range("A1:G8"), stock, kerf, trim, trim, 300, True)
        CompareReports baseline, actual, "V0 baseline parity"
        baseline = CUTTING_LIST(ws.Range("A1:G8"), stock, kerf, trim, trim, 300, False)
        actual = CUTTING_LIST_V1(ws.Range("A1:G8"), stock, kerf, trim, trim, 300)
        CompareReports baseline, actual, "V1 baseline parity"
        CheckPlanPP actual
        If trial <= 6 Then
            CompareDirections actual, CUTTING_LIST_V1(ws.Range("A1:G8"), stock, kerf, trim, trim, 300, False, "H")
            baseline = CUTTING_LIST_V0(ws.Range("A1:G8"), stock, kerf, trim, trim, 300, True)
            CompareDirections baseline, CUTTING_LIST_V0(ws.Range("A1:G8"), stock, kerf, trim, trim, 300, True, "H")
        End If
    Next trial
End Sub

Private Sub TestWorksheetCoexistence(ByVal ws As Worksheet)
    scenario = "V0 and V1 coexist and recalculate"
    Reset ws
    ws.Range("B1").Value2 = "PP17": ws.Range("C1").Value2 = "PP18"
    ws.Range("B2:C2").Value2 = "M1"
    ws.Range("A3").Value2 = 2200: ws.Range("B3:C3").Value2 = 1
    ws.Range("J1").Formula2 = "=CUTTING_LIST_V0(A1:C3,6000,3,10,10,300,TRUE)"
    ws.Range("AD1").Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3,10,10,300,FALSE)"
    ws.Calculate
    Equal ws.Range("J1").Value2, "SUMMARY REPORT", "V0 worksheet header"
    Equal ws.Range("AD1").Value2, "SUMMARY REPORT", "V1 worksheet header"
    Equal ws.Range("K5").Value2, 1, "V0 worksheet bar count"
    Equal ws.Range("AE5").Value2, 2, "V1 worksheet bar count"
    ws.Range("C3").Value2 = 0
    ws.Calculate
    Equal ws.Range("AE5").Value2, 1, "V1 recalculates remaining PP"
    ws.Range("C3").Value2 = 2
    ws.Calculate
    Equal ws.Range("AE5").Value2, 2, "V1 restores second PP separately"
    Equal ws.Range("AE7").Value2, 3, "V1 worksheet source pieces retained"
End Sub

Private Sub TestReportDirection(ByVal ws As Worksheet)
    Dim vertical As Variant, horizontal As Variant
    scenario = "vertical default and horizontal sections"
    Reset ws
    ws.Range("B1").Value2 = "PP17": ws.Range("C1").Value2 = "PP18"
    ws.Range("B2:C2").Value2 = "M1"
    ws.Range("A3").Value2 = 2200: ws.Range("B3:C3").Value2 = 1
    vertical = CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, False)
    CompareReports vertical, CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, False, "V"), "omitted direction preserves V"
    horizontal = CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, False, "H")
    CompareDirections vertical, horizontal
    Equal UBound(horizontal, 1), 14, "horizontal height"
    Equal UBound(horizontal, 2), 38, "horizontal width"
    Equal horizontal(1, 1), "SUMMARY REPORT", "summary on left"
    Equal horizontal(1, 4), "Target used list", "target to right"
    Equal horizontal(1, 17), "Item used list", "items to right"
    Equal horizontal(1, 26), "CUTTING PLAN", "plan to right"
    Equal horizontal(3, 27), "PP17", "first PP in horizontal plan"
    Equal horizontal(4, 27), "PP18", "second PP stays separate"
    Equal horizontal(3, 30), 2200, "Item remains numeric in column"
    Equal horizontal(3, 38), "REUSABLE", "six tail columns retained"
    CompareReports horizontal, CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, False, " h "), "trimmed case-insensitive direction"
    vertical = CUTTING_LIST_V0(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, True)
    horizontal = CUTTING_LIST_V0(ws.Range("A1:C3"), 6000, 3, 10, 10, 300, True, "H")
    CompareDirections vertical, horizontal
    Equal UBound(horizontal, 2), 39, "V0 horizontal width includes two Items"
    ErrorCode CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 0, 0, 0, False, "X"), 2015, "invalid direction"
    ErrorCode CUTTING_LIST_V0(ws.Range("A1:C3"), 6000, 3, 0, 0, 0, True, ""), 2015, "blank direction"

    scenario = "empty horizontal report"
    ws.Range("B3:C3").Value2 = 0
    vertical = CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3)
    horizontal = CUTTING_LIST_V1(ws.Range("A1:C3"), 6000, 3, 0, 0, 0, False, "H")
    CompareDirections vertical, horizontal
    Equal UBound(horizontal, 2), 38, "empty plan has Item1 and all tail columns"
    Equal horizontal(2, 30), "Item1", "empty plan item header"

    scenario = "direction cell changes spill layout"
    ws.Range("B3:C3").Value2 = 1
    ws.Range("F1").Value2 = "V"
    ws.Range("J1").Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3,10,10,300,FALSE,F1)"
    ws.Calculate
    Equal ws.Range("J16").Value2, "Target used list", "vertical section on worksheet"
    ws.Range("F1").Value2 = "H"
    ws.Calculate
    Equal ws.Range("M1").Value2, "Target used list", "horizontal target on worksheet"
    Equal ws.Range("AI1").Value2, "CUTTING PLAN", "horizontal plan on worksheet"
    Check IsEmpty(ws.Range("J16").Value2), "old tall spill cleared"
    ws.Range("F1").Value2 = "V"
    ws.Calculate
    Equal ws.Range("J16").Value2, "Target used list", "vertical restored"
    Check IsEmpty(ws.Range("AI1").Value2), "old horizontal spill cleared"
    ws.Range("J1").ClearContents

    scenario = "bounds checked against selected layout"
    ws.Cells(1048563, 1).Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3,10,10,300,FALSE,""V"")"
    ws.Calculate
    ErrorCode ws.Cells(1048563, 1).Value2, 2036, "V exceeds bottom edge"
    ws.Cells(1048563, 1).Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3,10,10,300,FALSE,""H"")"
    ws.Calculate
    Equal ws.Cells(1048563, 1).Value2, "SUMMARY REPORT", "H fits bottom edge"
    ws.Cells(1048563, 1).ClearContents
    ws.Cells(1, 16372).Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3,10,10,300,FALSE,""V"")"
    ws.Calculate
    Equal ws.Cells(1, 16372).Value2, "SUMMARY REPORT", "V fits right edge"
    ws.Cells(1, 16372).Formula2 = "=CUTTING_LIST_V1(A1:C3,6000,3,10,10,300,FALSE,""H"")"
    ws.Calculate
    ErrorCode ws.Cells(1, 16372).Value2, 2036, "H exceeds right edge"
    ws.Cells(1, 16372).ClearContents
End Sub

Private Sub CompareDirections(ByVal vertical As Variant, ByVal horizontal As Variant)
    Dim targetCount As Long, demandCount As Long, barCount As Long
    Dim itemTitle As Long, planTitle As Long, row As Long, col As Long, expectedRows As Long
    If Not IsArray(vertical) Or Not IsArray(horizontal) Then
        Check False, "directions must both return arrays"
        Exit Sub
    End If
    For row = 1 To UBound(vertical, 1)
        If CStr(vertical(row, 1)) = "Item used list" Then itemTitle = row
        If CStr(vertical(row, 1)) = "CUTTING PLAN" Then planTitle = row
    Next row
    targetCount = itemTitle - 19
    demandCount = planTitle - 22 - targetCount
    barCount = UBound(vertical, 1) - planTitle - 1
    expectedRows = 14
    If targetCount + 2 > expectedRows Then expectedRows = targetCount + 2
    If demandCount + 2 > expectedRows Then expectedRows = demandCount + 2
    If barCount + 2 > expectedRows Then expectedRows = barCount + 2
    Equal UBound(horizontal, 1), expectedRows, "H height uses tallest section"
    Equal UBound(horizontal, 2), UBound(vertical, 2) + 25, "H width uses section widths and gaps"
    For row = 1 To 14
        For col = 1 To 2
            Equal horizontal(row, col), vertical(row, col), "summary contents invariant"
        Next col
    Next row
    For row = 1 To targetCount + 2
        For col = 1 To 12
            Equal horizontal(row, col + 3), vertical(row + 15, col), "target contents invariant"
        Next col
    Next row
    For row = 1 To demandCount + 2
        For col = 1 To 8
            Equal horizontal(row, col + 16), vertical(row + itemTitle - 1, col), "item contents invariant"
        Next col
    Next row
    For row = 1 To barCount + 2
        For col = 1 To UBound(vertical, 2)
            Equal horizontal(row, col + 25), vertical(row + planTitle - 1, col), "plan contents invariant"
        Next col
    Next row
    For row = 1 To UBound(horizontal, 1)
        Equal horizontal(row, 3), "", "summary-target gap"
        Equal horizontal(row, 16), "", "target-item gap"
        Equal horizontal(row, 25), "", "item-plan gap"
    Next row
End Sub

Private Sub CheckPlanPP(ByVal report As Variant)
    Dim header As Long, row As Long, col As Long, total As Double, suffix As Long
    Dim group As String, text As String, pieces As Variant, entry As Variant, at As Long
    If Not IsArray(report) Then
        Check False, "expected report array"
        Exit Sub
    End If
    For row = 1 To UBound(report, 1)
        If CStr(report(row, 1)) = "CUTTING PLAN" Then header = row + 1: Exit For
    Next row
    Check header > 0, "cutting plan exists"
    If header = 0 Then Exit Sub
    suffix = UBound(report, 2) - 7
    For row = header + 1 To UBound(report, 1)
        group = CStr(report(row, 2))
        Check Len(group) > 0, "every bar has PP"
        Check group <> "MIXED", "no cross-PP bar"
        pieces = Split(CStr(report(row, suffix)), " + ")
        For Each entry In pieces
            at = InStr(CStr(entry), ": ")
            Check at > 0, "group cut trace has PP"
            If at > 0 Then Equal LCase$(Left$(CStr(entry), at - 1)), LCase$(group), "each traced cut belongs to bar PP"
        Next entry
        total = 0
        For col = 5 To suffix - 1
            If Len(CStr(report(row, col))) > 0 Then total = total + CDbl(report(row, col))
        Next col
        Equal total, report(row, suffix + 2), "numeric Item sum"
        Equal report(row, 4), total + CDbl(report(row, suffix + 3)) _
            + CDbl(report(row, suffix + 4)) + CDbl(report(row, suffix + 5)), "bar balance"
    Next row
End Sub

Private Sub CompareReports(ByVal baseline As Variant, ByVal actual As Variant, ByVal label As String)
    Dim row As Long, col As Long
    If Not IsArray(baseline) Or Not IsArray(actual) Then
        Check False, label & " requires arrays"
        Exit Sub
    End If
    Check UBound(baseline, 1) = UBound(actual, 1), label & " row count"
    Check UBound(baseline, 2) = UBound(actual, 2), label & " column count"
    If UBound(baseline, 1) <> UBound(actual, 1) Or UBound(baseline, 2) <> UBound(actual, 2) Then Exit Sub
    For row = 1 To UBound(baseline, 1)
        For col = 1 To UBound(baseline, 2)
            Equal actual(row, col), baseline(row, col), label
        Next col
    Next row
End Sub

Private Sub Reset(ByVal ws As Worksheet)
    ws.Range("A1:AZ100").UnMerge
    ws.Range("A1:AZ100").Clear
End Sub

Private Sub ErrorCode(ByVal actual As Variant, ByVal expected As Long, ByVal label As String)
    If IsError(actual) Then
        Equal CStr(actual), CStr(CVErr(expected)), label
    Else
        Check False, label & " expected error"
    End If
End Sub

Private Sub Equal(ByVal actual As Variant, ByVal expected As Variant, ByVal label As String)
    If IsError(actual) Or IsError(expected) Then
        Check False, label & " unexpected error"
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
        If failures <= 15 Then details = details & vbCrLf & scenario & ": " & label
    End If
End Sub
