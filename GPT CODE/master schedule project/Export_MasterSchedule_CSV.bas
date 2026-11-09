Attribute VB_Name = "MasterScheduleCSV"
Option Explicit

' Export only. Does not change cells or save the source workbook.
Public Sub ExportMasterScheduleCSV()
    On Error GoTo Failed
    Dim wb As Object, ws As Object, headers As Variant
    Dim rows As Collection, planCodes As Object, parents As Object
    Dim output As String, destination As Variant, stream As Object
    Dim csvLines() As String, lineNumber As Long
    Dim lastRow As Long, r As Long, c As Long, level As Long
    Dim rootNumber As Long, counts(0 To 15) As Long, i As Long
    Dim projectCode As String, newProject As String, description As String
    Dim code As String, track As String, parentCode As String, hasWBS As Boolean, databaseRow As Boolean, dbCounter As Long
    Dim values As Variant, item As Variant, key As Variant, pieces As Variant

    Set wb = ActiveWorkbook
    If wb Is Nothing Then Err.Raise vbObjectError + 101, , "Open the source workbook first."
    Set ws = wb.Worksheets("Programm Database")
    headers = Array("PJ", "Project Works", "Group Drawing", "Product", "Description", MSCInfoHeader(), "Man", "Unit", "Quantity", "Status", "Action", "Shop Drawing Start Date", "Shop Drawing End Date", "Shop Dwg. Approved", "Remark", "Duration", "WBS", "Plan / Actual", "Node Type", "Task ID", "Project ID", "Product ID")
    For c = 1 To 16
        If MSCHeader(CStr(ws.Cells(4, c).Value2)) <> MSCHeader(CStr(headers(c - 1))) Then
            Err.Raise vbObjectError + 102, , "Header mismatch at " & ws.Cells(4, c).Address(False, False) & ". Keep the reference columns A:P and header row 4."
        End If
    Next c
    hasWBS = (MSCHeader(CStr(ws.Cells(4, 17).Value2)) = "wbs" And MSCHeader(CStr(ws.Cells(4, 18).Value2)) = "plan/actual")
    If (MSCHeader(CStr(ws.Cells(4, 17).Value2)) = "wbs") Xor (MSCHeader(CStr(ws.Cells(4, 18).Value2)) = "plan/actual") Then Err.Raise vbObjectError + 116, , "Both Q=WBS and R=Plan / Actual are required together."
    lastRow = ws.Cells(ws.Rows.Count, 5).End(-4162).Row
    If lastRow < 5 Then Err.Raise vbObjectError + 103, , "No Description rows found."
    If lastRow > 40004 Then Err.Raise vbObjectError + 104, , "Too many rows. Export no more than 40,000 data rows."
    Set rows = New Collection
    Set planCodes = CreateObject("Scripting.Dictionary")
    Set parents = CreateObject("Scripting.Dictionary")

    For r = 5 To lastRow
        description = Trim$(CStr(ws.Cells(r, 5).Value2))
        If Len(description) > 0 Then
            ReDim values(0 To 21)
            For c = 1 To 15
                If IsError(ws.Cells(r, c).Value2) Then Err.Raise vbObjectError + 105, , "Excel error at " & ws.Cells(r, c).Address(False, False)
                If c = 12 Or c = 13 Or c = 14 Then
                    values(c - 1) = MSCDate(ws.Cells(r, c).Value2, CBool(wb.Date1904), ws.Cells(r, c).Address(False, False))
                ElseIf c = 9 Then
                    If Len(CStr(ws.Cells(r, c).Value2)) > 0 Then
                        If Not IsNumeric(ws.Cells(r, c).Value2) Then Err.Raise vbObjectError + 106, , "Quantity must be numeric at I" & r
                        If CDbl(ws.Cells(r, c).Value2) < 0 Then Err.Raise vbObjectError + 107, , "Quantity cannot be negative at I" & r
                        values(c - 1) = Replace(CStr(CDbl(ws.Cells(r, c).Value2)), Application.DecimalSeparator, ".")
                    End If
                Else
                    values(c - 1) = CStr(ws.Cells(r, c).Value2)
                End If
            Next c
            databaseRow = True
            For c = 0 To 4
                If Len(Trim$(CStr(values(c)))) = 0 Then databaseRow = False
            Next c
            For c = 19 To 22
                If MSCHeader(CStr(ws.Cells(4, c).Value2)) = MSCHeader(CStr(headers(c - 1))) Then
                    If IsError(ws.Cells(r, c).Value2) Then Err.Raise vbObjectError + 118, , "Invalid metadata at row " & r
                    values(c - 1) = CStr(ws.Cells(r, c).Value2)
                End If
            Next c
            values(4) = description
            ' P Duration is derived by Master Schedule, so leave it blank.
            values(15) = ""
            If hasWBS Then
                code = Trim$(CStr(ws.Cells(r, 17).Value2))
                Do While Left$(code, 1) = "'": code = Mid$(code, 2): Loop
                track = Trim$(CStr(ws.Cells(r, 18).Value2))
                If LCase$(track) <> "plan" And LCase$(track) <> "actual" Then Err.Raise vbObjectError + 108, , "R" & r & " must be Plan or Actual."
                If Len(code) = 0 Then Err.Raise vbObjectError + 109, , "Missing WBS at Q" & r
            ElseIf databaseRow Then
                dbCounter = dbCounter + 1
                code = CStr(1000000 + dbCounter)
                track = "Plan"
                values(18) = "Task"
            Else
                newProject = Trim$(CStr(values(0)))
                If Len(newProject) > 0 And newProject <> projectCode Then
                    If Len(projectCode) = 0 And counts(0) > rootNumber Then rootNumber = counts(0)
                    rootNumber = rootNumber + 1
                    projectCode = newProject
                    For i = 0 To 15: counts(i) = 0: Next i
                    Dim projectValues As Variant
                    ReDim projectValues(0 To 21)
                    projectValues(0) = projectCode
                    projectValues(4) = projectCode
                    projectValues(16) = CStr(rootNumber)
                    projectValues(17) = "Plan"
                    rows.Add projectValues
                    planCodes.Add CStr(rootNumber), True
                End If
                level = CLng(ws.Cells(r, 5).IndentLevel)
                If level < 0 Or level > 15 Then Err.Raise vbObjectError + 110, , "Unsupported Description indent at E" & r
                counts(level) = counts(level) + 1
                For i = level + 1 To 15: counts(i) = 0: Next i
                code = ""
                If Len(projectCode) > 0 Then code = CStr(rootNumber)
                For i = 0 To level
                    If counts(i) = 0 Then Err.Raise vbObjectError + 111, , "Missing parent indent before E" & r
                    If Len(code) > 0 Then code = code & "."
                    code = code & CStr(counts(i))
                Next i
                If Len(projectCode) > 0 Then values(0) = projectCode
                track = "Plan"
            End If
            values(16) = code
            values(17) = track
            If LCase$(track) = "plan" Then
                If planCodes.Exists(code) Then Err.Raise vbObjectError + 112, , "Duplicate Plan WBS: " & code
                planCodes.Add code, True
            End If
            rows.Add values
        End If
    Next r
    If rows.Count = 0 Then Err.Raise vbObjectError + 113, , "No rows to export."
    For Each key In planCodes.Keys
        pieces = Split(CStr(key), ".")
        If UBound(pieces) > 0 Then
            parentCode = Left$(CStr(key), InStrRev(CStr(key), ".") - 1)
            parents(parentCode) = True
        End If
    Next key
    ReDim csvLines(0 To rows.Count)
    csvLines(0) = MSCLine(headers)
    lineNumber = 0
    For Each item In rows
        code = CStr(item(16))
        If Not planCodes.Exists(code) Then Err.Raise vbObjectError + 114, , "Actual WBS has no Plan: " & code
        If Len(CStr(item(18))) > 0 Then
            If LCase$(CStr(item(18))) <> "group" And LCase$(CStr(item(18))) <> "section" And LCase$(CStr(item(18))) <> "task" Then Err.Raise vbObjectError + 119, , "Invalid Node Type for " & code
        ElseIf Len(CStr(item(0))) > 0 And Len(CStr(item(1))) > 0 And Len(CStr(item(2))) > 0 And Len(CStr(item(3))) > 0 Then
            item(18) = "Task"
        ElseIf InStr(code, ".") = 0 Then
            item(18) = "Group"
        ElseIf parents.Exists(code) Then
            item(18) = "Section"
        Else
            item(18) = "Task"
        End If
        lineNumber = lineNumber + 1
        csvLines(lineNumber) = MSCLine(item)
    Next item
    output = Join(csvLines, vbCrLf) & vbCrLf
    destination = Application.GetSaveAsFilename("Master_Schedule_" & Format$(Date, "yyyy-mm-dd") & ".csv", "CSV UTF-8 (*.csv),*.csv")
    If VarType(destination) = vbBoolean Then Exit Sub
    If LCase$(Right$(CStr(destination), 4)) <> ".csv" Then destination = CStr(destination) & ".csv"
    If Len(Dir$(CStr(destination))) > 0 Then
        If MsgBox("Replace the existing CSV file?", vbYesNo + vbQuestion, "Master Schedule") <> vbYes Then Exit Sub
    End If
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 2
    stream.Charset = "utf-8"
    stream.Open
    stream.WriteText output
    If stream.Size > 10 * 1024 * 1024 Then Err.Raise vbObjectError + 117, , "CSV exceeds the 10 MB import limit. Export a smaller work list."
    stream.SaveToFile CStr(destination), 2
    stream.Close
    MsgBox "Exported " & rows.Count & " rows to UTF-8 CSV. Import this file in Master Schedule.", vbInformation, "Master Schedule"
    Exit Sub
