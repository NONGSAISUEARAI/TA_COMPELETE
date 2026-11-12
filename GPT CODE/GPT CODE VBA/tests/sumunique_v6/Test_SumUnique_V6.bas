Attribute VB_Name = "Test_SumUnique_V6"
Option Explicit

Private assertionCount As Long
Private failureCount As Long
Private failureLog As String
Private currentCase As String

Public Function RunSumUniqueV6Tests() As String
    Dim ws As Worksheet

    On Error GoTo UnexpectedError
    Set ws = ThisWorkbook.Worksheets(1)
    assertionCount = 0
    failureCount = 0
    failureLog = ""
    TestFull ws
    TestSparse ws
    TestTwoConditionsAndTitle ws
    TestIndependentSorting ws
    TestDeepHeaders ws
    TestAmounts ws
    TestSourceKeys ws
    TestInvalidArguments ws
    TestRangeErrors ws
    TestRectangularInput ws
    TestSingleCellInput ws
    TestReferences ws
    TestOutputAndNumericOverflow ws
    TestCountAndSumTogether ws
    TestWorksheetSpills ws
    TestDelimiterValues ws

    If failureCount = 0 Then
        RunSumUniqueV6Tests = "PASS: " & assertionCount & " assertions across 16 cases"
    Else
        RunSumUniqueV6Tests = "FAIL: " & failureCount & "/" & assertionCount & failureLog
    End If
    Exit Function
UnexpectedError:
    RunSumUniqueV6Tests = "FAIL: VBA error " & Err.Number & " in " & currentCase _
        & ": " & Err.Description & failureLog
End Function

Private Sub TestFull(ByVal ws As Worksheet)
    Dim actual As Variant
    Dim groupIndex As Long
    Dim outputColumn As Long
    Dim outputRow As Long
    Dim expected As Variant

    currentCase = "full Cartesian totals"
    ExampleData ws
    actual = SUMUNIQUE_V6("SS", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, _
        ws.Range("B1:B6"), 0, ws.Range("C1:C6"), 0)
    If Not ExpectShape(actual, 5, 13) Then Exit Sub
    ExpectEqual actual(1, 1), "SS", "title"
    ExpectEqual actual(4, 1), "as", "row label as"
    ExpectEqual actual(5, 1), "wqe", "row label wqe"
    For groupIndex = 0 To 3
        outputColumn = 2 + groupIndex * 3
        ExpectEqual actual(2, outputColumn), Chr$(65 + groupIndex), "outer group"
        ExpectBlank actual(2, outputColumn + 1), "outer group spacer"
        ExpectBlank actual(2, outputColumn + 2), "outer group spacer"
        ExpectEqual actual(3, outputColumn), "qq", "qq under every group"
        ExpectEqual actual(3, outputColumn + 1), "erw", "erw under every group"
        ExpectEqual actual(3, outputColumn + 2), "we", "we under every group"
    Next groupIndex
    For outputRow = 4 To 5
        For outputColumn = 2 To 13
            expected = ""
            If outputRow = 4 And outputColumn = 2 Then expected = 10
            If outputRow = 4 And outputColumn = 11 Then expected = 7
            If outputRow = 5 And outputColumn = 6 Then expected = 4
            If outputRow = 5 And outputColumn = 10 Then expected = -2
            If VarType(expected) = vbString Then
                ExpectBlank actual(outputRow, outputColumn), "unmatched tuple blank"
            Else
                ExpectNear actual(outputRow, outputColumn), CDbl(expected), "tuple sum"
            End If
        Next outputColumn
    Next outputRow
End Sub

