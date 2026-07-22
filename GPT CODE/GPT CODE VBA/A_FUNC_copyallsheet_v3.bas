Attribute VB_Name = "A_FUNC_copyallsheet_v3"
Option Explicit

' Syntax:
' =copyallsheet_v3(SourceRange, StartSheet, CopySheetCount, [FilterEmptyRows])
'
' FilterEmptyRows:
' 0 = keep every row (default)
' 1 = remove a row when every cell in SourceRange columns is blank
Public Function copyallsheet_v3( _
    ByVal SourceRange As Range, _
    ByVal StartSheet As Variant, _
    ByVal CopySheetCount As Long, _
    Optional ByVal FilterEmptyRows As Long = 0) As Variant

    Dim wb As Workbook
    Dim ws As Worksheet
    Dim wsFormula As Worksheet
    Dim result() As Variant
    Dim cellValue As Variant
    Dim startSheetIndex As Long
    Dim actualSheetCount As Long
    Dim outputRowCount As Long
    Dim outputRow As Long
    Dim rowCount As Long
    Dim columnCount As Long
    Dim firstRow As Long
    Dim firstColumn As Long
    Dim i As Long
    Dim r As Long
    Dim c As Long

    Application.Volatile True

    Set wsFormula = Application.Caller.Worksheet
    Set wb = wsFormula.Parent

    If CopySheetCount <= 0 Then
        copyallsheet_v3 = CVErr(xlErrValue)
        Exit Function
    End If

    If FilterEmptyRows <> 0 And FilterEmptyRows <> 1 Then
        copyallsheet_v3 = CVErr(xlErrValue)
        Exit Function
    End If

    rowCount = SourceRange.Rows.Count
    columnCount = SourceRange.Columns.Count
    firstRow = SourceRange.Row
    firstColumn = SourceRange.Column

    If IsNumeric(StartSheet) Then
        startSheetIndex = CLng(StartSheet)
    Else
        For i = 1 To wb.Worksheets.Count
            If StrComp( _
                wb.Worksheets(i).Name, _
                CStr(StartSheet), _
                vbTextCompare) = 0 Then

                startSheetIndex = i
                Exit For
            End If
        Next i
    End If

    If startSheetIndex < 1 Or startSheetIndex > wb.Worksheets.Count Then
        copyallsheet_v3 = CVErr(xlErrRef)
        Exit Function
    End If

    ' Count the exact number of output rows before creating the spill array.
    For i = startSheetIndex To wb.Worksheets.Count
        Set ws = wb.Worksheets(i)

        If ws.Name <> wsFormula.Name Then
            actualSheetCount = actualSheetCount + 1

            If FilterEmptyRows = 1 Then
                For r = 1 To rowCount
                    If CopyAllSheetV3RowHasData( _
                        ws, _
                        firstRow + r - 1, _
                        firstColumn, _
                        columnCount) Then

                        outputRowCount = outputRowCount + 1
                    End If
                Next r
            Else
                outputRowCount = outputRowCount + rowCount
            End If

            If actualSheetCount = CopySheetCount Then Exit For
        End If
    Next i

    If actualSheetCount = 0 Or outputRowCount = 0 Then
        copyallsheet_v3 = ""
        Exit Function
    End If

    ReDim result(1 To outputRowCount, 1 To columnCount + 1)

    outputRow = 1
    actualSheetCount = 0

    For i = startSheetIndex To wb.Worksheets.Count
        Set ws = wb.Worksheets(i)

        If ws.Name <> wsFormula.Name Then
            For r = 1 To rowCount
                If FilterEmptyRows = 0 Or CopyAllSheetV3RowHasData( _
                    ws, _
                    firstRow + r - 1, _
                    firstColumn, _
                    columnCount) Then

                    result(outputRow, 1) = ws.Name

                    For c = 1 To columnCount
                        cellValue = ws.Cells( _
                            firstRow + r - 1, _
                            firstColumn + c - 1).Value2

                        If IsEmpty(cellValue) Then
                            result(outputRow, c + 1) = ""
                        ElseIf IsError(cellValue) Then
                            result(outputRow, c + 1) = cellValue
                        ElseIf Len(CStr(cellValue)) = 0 Then
                            result(outputRow, c + 1) = ""
                        Else
                            result(outputRow, c + 1) = cellValue
                        End If
                    Next c

                    outputRow = outputRow + 1
                End If
            Next r

            actualSheetCount = actualSheetCount + 1
            If actualSheetCount = CopySheetCount Then Exit For
        End If
    Next i

    copyallsheet_v3 = result
End Function

Private Function CopyAllSheetV3RowHasData( _
    ByVal ws As Worksheet, _
    ByVal rowNumber As Long, _
    ByVal firstColumn As Long, _
    ByVal columnCount As Long) As Boolean

    Dim cellValue As Variant
    Dim c As Long

    For c = 0 To columnCount - 1
        cellValue = ws.Cells(rowNumber, firstColumn + c).Value2

        If IsError(cellValue) Then
            CopyAllSheetV3RowHasData = True
            Exit Function
        End If

        If Len(CStr(cellValue)) > 0 Then
            CopyAllSheetV3RowHasData = True
            Exit Function
        End If
    Next c
End Function
