Attribute VB_Name = "A_FUNC_copyallsheet_v4"
Option Explicit

' Syntax:
' =copyallsheet_v4(SourceAddressOrRange,StartSheet,CopySheetCount,[FilterEmptyRows=0],[ShowSheetName=TRUE])
' =copyallsheet_v4("A2:D20",3,5,1,FALSE)
'
' SourceAddressOrRange: quoted A1 address (fixed text) or a real range.
' StartSheet: worksheet tab number or name. The name must not be numeric.
' CopySheetCount: number of consecutive worksheets to read from StartSheet.
' The worksheet containing the formula is skipped, as in v3.
' FilterEmptyRows: 0 = keep all rows; 1 = omit completely blank rows.
' ShowSheetName: TRUE (default) adds the worksheet name as the first column;
'                FALSE returns only the source data columns.
'
' The tab positions are intentionally used. Inserting, deleting, or moving
' tabs within the selected run changes which sheets are read.

Public Function copyallsheet_v4( _
    ByVal SourceAddressOrRange As Variant, _
    ByVal StartSheet As Variant, _
    ByVal CopySheetCount As Long, _
    Optional ByVal FilterEmptyRows As Long = 0, _
    Optional ByVal ShowSheetName As Boolean = True) As Variant

    Dim callerSheet As Worksheet
    Dim wb As Workbook
    Dim sourceArea As Range
    Dim sourceAddress As String
    Dim ws As Worksheet
    Dim startValue As Variant
    Dim startSheetIndex As Long
    Dim actualSheetCount As Long
    Dim result() As Variant
    Dim cellValue As Variant
    Dim firstRow As Long
    Dim firstColumn As Long
    Dim rowCount As Long
    Dim columnCount As Long
    Dim nameColumnCount As Long
    Dim outputRowCount As Long
    Dim outputRow As Long
    Dim i As Long
    Dim r As Long
    Dim c As Long

    On Error GoTo InvalidInput

    If CopySheetCount <= 0 Then GoTo InvalidInput
    If FilterEmptyRows <> 0 And FilterEmptyRows <> 1 Then GoTo InvalidInput

    Set callerSheet = Application.Caller.Worksheet
    Set wb = callerSheet.Parent

    If IsObject(SourceAddressOrRange) Then
        If TypeName(SourceAddressOrRange) <> "Range" Then GoTo InvalidInput
        Set sourceArea = SourceAddressOrRange
    ElseIf VarType(SourceAddressOrRange) = vbString Then
        sourceAddress = Trim$(CStr(SourceAddressOrRange))
        If Len(sourceAddress) = 0 Or InStr(1, sourceAddress, "!", vbBinaryCompare) > 0 Then
            GoTo InvalidInput
        End If
        Set sourceArea = callerSheet.Range(sourceAddress)
    Else
        GoTo InvalidInput
    End If

    If sourceArea Is Nothing Then GoTo InvalidReference
    If sourceArea.Areas.Count <> 1 Then GoTo InvalidReference
    If Not (sourceArea.Worksheet.Parent Is wb) Then GoTo InvalidReference

    If IsObject(StartSheet) Then
        If TypeName(StartSheet) <> "Range" Then GoTo InvalidInput
        If StartSheet.Cells.CountLarge <> 1 Then GoTo InvalidReference
        startValue = StartSheet.Value2
    Else
        startValue = StartSheet
    End If
    If IsError(startValue) Or IsEmpty(startValue) Then GoTo InvalidInput

    If IsNumeric(startValue) Then
        If CDbl(startValue) <> Fix(CDbl(startValue)) Then GoTo InvalidInput
        If CDbl(startValue) < 1 Or CDbl(startValue) > wb.Worksheets.Count Then
            GoTo InvalidReference
        End If
        startSheetIndex = CLng(startValue)
    Else
        For i = 1 To wb.Worksheets.Count
            If StrComp(wb.Worksheets(i).Name, CStr(startValue), vbTextCompare) = 0 Then
                startSheetIndex = i
                Exit For
            End If
        Next i
        If startSheetIndex = 0 Then GoTo InvalidReference
    End If

    Application.Volatile True

    firstRow = sourceArea.Row
    firstColumn = sourceArea.Column
    rowCount = CLng(sourceArea.Rows.CountLarge)
    columnCount = CLng(sourceArea.Columns.CountLarge)

    For i = startSheetIndex To wb.Worksheets.Count
        Set ws = wb.Worksheets(i)
        If Not (ws Is callerSheet) Then
            actualSheetCount = actualSheetCount + 1
            For r = 0 To rowCount - 1
                If FilterEmptyRows = 0 Or CopyAllSheetV4RowHasData( _
                    ws, firstRow + r, firstColumn, columnCount) Then
                    outputRowCount = outputRowCount + 1
                End If
            Next r
            If actualSheetCount = CopySheetCount Then Exit For
        End If
    Next i

    If outputRowCount = 0 Then
        copyallsheet_v4 = vbNullString
        Exit Function
    End If

    If ShowSheetName Then nameColumnCount = 1
    ReDim result(1 To outputRowCount, 1 To columnCount + nameColumnCount)
    outputRow = 1
    actualSheetCount = 0

    For i = startSheetIndex To wb.Worksheets.Count
        Set ws = wb.Worksheets(i)
        If Not (ws Is callerSheet) Then
            For r = 0 To rowCount - 1
                If FilterEmptyRows = 0 Or CopyAllSheetV4RowHasData( _
                    ws, firstRow + r, firstColumn, columnCount) Then

                    If ShowSheetName Then result(outputRow, 1) = ws.Name
                    For c = 0 To columnCount - 1
                        cellValue = ws.Cells(firstRow + r, firstColumn + c).Value2
                        If IsError(cellValue) Then
                            result(outputRow, c + 1 + nameColumnCount) = cellValue
                        ElseIf IsEmpty(cellValue) Then
                            result(outputRow, c + 1 + nameColumnCount) = vbNullString
                        ElseIf Len(CStr(cellValue)) = 0 Then
                            result(outputRow, c + 1 + nameColumnCount) = vbNullString
                        Else
                            result(outputRow, c + 1 + nameColumnCount) = cellValue
                        End If
                    Next c
                    outputRow = outputRow + 1
                End If
            Next r

            actualSheetCount = actualSheetCount + 1
            If actualSheetCount = CopySheetCount Then Exit For
        End If
    Next i

    copyallsheet_v4 = result
    Exit Function

InvalidReference:
    copyallsheet_v4 = CVErr(xlErrRef)
    Exit Function

InvalidInput:
    copyallsheet_v4 = CVErr(xlErrValue)
End Function

Private Function CopyAllSheetV4RowHasData( _
    ByVal ws As Worksheet, _
    ByVal rowNumber As Long, _
    ByVal firstColumn As Long, _
    ByVal columnCount As Long) As Boolean

    Dim cellValue As Variant
    Dim c As Long

    For c = 0 To columnCount - 1
        cellValue = ws.Cells(rowNumber, firstColumn + c).Value2
        If IsError(cellValue) Then
            CopyAllSheetV4RowHasData = True
            Exit Function
        End If
        If Not IsEmpty(cellValue) Then
            If Len(CStr(cellValue)) > 0 Then
                CopyAllSheetV4RowHasData = True
                Exit Function
            End If
        End If
    Next c
End Function
