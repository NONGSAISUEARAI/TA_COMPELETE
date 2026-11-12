Attribute VB_Name = "Test_CountUnique_V6"
Option Explicit

Private assertionCount As Long
Private failureCount As Long
Private failureLog As String
Private currentCase As String

Public Function RunCountUniqueV6Tests() As String
    Dim ws As Worksheet

    On Error GoTo UnexpectedError
    Set ws = ThisWorkbook.Worksheets(1)
    assertionCount = 0
    failureCount = 0
    failureLog = ""

    TestScreenshotFull ws
    TestScreenshotSparse ws
    TestNoHeadingAndTwoConditions ws
    TestSortFlags ws
    TestFourAndFiveConditions ws
    TestInvalidArguments ws
    TestBlankErrorAndZeroKeys ws
    TestCaseAndTypeKeys ws
    TestMultiColumnRanges ws
    TestHeadingAndFlagReferences ws
    TestSparseDoesNotExpandProduct ws
    TestWorksheetFormula ws

    If failureCount = 0 Then
        RunCountUniqueV6Tests = "PASS: " & assertionCount & " assertions across 12 cases"
    Else
        RunCountUniqueV6Tests = "FAIL: " & failureCount & "/" & assertionCount & failureLog
    End If
    Exit Function

UnexpectedError:
    RunCountUniqueV6Tests = "FAIL: unexpected VBA error " & Err.Number & _
        " in " & currentCase & ": " & Err.Description & failureLog
End Function

Private Sub TestScreenshotFull(ByVal ws As Worksheet)
    Dim actual As Variant
    Dim groupIndex As Long
    Dim dataRow As Long
    Dim outputColumn As Long
    Dim expected As Variant

    currentCase = "screenshot full Cartesian"
    ScreenshotData ws
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 0, _
        ws.Range("B1:B6"), 0, ws.Range("C1:C6"), 0)
    If Not ExpectShape(actual, 5, 13) Then Exit Sub
    ExpectEqual actual(1, 1), "SS", "heading"
    ExpectEqual actual(4, 1), "as", "first vertical label"
    ExpectEqual actual(5, 1), "wqe", "second vertical label"

    For groupIndex = 0 To 3
        outputColumn = 2 + 3 * groupIndex
        ExpectEqual actual(2, outputColumn), Chr$(65 + groupIndex), "group header"
        ExpectBlank actual(2, outputColumn + 1), "group header spacer"
        ExpectBlank actual(2, outputColumn + 2), "group header spacer"
        ExpectEqual actual(3, outputColumn), "qq", "qq under every group"
        ExpectEqual actual(3, outputColumn + 1), "erw", "erw under every group"
        ExpectEqual actual(3, outputColumn + 2), "we", "we under every group"
    Next groupIndex

    For dataRow = 4 To 5
        For outputColumn = 2 To 13
            expected = ""
            If dataRow = 4 And (outputColumn = 2 Or outputColumn = 11) Then expected = 1
            If dataRow = 5 And (outputColumn = 6 Or outputColumn = 10) Then expected = 2
            If VarType(expected) = vbString Then
                ExpectBlank actual(dataRow, outputColumn), "unobserved count stays blank"
            Else
                ExpectEqual actual(dataRow, outputColumn), expected, "observed count"
            End If
        Next outputColumn
    Next dataRow
End Sub