Failed:
    Dim failureMessage As String
    failureMessage = Err.Description
    On Error Resume Next
    If Not stream Is Nothing Then stream.Close
    MsgBox failureMessage, vbExclamation, "Master Schedule CSV"
End Sub

Private Function MSCLine(ByVal values As Variant) As String
    Dim c As Long, text As String, output As String
    For c = LBound(values) To UBound(values)
        If IsEmpty(values(c)) Or IsNull(values(c)) Then text = "" Else text = CStr(values(c))
        ' Reversible text escape: also protect literal leading apostrophes.
        If c = 16 And Len(text) > 0 And IsNumeric(Left$(text, 1)) Then
            text = "'" & text
        ElseIf Len(text) > 0 Then
            If InStr(1, "=+-@'", Left$(text, 1), vbBinaryCompare) > 0 Then text = "'" & text
        End If
        If c > LBound(values) Then output = output & ","
        output = output & Chr$(34) & Replace(text, Chr$(34), Chr$(34) & Chr$(34)) & Chr$(34)
    Next c
    MSCLine = output
End Function

Private Function MSCHeader(ByVal value As String) As String
    MSCHeader = LCase$(Replace(Replace(Replace(Replace(value, " ", ""), vbCr, ""), vbLf, ""), ChrW(160), ""))