Private Sub TestSparse(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "observed tuples only"
    ExampleData ws
    actual = SUMUNIQUE_V6("SS", 0, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, _
        ws.Range("B1:B6"), 0, ws.Range("C1:C6"), 0)
    If Not ExpectShape(actual, 5, 5) Then Exit Sub
    ExpectEqual actual(2, 2), "A", "A header"
    ExpectEqual actual(2, 3), "B", "B header"
    ExpectEqual actual(2, 4), "C", "C header"
    ExpectEqual actual(2, 5), "D", "D header"
    ExpectEqual actual(3, 2), "qq", "A child"
    ExpectEqual actual(3, 5), "qq", "D identical child reappears"
    ExpectNear actual(4, 2), 10, "A/qq sum"
    ExpectNear actual(4, 5), 7, "D/qq sum"
    ExpectNear actual(5, 3), 4, "B/erw sum"
    ExpectNear actual(5, 4), -2, "C/we negative sum"
    ExpectBlank actual(4, 3), "missing sparse row tuple"
End Sub

Private Sub TestTwoConditionsAndTitle(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "two conditions and omitted title"
    ExampleData ws
    actual = SUMUNIQUE_V6("", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    If ExpectShape(actual, 3, 5) Then
        ExpectEqual actual(1, 2), "A", "header starts at first row"
        ExpectNear actual(2, 2), 10, "two-condition A sum"
        ExpectNear actual(3, 3), 4, "two-condition B sum"
        ExpectNear actual(3, 4), -2, "two-condition C sum"
    End If
End Sub

Private Sub TestIndependentSorting(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "independent sorting"
    PutRows ws, Array(Array(20, "Z", "Y", 6), Array(10, "A", "X", 3))
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D2"), ws.Range("A1:A2"), 0, _
        ws.Range("B1:B2"), 0, ws.Range("C1:C2"), 0)
    If ExpectShape(actual, 5, 5) Then
        ExpectNear actual(4, 1), 20, "first-seen row"
        ExpectEqual actual(2, 2), "Z", "first-seen group"
        ExpectEqual actual(3, 2), "Y", "first-seen child"
        ExpectNear actual(4, 2), 6, "unsorted amount"
    End If
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D2"), ws.Range("A1:A2"), 1, _
        ws.Range("B1:B2"), 1, ws.Range("C1:C2"), 1)
    If ExpectShape(actual, 5, 5) Then
        ExpectNear actual(4, 1), 10, "ascending numeric row"
        ExpectEqual actual(2, 2), "A", "ascending group"
        ExpectEqual actual(3, 2), "X", "ascending child"
        ExpectNear actual(4, 2), 3, "sorted amount"
    End If
    actual = SUMUNIQUE_V6("S", 0, ws.Range("D1:D2"), ws.Range("A1:A2"), 1, _
        ws.Range("B1:B2"), 0, ws.Range("C1:C2"), 1)
    If ExpectShape(actual, 5, 3) Then
        ExpectNear actual(4, 1), 10, "mixed ascending row"
        ExpectEqual actual(2, 2), "Z", "mixed first-seen group"
        ExpectNear actual(4, 3), 3, "mixed sparse amount mapping"
        ExpectNear actual(5, 2), 6, "mixed sparse second row amount"
    End If
End Sub

Private Sub TestDeepHeaders(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "five conditions and four horizontal levels"
    PutRows ws, Array(Array("R2", "B", "beta", "Y", "N", 2.5), _
        Array("R1", "A", "alpha", "X", "M", -1.25))
    actual = SUMUNIQUE_V6("Deep", 1, ws.Range("F1:F2"), ws.Range("A1:A2"), 1, _
        ws.Range("B1:B2"), 1, ws.Range("C1:C2"), 1, ws.Range("D1:D2"), 1, ws.Range("E1:E2"), 1)
    If ExpectShape(actual, 7, 17) Then
        ExpectEqual actual(2, 2), "A", "deep outer A"
        ExpectEqual actual(2, 10), "B", "deep outer B"
        ExpectEqual actual(3, 10), "alpha", "child repeats under new parent"
        ExpectEqual actual(5, 2), "M", "deepest child M"
        ExpectEqual actual(5, 3), "N", "deepest child N"
        ExpectNear actual(6, 2), -1.25, "deep first sum"
        ExpectNear actual(7, 17), 2.5, "deep last sum"
        ExpectBlank actual(6, 3), "deep missing tuple"
    End If
    actual = SUMUNIQUE_V6("Deep", 0, ws.Range("F1:F2"), ws.Range("A1:A2"), 1, _
        ws.Range("B1:B2"), 1, ws.Range("C1:C2"), 1, ws.Range("D1:D2"), 1, ws.Range("E1:E2"), 1)
    If ExpectShape(actual, 7, 3) Then
        ExpectNear actual(6, 2), -1.25, "sparse deep first sum"
        ExpectNear actual(7, 3), 2.5, "sparse deep last sum"
    End If
End Sub

Private Sub TestAmounts(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "numeric strings zero negative cancellation and invalid amounts"
    PutRows ws, Array(Array("r", "A", 10), Array("r", "A", -10), Array("r", "A", 0), _
        Array("r", "A", 2.5), Array("ignored", "X", "bad"), Array("ignored", "X", ""), _
        Array("ignored", "X", CVErr(xlErrNA)), Array("ignored", "X", True), Array("zero", "B", 0), _
        Array("ignored", "X", False))
    ws.Range("C4").NumberFormat = "@"
    ws.Range("C4").Value2 = "2.5"
    actual = SUMUNIQUE_V6("S", 0, ws.Range("C1:C10"), ws.Range("A1:A10"), 0, ws.Range("B1:B10"), 0)
    If ExpectShape(actual, 4, 3) Then
        ExpectNear actual(3, 2), 2.5, "numeric text contributes"
        ExpectNear actual(4, 3), 0, "zero amount contributes real zero tuple"
        ExpectBlank actual(3, 3), "no tuple remains blank"
        ExpectEqual actual(4, 1), "zero", "zero-only row retained"
    End If
    PutRows ws, Array(Array("r", "A", 10), Array("r", "A", -10))
    actual = SUMUNIQUE_V6("S", 0, ws.Range("C1:C2"), ws.Range("A1:A2"), 0, ws.Range("B1:B2"), 0)
    If ExpectShape(actual, 3, 2) Then ExpectNear actual(3, 2), 0, "cancellation retains zero"
    ws.Range("C1:C2").ClearContents
    actual = SUMUNIQUE_V6("S", 1, ws.Range("C1:C2"), ws.Range("A1:A2"), 0, ws.Range("B1:B2"), 0)
    ExpectBlank actual, "all amounts blank returns blank"
End Sub

Private Sub TestSourceKeys(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "blank error zero case and numeric-text source keys"
    PutRows ws, Array(Array(0, 0, 2), Array("a", "b", 3), Array("A", "B", 4), _
        Array("", "b", 100), Array("x", CVErr(xlErrNA), 100), Array("  ", "b", 100))
    actual = SUMUNIQUE_V6("S", 1, ws.Range("C1:C6"), ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    If ExpectShape(actual, 4, 3) Then
        ExpectNear actual(3, 1), 0, "zero vertical key"
        ExpectNear actual(2, 2), 0, "zero header key"
        ExpectNear actual(3, 2), 2, "zero keys sum"
        ExpectNear actual(4, 3), 7, "case-insensitive sum"
    End If
    PutRows ws, Array(Array(1, "B", 2), Array(1, "B", 3))
    ws.Range("A1").NumberFormat = "@"
    ws.Range("A1").Value2 = "1"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("C1:C2"), ws.Range("A1:A2"), 0, ws.Range("B1:B2"), 0)
    If ExpectShape(actual, 4, 2) Then
        ExpectTrue VarType(actual(3, 1)) = vbString, "text key distinct"
        ExpectTrue VarType(actual(4, 1)) <> vbString, "numeric key distinct"
        ExpectNear actual(3, 2), 2, "text key sum"
        ExpectNear actual(4, 2), 3, "numeric key sum"
    End If
End Sub

Private Sub TestInvalidArguments(ByVal ws As Worksheet)
    Dim actual As Variant
    Dim missingRange As Range
    currentCase = "invalid arguments"
    ExampleData ws
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"))
    ExpectError actual, xlErrValue, "no pairs"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 0)
    ExpectError actual, xlErrValue, "only one pair"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, ws.Range("B1:B6"))
    ExpectError actual, xlErrValue, "unpaired range"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 2, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "invalid sorting"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 1E+20, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "large invalid flag avoids overflow"
    actual = SUMUNIQUE_V6("S", 2, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "invalid blank mode"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), "A1:A6", 0, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "range text rejected"
    actual = SUMUNIQUE_V6("S", 1, missingRange, ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "Nothing amount range"
End Sub

Private Sub TestRangeErrors(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "source and sum range errors"
    ExampleData ws
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D5"), ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrRef, "sum length mismatch"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, ws.Range("B1:B5"), 0)
    ExpectError actual, xlErrRef, "source length mismatch"
    actual = SUMUNIQUE_V6("S", 1, Application.Union(ws.Range("D1:D3"), ws.Range("D5:D6")), _
        ws.Range("A1:A5"), 0, ws.Range("B1:B5"), 0)
    ExpectError actual, xlErrRef, "multi-area sum range"
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D5"), _
        Application.Union(ws.Range("A1:A3"), ws.Range("A5:A6")), 0, ws.Range("B1:B5"), 0)
    ExpectError actual, xlErrRef, "multi-area source range"
End Sub

Private Sub TestRectangularInput(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "rectangular ranges flatten row-major"
    ws.Cells.Clear
    ws.Range("A1").Value2 = "R1"
    ws.Range("B1").Value2 = "R2"
    ws.Range("A2").Value2 = "R1"
    ws.Range("B2").Value2 = "R2"
    ws.Range("D1").Value2 = "A"
    ws.Range("E1").Value2 = "A"
    ws.Range("D2").Value2 = "B"
    ws.Range("E2").Value2 = "B"
    ws.Range("G1").Value2 = 1
    ws.Range("H1").Value2 = 2
    ws.Range("I1").Value2 = 3
    ws.Range("J1").Value2 = 4
    actual = SUMUNIQUE_V6("S", 1, ws.Range("G1:J1"), ws.Range("A1:B2"), 0, ws.Range("D1:E2"), 0)
    If ExpectShape(actual, 4, 3) Then
        ExpectNear actual(3, 2), 1, "R1/A amount"
        ExpectNear actual(4, 2), 2, "R2/A amount"
        ExpectNear actual(3, 3), 3, "R1/B amount"
        ExpectNear actual(4, 3), 4, "R2/B amount"
    End If
End Sub

Private Sub TestSingleCellInput(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "single-cell source and amount ranges"
    PutRows ws, Array(Array("R", "A", 1.25))
    actual = SUMUNIQUE_V6("S", 1, ws.Range("C1"), ws.Range("A1"), 0, ws.Range("B1"), 0)
    If ExpectShape(actual, 3, 2) Then
        ExpectEqual actual(2, 2), "A", "scalar header"
        ExpectNear actual(3, 2), 1.25, "scalar amount"
    End If
End Sub

Private Sub TestReferences(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "heading and flag cell references"
    ExampleData ws
    ws.Range("H1").Value2 = "From cell"
    ws.Range("H2").Value2 = 1
    ws.Range("H3").Value2 = 0
    actual = SUMUNIQUE_V6(ws.Range("H1"), ws.Range("H2"), ws.Range("D1:D6"), _
        ws.Range("A1:A6"), ws.Range("H3"), ws.Range("B1:B6"), ws.Range("H3"))
    If ExpectShape(actual, 4, 5) Then
        ExpectEqual actual(1, 1), "From cell", "heading reference"
        ExpectNear actual(3, 2), 10, "flag references"
    End If
End Sub

Private Sub TestOutputAndNumericOverflow(ByVal ws As Worksheet)
    Dim actual As Variant
    Dim values(1 To 129, 1 To 4) As Variant
    Dim i As Long
    currentCase = "sparse large cardinality and overflow checks"
    ws.Cells.Clear
    For i = 1 To 129
        values(i, 1) = "R"
        values(i, 2) = "G" & Format$(i, "000")
        values(i, 3) = "S" & Format$(i, "000")
        values(i, 4) = i
    Next i
    ws.Range("A1:D129").Value2 = values
    actual = SUMUNIQUE_V6("S", 0, ws.Range("D1:D129"), ws.Range("A1:A129"), 0, _
        ws.Range("B1:B129"), 0, ws.Range("C1:C129"), 0)
    If ExpectShape(actual, 4, 130) Then
        ExpectNear actual(4, 2), 1, "sparse first diagonal sum"
        ExpectNear actual(4, 130), 129, "sparse last diagonal sum"
    End If
    actual = SUMUNIQUE_V6("S", 1, ws.Range("D1:D129"), ws.Range("A1:A129"), 0, _
        ws.Range("B1:B129"), 0, ws.Range("C1:C129"), 0)
    ExpectError actual, xlErrNum, "full product exceeds worksheet columns"
    PutRows ws, Array(Array("R", "A", 1E+308), Array("R", "A", 1E+308))
    actual = SUMUNIQUE_V6("S", 0, ws.Range("C1:C2"), ws.Range("A1:A2"), 0, ws.Range("B1:B2"), 0)
    ExpectError actual, xlErrNum, "sum arithmetic overflow"
End Sub

Private Sub TestCountAndSumTogether(ByVal ws As Worksheet)
    Dim actualSum As Variant
    Dim actualCount As Variant
    currentCase = "count and sum modules coexist"
    ExampleData ws
    actualCount = COUNTUNIQUE_V6("C", 1, ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    actualSum = SUMUNIQUE_V6("S", 1, ws.Range("D1:D6"), ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    If ExpectShape(actualCount, 4, 5) And ExpectShape(actualSum, 4, 5) Then
        ExpectNear actualCount(4, 3), 2, "count still returns occurrence count"
        ExpectNear actualSum(4, 3), 4, "sum returns accumulated amount"
    End If
End Sub

Private Sub TestWorksheetSpills(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "worksheet Formula2 full and sparse spills"
    ExampleData ws
    ws.Range("H1").Value2 = "From cell"
    ws.Range("H2").Value2 = 1
    ws.Range("H3").Value2 = 0
    ws.Range("K1").Formula2 = "=SUMUNIQUE_V6(H1,H2,D1:D6,A1:A6,H3,B1:B6,H3,C1:C6,H3)"
    ws.Calculate
    ExpectEqual ws.Range("K1").Value2, "From cell", "formula title reference"
    ExpectNear ws.Range("L4").Value2, 10, "formula A amount"
    ExpectNear ws.Range("U4").Value2, 7, "formula D amount"
    ExpectNear ws.Range("P5").Value2, 4, "formula B sum"
    ExpectNear ws.Range("T5").Value2, -2, "formula C negative sum"
    ExpectBlank ws.Range("M4").Value2, "formula missing amount blank"
    actual = ws.Range("K1").SpillingToRange.Value2
    ExpectShape actual, 5, 13
    ws.Range("H2").Value2 = 0
    ws.Calculate
    ExpectNear ws.Range("L4").Value2, 10, "sparse formula A amount"
    ExpectNear ws.Range("O4").Value2, 7, "sparse formula D amount"
    ExpectNear ws.Range("M5").Value2, 4, "sparse formula B sum"
    ExpectNear ws.Range("N5").Value2, -2, "sparse formula C negative sum"
    ExpectBlank ws.Range("M4").Value2, "sparse formula missing amount blank"
    actual = ws.Range("K1").SpillingToRange.Value2
    ExpectShape actual, 5, 5
End Sub

Private Sub TestDelimiterValues(ByVal ws As Worksheet)
    Dim actual As Variant
    currentCase = "source delimiter text cannot collide tuple keys"
    PutRows ws, Array(Array("R", "a|b", "c", 1), Array("R", "a", "b|c", 2), _
        Array("R", "a" & ChrW$(30) & "b", "c", 4), Array("R", "a", "b" & ChrW$(30) & "c", 8))
    actual = SUMUNIQUE_V6("S", 0, ws.Range("D1:D4"), ws.Range("A1:A4"), 0, _
        ws.Range("B1:B4"), 0, ws.Range("C1:C4"), 0)
    If ExpectShape(actual, 4, 5) Then
        ExpectNear actual(4, 2), 1, "pipe in outer key"
        ExpectNear actual(4, 3), 2, "pipe in inner key"
        ExpectNear actual(4, 4), 8, "control separator in inner key"
        ExpectNear actual(4, 5), 4, "control separator in outer key"
        ExpectBlank actual(2, 4), "sparse same-parent header spacer"
    End If
End Sub

Private Sub ExampleData(ByVal ws As Worksheet)
    PutRows ws, Array(Array("as", "A", "qq", 10), Array("wqe", "B", "erw", 1.5), _
        Array("wqe", "C", "we", -3), Array("as", "D", "qq", 7), _
        Array("wqe", "B", "erw", 2.5), Array("wqe", "C", "we", 1))
End Sub

Private Sub PutRows(ByVal ws As Worksheet, ByVal rows As Variant)
    Dim values() As Variant
    Dim rowIndex As Long
    Dim columnIndex As Long
    Dim rowCount As Long
    Dim columnCount As Long
    ws.Cells.Clear
    rowCount = UBound(rows) - LBound(rows) + 1
    columnCount = UBound(rows(LBound(rows))) - LBound(rows(LBound(rows))) + 1
    ReDim values(1 To rowCount, 1 To columnCount)
    For rowIndex = 1 To rowCount
        For columnIndex = 1 To columnCount
            values(rowIndex, columnIndex) = rows(LBound(rows) + rowIndex - 1)(columnIndex - 1)
        Next columnIndex
    Next rowIndex
    ws.Cells(1, 1).Resize(rowCount, columnCount).Value2 = values
End Sub

Private Function ExpectShape(ByRef actual As Variant, ByVal expectedRows As Long, _
    ByVal expectedColumns As Long) As Boolean
    On Error GoTo WrongShape
    If Not IsArray(actual) Then GoTo WrongShape
    ExpectTrue UBound(actual, 1) = expectedRows, "result row count"
    ExpectTrue UBound(actual, 2) = expectedColumns, "result column count"
    ExpectShape = (UBound(actual, 1) = expectedRows And UBound(actual, 2) = expectedColumns)
    Exit Function
WrongShape:
    ExpectTrue False, "expected a 2D result array"
End Function

Private Sub ExpectNear(ByVal actual As Variant, ByVal expected As Double, ByVal detail As String)
    If IsError(actual) Then
        ExpectTrue False, detail & " (unexpected " & CStr(actual) & ")"
        Exit Sub
    End If
    If Not IsNumeric(actual) Then
        ExpectTrue False, detail & " (expected numeric value)"
        Exit Sub
    End If
    ExpectTrue Abs(CDbl(actual) - expected) < 0.00000001, detail & _
        " (expected " & CStr(expected) & ", got " & CStr(actual) & ")"
End Sub

Private Sub ExpectEqual(ByVal actual As Variant, ByVal expected As Variant, ByVal detail As String)
    If IsError(actual) Then
        ExpectTrue False, detail & " (unexpected " & CStr(actual) & ")"
    Else
        ExpectTrue CStr(actual) = CStr(expected), detail
    End If
End Sub

Private Sub ExpectBlank(ByVal actual As Variant, ByVal detail As String)
    If IsError(actual) Or IsArray(actual) Or IsObject(actual) Then
        ExpectTrue False, detail & " (expected blank string)"
    Else
        ExpectTrue VarType(actual) = vbString And Len(CStr(actual)) = 0, detail
    End If
End Sub

Private Sub ExpectError(ByVal actual As Variant, ByVal expectedCode As Long, ByVal detail As String)
    If IsError(actual) Then
        ExpectTrue CStr(actual) = CStr(CVErr(expectedCode)), detail
    Else
        ExpectTrue False, detail & " (expected Excel error " & expectedCode & ")"
    End If
End Sub

Private Sub ExpectTrue(ByVal condition As Boolean, ByVal detail As String)
    assertionCount = assertionCount + 1
    If Not condition Then
        failureCount = failureCount + 1
        failureLog = failureLog & vbLf & currentCase & ": " & detail
    End If
End Sub