Private Sub TestScreenshotSparse(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "screenshot observed tuples"
    ScreenshotData ws
    actual = COUNTUNIQUE_V6("SS", 0, ws.Range("A1:A6"), 0, _
        ws.Range("B1:B6"), 0, ws.Range("C1:C6"), 0)
    If Not ExpectShape(actual, 5, 5) Then Exit Sub
    ExpectEqual actual(2, 2), "A", "sparse A"
    ExpectEqual actual(2, 3), "B", "sparse B"
    ExpectEqual actual(2, 4), "C", "sparse C"
    ExpectEqual actual(2, 5), "D", "sparse D"
    ExpectEqual actual(3, 2), "qq", "sparse A/qq"
    ExpectEqual actual(3, 3), "erw", "sparse B/erw"
    ExpectEqual actual(3, 4), "we", "sparse C/we"
    ExpectEqual actual(3, 5), "qq", "sparse D/qq"
    ExpectEqual actual(4, 2), 1, "as A/qq"
    ExpectEqual actual(4, 5), 1, "as D/qq"
    ExpectEqual actual(5, 3), 2, "wqe B/erw"
    ExpectEqual actual(5, 4), 2, "wqe C/we"
    ExpectBlank actual(4, 3), "sparse missing count"
End Sub

Private Sub TestNoHeadingAndTwoConditions(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "empty heading and two conditions"
    ScreenshotData ws
    actual = COUNTUNIQUE_V6("", 1, ws.Range("A1:A6"), 0, _
        ws.Range("B1:B6"), 0, ws.Range("C1:C6"), 0)
    If ExpectShape(actual, 4, 13) Then
        ExpectEqual actual(1, 2), "A", "first header without title row"
        ExpectEqual actual(3, 1), "as", "first label without title row"
    End If
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    If ExpectShape(actual, 4, 5) Then
        ExpectEqual actual(2, 2), "A", "single header level"
        ExpectEqual actual(3, 1), "as", "two condition label"
        ExpectEqual actual(3, 2), 1, "two condition A total"
        ExpectEqual actual(4, 3), 2, "two condition B total"
    End If
End Sub

Private Sub TestSortFlags(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "independent sort flags"
    PutRows ws, Array(Array(20, "Z", "Y"), Array(10, "A", "X"))
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A2"), 0, _
        ws.Range("B1:B2"), 0, ws.Range("C1:C2"), 0)
    If ExpectShape(actual, 5, 5) Then
        ExpectEqual actual(4, 1), 20, "unsorted row first seen"
        ExpectEqual actual(2, 2), "Z", "unsorted group first seen"
        ExpectEqual actual(3, 2), "Y", "unsorted subheader first seen"
        ExpectEqual actual(4, 2), 1, "unsorted count"
        ExpectEqual actual(5, 5), 1, "unsorted count last"
    End If

    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A2"), 1, _
        ws.Range("B1:B2"), 1, ws.Range("C1:C2"), 1)
    If ExpectShape(actual, 5, 5) Then
        ExpectEqual actual(4, 1), 10, "numeric ascending row"
        ExpectEqual actual(2, 2), "A", "ascending group"
        ExpectEqual actual(3, 2), "X", "ascending subheader"
        ExpectEqual actual(4, 2), 1, "sorted count first"
        ExpectEqual actual(5, 5), 1, "sorted count last"
    End If

    actual = COUNTUNIQUE_V6("SS", 0, ws.Range("A1:A2"), 1, _
        ws.Range("B1:B2"), 0, ws.Range("C1:C2"), 1)
    If ExpectShape(actual, 5, 3) Then
        ExpectEqual actual(4, 1), 10, "mixed sorted row"
        ExpectEqual actual(2, 2), "Z", "mixed unsorted group"
        ExpectEqual actual(3, 2), "Y", "mixed sparse tuple first"
        ExpectEqual actual(3, 3), "X", "mixed sparse tuple second"
    End If
End Sub

Private Sub TestFourAndFiveConditions(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "four and five conditions"
    PutRows ws, Array(Array("R2", "B", "beta", "Y", "N"), _
        Array("R1", "A", "alpha", "X", "M"))
    actual = COUNTUNIQUE_V6("Deep", 1, ws.Range("A1:A2"), 1, ws.Range("B1:B2"), 1, _
        ws.Range("C1:C2"), 1, ws.Range("D1:D2"), 1)
    If ExpectShape(actual, 6, 9) Then
        ExpectEqual actual(2, 2), "A", "deep outer A"
        ExpectEqual actual(2, 6), "B", "deep outer B"
        ExpectBlank actual(2, 3), "deep outer spacer"
        ExpectEqual actual(3, 2), "alpha", "deep middle alpha"
        ExpectEqual actual(3, 4), "beta", "deep middle beta"
        ExpectEqual actual(3, 6), "alpha", "deep middle repeats under B"
        ExpectBlank actual(3, 3), "deep middle spacer"
        ExpectEqual actual(4, 2), "X", "third horizontal level"
        ExpectEqual actual(4, 3), "Y", "third horizontal level next"
        ExpectEqual actual(5, 2), 1, "deep first count"
        ExpectEqual actual(6, 9), 1, "deep last count"
        ExpectBlank actual(5, 3), "deep missing count"
    End If
    actual = COUNTUNIQUE_V6("Deeper", 1, ws.Range("A1:A2"), 1, ws.Range("B1:B2"), 1, _
        ws.Range("C1:C2"), 1, ws.Range("D1:D2"), 1, ws.Range("E1:E2"), 1)
    If ExpectShape(actual, 7, 17) Then
        ExpectEqual actual(5, 2), "M", "fourth horizontal level"
        ExpectEqual actual(5, 3), "N", "fourth horizontal level next"
        ExpectEqual actual(6, 2), 1, "five conditions first count"
        ExpectEqual actual(7, 17), 1, "five conditions last count"
    End If
End Sub

Private Sub TestInvalidArguments(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "invalid arguments"
    ScreenshotData ws
    actual = COUNTUNIQUE_V6("SS", 1)
    ExpectError actual, xlErrValue, "no range/sort pairs"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 0)
    ExpectError actual, xlErrValue, "only one range/sort pair"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 0, ws.Range("B1:B6"))
    ExpectError actual, xlErrValue, "odd number of pair arguments"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 2, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "invalid sort flag"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 1E+20, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "sort flag cannot overflow CLng"
    actual = COUNTUNIQUE_V6("SS", 2, ws.Range("A1:A6"), 0, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "invalid empty mode"
    actual = COUNTUNIQUE_V6("SS", 1, "A1:A6", 0, ws.Range("B1:B6"), 0)
    ExpectError actual, xlErrValue, "range text is not a Range object"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A6"), 0, ws.Range("B1:B5"), 0)
    ExpectError actual, xlErrRef, "mismatched range lengths"
    actual = COUNTUNIQUE_V6("SS", 1, Application.Union(ws.Range("A1:A3"), _
        ws.Range("A5:A6")), 0, ws.Range("B1:B5"), 0)
    ExpectError actual, xlErrRef, "multi-area range"
End Sub

Private Sub TestBlankErrorAndZeroKeys(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "blank/error source keys and numeric zero"
    PutRows ws, Array(Array(0, 0), Array("x", 0), Array("", "A"), _
        Array("z", CVErr(xlErrNA)), Array("m", ""))
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A5"), 0, ws.Range("B1:B5"), 0)
    If ExpectShape(actual, 4, 2) Then
        ExpectEqual actual(2, 2), 0, "numeric zero group retained"
        ExpectEqual actual(3, 1), 0, "numeric zero vertical label retained"
        ExpectEqual actual(3, 2), 1, "numeric zero count"
        ExpectEqual actual(4, 1), "x", "second valid row retained"
        ExpectEqual actual(4, 2), 1, "second valid row count"
    End If
    ws.Cells.Clear
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A5"), 0, ws.Range("B1:B5"), 0)
    ExpectBlank actual, "empty dataset returns empty string"
End Sub

Private Sub TestCaseAndTypeKeys(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "case-insensitive and type-aware keys"
    PutRows ws, Array(Array("a", "b", "c"), Array("A", "B", "C"))
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A2"), 0, _
        ws.Range("B1:B2"), 0, ws.Range("C1:C2"), 0)
    If ExpectShape(actual, 4, 2) Then
        ExpectEqual actual(4, 2), 2, "case-insensitive matching"
    End If
    PutRows ws, Array(Array(1, "B"), Array(1, "B"))
    ws.Range("A1").NumberFormat = "@"
    ws.Range("A1").Value2 = "1"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A2"), 0, ws.Range("B1:B2"), 0)
    If ExpectShape(actual, 4, 2) Then
        ExpectTrue VarType(actual(3, 1)) = vbString, "text numeric key remains text"
        ExpectTrue VarType(actual(4, 1)) <> vbString, "numeric key remains numeric"
        ExpectEqual actual(3, 2), 1, "text key count"
        ExpectEqual actual(4, 2), 1, "numeric key count"
    End If
End Sub

Private Sub TestMultiColumnRanges(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "contiguous multi-column ranges flatten row-major"
    ws.Cells.Clear
    ws.Range("A1").Value2 = "R1"
    ws.Range("B1").Value2 = "R2"
    ws.Range("A2").Value2 = "R1"
    ws.Range("B2").Value2 = "R2"
    ws.Range("D1").Value2 = "A"
    ws.Range("E1").Value2 = "A"
    ws.Range("D2").Value2 = "B"
    ws.Range("E2").Value2 = "B"
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:B2"), 0, ws.Range("D1:E2"), 0)
    If ExpectShape(actual, 4, 3) Then
        ExpectEqual actual(3, 2), 1, "row-major R1/A"
        ExpectEqual actual(3, 3), 1, "row-major R1/B"
        ExpectEqual actual(4, 2), 1, "row-major R2/A"
        ExpectEqual actual(4, 3), 1, "row-major R2/B"
    End If
End Sub

Private Sub TestHeadingAndFlagReferences(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "heading and flags supplied as single-cell references"
    ScreenshotData ws
    ws.Range("H1").Value2 = "Heading from cell"
    ws.Range("H2").Value2 = 1
    ws.Range("H3").Value2 = 0
    actual = COUNTUNIQUE_V6(ws.Range("H1"), ws.Range("H2"), _
        ws.Range("A1:A6"), ws.Range("H3"), ws.Range("B1:B6"), ws.Range("H3"))
    If ExpectShape(actual, 4, 5) Then
        ExpectEqual actual(1, 1), "Heading from cell", "heading reference"
        ExpectEqual actual(3, 2), 1, "flag references"
    End If
End Sub

Private Sub TestSparseDoesNotExpandProduct(ByVal ws As Worksheet)
    Dim actual As Variant
    Dim values(1 To 129, 1 To 3) As Variant
    Dim i As Long

    currentCase = "sparse high-cardinality and full-product limit"
    ws.Cells.Clear
    For i = 1 To 129
        values(i, 1) = "R"
        values(i, 2) = "G" & Format$(i, "000")
        values(i, 3) = "S" & Format$(i, "000")
    Next i
    ws.Range("A1:C129").Value2 = values
    actual = COUNTUNIQUE_V6("SS", 0, ws.Range("A1:A129"), 0, _
        ws.Range("B1:B129"), 0, ws.Range("C1:C129"), 0)
    If ExpectShape(actual, 4, 130) Then
        ExpectEqual actual(4, 2), 1, "sparse first diagonal"
        ExpectEqual actual(4, 130), 1, "sparse last diagonal"
    End If
    actual = COUNTUNIQUE_V6("SS", 1, ws.Range("A1:A129"), 0, _
        ws.Range("B1:B129"), 0, ws.Range("C1:C129"), 0)
    ExpectError actual, xlErrNum, "full product exceeds Excel columns"
End Sub

Private Sub TestWorksheetFormula(ByVal ws As Worksheet)
    Dim actual As Variant

    currentCase = "actual worksheet formula and dynamic spill"
    ScreenshotData ws
    ws.Range("K1").Formula2 = "=COUNTUNIQUE_V6(""SS"",1,A1:A6,0,B1:B6,0,C1:C6,0)"
    ws.Calculate
    ExpectEqual ws.Range("K1").Value2, "SS", "worksheet heading"
    ExpectEqual ws.Range("L2").Value2, "A", "worksheet header"
    ExpectEqual ws.Range("L4").Value2, 1, "worksheet count A/qq"
    ExpectEqual ws.Range("U4").Value2, 1, "worksheet count D/qq"
    ExpectEqual ws.Range("P5").Value2, 2, "worksheet count B/erw"
    ExpectEqual ws.Range("T5").Value2, 2, "worksheet count C/we"
    ExpectBlank ws.Range("M4").Value2, "worksheet missing count remains blank"
    actual = ws.Range("K1").SpillingToRange.Value2
    ExpectShape actual, 5, 13

    ws.Range("K1").Formula2 = "=COUNTUNIQUE_V6(""SS"",0,A1:A6,0,B1:B6,0,C1:C6,0)"
    ws.Calculate
    ExpectEqual ws.Range("K1").Value2, "SS", "sparse worksheet heading"
    ExpectEqual ws.Range("L2").Value2, "A", "sparse worksheet header A"
    ExpectEqual ws.Range("O2").Value2, "D", "sparse worksheet header D"
    ExpectEqual ws.Range("L4").Value2, 1, "sparse worksheet count A/qq"
    ExpectEqual ws.Range("O4").Value2, 1, "sparse worksheet count D/qq"
    ExpectEqual ws.Range("M5").Value2, 2, "sparse worksheet count B/erw"
    ExpectEqual ws.Range("N5").Value2, 2, "sparse worksheet count C/we"
    ExpectBlank ws.Range("M4").Value2, "sparse worksheet missing count remains blank"
    actual = ws.Range("K1").SpillingToRange.Value2
    ExpectShape actual, 5, 5
End Sub

Private Sub ScreenshotData(ByVal ws As Worksheet)
    PutRows ws, Array(Array("as", "A", "qq"), Array("wqe", "B", "erw"), _
        Array("wqe", "C", "we"), Array("as", "D", "qq"), _
        Array("wqe", "B", "erw"), Array("wqe", "C", "we"))
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

Private Sub ExpectEqual(ByVal actual As Variant, ByVal expected As Variant, ByVal detail As String)
    If IsError(actual) Then
        ExpectTrue False, detail & " (unexpected " & CStr(actual) & ")"
    Else
        ExpectTrue CStr(actual) = CStr(expected), detail & _
            " (expected " & CStr(expected) & ", got " & CStr(actual) & ")"
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