End Function

Private Function MSCDate(ByVal value As Variant, ByVal date1904 As Boolean, ByVal address As String) As String
    Dim number As Double, dayValue As Date, parts As Variant
    Dim y As Long, m As Long, d As Long, text As String
    If IsEmpty(value) Or Len(CStr(value)) = 0 Then Exit Function
    If IsNumeric(value) Then
        number = CDbl(value)
        If (Not date1904 And number < 1) Or number < 0 Then GoTo InvalidDate
        If Not date1904 And Fix(number) = 60 Then GoTo InvalidDate
        If date1904 Then
            dayValue = DateAdd("d", Fix(number), DateSerial(1904, 1, 1))
        ElseIf number < 60 Then
            dayValue = DateAdd("d", Fix(number), DateSerial(1899, 12, 31))
        Else
            dayValue = DateAdd("d", Fix(number), DateSerial(1899, 12, 30))
        End If
    Else
        text = Trim$(CStr(value))
        parts = Split(Replace(text, "/", "-"), "-")
        If UBound(parts) <> 2 Then GoTo InvalidDate
        If Len(parts(0)) = 4 Then
            y = CLng(parts(0)): m = CLng(parts(1)): d = CLng(parts(2))
        ElseIf Len(parts(2)) = 4 Then
            d = CLng(parts(0)): m = CLng(parts(1)): y = CLng(parts(2))
        Else
            GoTo InvalidDate
        End If
        dayValue = DateSerial(y, m, d)
        If Year(dayValue) <> y Or Month(dayValue) <> m Or Day(dayValue) <> d Then GoTo InvalidDate
    End If
    MSCDate = Format$(dayValue, "yyyy-mm-dd")
    Exit Function
InvalidDate:
    Err.Raise vbObjectError + 115, , "Invalid date at " & address & ". Use an Excel date or yyyy-mm-dd / dd/mm/yyyy (Gregorian)."
End Function

Private Function MSCInfoHeader() As String
    MSCInfoHeader = ChrW(&HE02) & ChrW(&HE49) & ChrW(&HE2D) & ChrW(&HE21) & ChrW(&HE39) & ChrW(&HE25) & ChrW(&HE1B) & ChrW(&HE31) & ChrW(&HE08) & ChrW(&HE08) & ChrW(&HE38) & ChrW(&HE1A) & ChrW(&HE31) & ChrW(&HE19)
End Function
