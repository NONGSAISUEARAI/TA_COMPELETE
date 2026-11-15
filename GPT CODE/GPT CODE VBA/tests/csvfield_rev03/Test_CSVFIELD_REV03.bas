Attribute VB_Name = "Test_CSVFIELD_REV03"
Option Explicit

Private checks As Long

Public Function RunCsvFieldRev03Tests() As String
    Dim ws As Worksheet
    Dim text As String
    Dim actual As Variant
    Dim candidate As Variant
    Dim badIndexes As Variant
    Dim i As Long

    On Error GoTo Failed
    checks = 0
    Set ws = ThisWorkbook.Worksheets(1)
    text = "A, B, C, D"
    CheckEqual CSVFIELD(text, 4), "D"
    CheckEqual CSVFIELD(text, 3, 1, 3, True, " | "), "C | A | C"
    CheckEqual CSVFIELD(text, 3, 1, 3), "C,A,C"
    CheckEqual CSVFIELD(text, 2, False), " B"
    CheckEqual CSVFIELD(text, 2, False, "-"), " B"
    CheckEqual CSVFIELD(text, 3, 1, "-"), "C-A"
    CheckEqual CSVFIELD(text, 10), ""
    CheckEqual CSVFIELD("A,,C", 2, 3), ",C"
    CheckEqual CSVFIELD("A,(B,C),""D,E"",F", 2, 3, True, " | "), "(B,C) | D,E"
    CheckEqual CSVFIELD("A,""B""""C"",D", 2), "B""C"
    CheckEqual CSVFIELD(Empty, 1), ""
    CheckEqual CSVFIELD(Null, 1), ""

    ' Compare normal behavior with the original revision in the same workbook.
    CheckEqual CSVFIELD(text, 3, 1, 3, True, " | "), _
        CSVFIELD_BASELINE(text, 3, 1, 3, True, " | ")
    CheckEqual CSVFIELD(text, 2, False), CSVFIELD_BASELINE(text, 2, False)
    CheckEqual CSVFIELD("A,(B,C),""D,E"",F", 2, 3), _
        CSVFIELD_BASELINE("A,(B,C),""D,E"",F", 2, 3)

    badIndexes = Array(0, -1, 1.5, 1E+20, CVErr(xlErrNA))
    For i = LBound(badIndexes) To UBound(badIndexes)
        candidate = badIndexes(i)
        CheckHelp CSVFIELD(text, candidate)
    Next i
    CheckHelp CSVFIELD(text)
    CheckHelp CSVFIELD(text, True)
    CheckHelp CSVFIELD(text, "4")
    CheckHelp CSVFIELD(text, "bad", 1)
    CheckHelp CSVFIELD(text, 1, "-", True)
    CheckHelp CSVFIELD(Array("A", "B"), 1)
    CheckHelp CSVFIELD(ws.Range("A1:A2"), 1)
    CheckHelp CSVFIELD("A,""B,C", 1)
    CheckHelp CSVFIELD("A,(B,C", 1)
    CheckHelp CSVFIELD(CVErr(xlErrValue), 1)
    CheckHelp CSVFIELD(String$(20000, "A"), 1, 1)
    actual = CSVFIELD(CVErr(xlErrNA), 1)
    CheckEqual IsError(actual), True
    CheckEqual CStr(actual), CStr(CVErr(xlErrNA))

    ws.Range("A1").Value2 = text
    ws.Range("C1").Formula2 = "=CSVFIELD(A1,3,1,3,TRUE,"" | "")"
    ws.Range("C2").Formula2 = "=CSVFIELD(A1,0)"
    ws.Range("C3").Formula2 = "=CSVFIELD(A1)"
    ws.Range("A2").Formula2 = "=1+""bad"""
    ws.Range("C4").Formula2 = "=CSVFIELD(A2,1)"
    ws.Calculate
    CheckEqual ws.Range("C1").Value2, "C | A | C"
    CheckHelp ws.Range("C2").Value2
    CheckHelp ws.Range("C3").Value2
    CheckHelp ws.Range("C4").Value2

    RunCsvFieldRev03Tests = "PASS: " & checks & " checks, including worksheet formulas and REV02 regression"
    Exit Function
Failed:
    RunCsvFieldRev03Tests = "FAIL after " & checks & " checks: " & Err.Number & " " & Err.Description
End Function

Private Sub CheckEqual(ByVal actual As Variant, ByVal expected As Variant)
    checks = checks + 1
    If IsError(actual) Then Err.Raise vbObjectError + 1, , "Unexpected error at check " & checks
    If CStr(actual) <> CStr(expected) Then
        Err.Raise vbObjectError + 2, , "Expected [" & CStr(expected) & "] got [" & CStr(actual) & "]"
    End If
End Sub

Private Sub CheckHelp(ByVal actual As Variant)
    checks = checks + 1
    If IsError(actual) Then Err.Raise vbObjectError + 3, , "Expected usage text, got an Excel error"
    If InStr(1, CStr(actual), "CSVFIELD argument help:", vbBinaryCompare) <> 1 Then
        Err.Raise vbObjectError + 4, , "Missing help prefix"
    End If
    If InStr(1, CStr(actual), "=CSVFIELD(W2,4)", vbBinaryCompare) = 0 Then
        Err.Raise vbObjectError + 5, , "Missing formula example"
    End If
End Sub
