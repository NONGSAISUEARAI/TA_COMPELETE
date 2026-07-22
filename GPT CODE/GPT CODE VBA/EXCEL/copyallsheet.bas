Attribute VB_Name = "copyallsheet"
Option Explicit

Function copyallsheet( _
    SourceRange As Range, _
    Optional FilterEmptyRows As Long = 0)

    Dim ws As Worksheet
    Dim wsFormula As Worksheet
    Dim Result() As Variant
    Dim r As Long
    Dim c As Long
    Dim outRow As Long
    Dim RowCount As Long
    Dim ColCount As Long
    Dim SheetCount As Long
    Dim FirstRow As Long
    Dim FirstCol As Long
    Dim OutputRowCount As Long

    If FilterEmptyRows <> 0 And FilterEmptyRows <> 1 Then
        copyallsheet = CVErr(xlErrValue)
        Exit Function
    End If

    Set wsFormula = Application.Caller.Worksheet

    RowCount = SourceRange.Rows.Count
    ColCount = SourceRange.Columns.Count

    FirstRow = SourceRange.Row
    FirstCol = SourceRange.Column

    SheetCount = ThisWorkbook.Worksheets.Count - 1

    If SheetCount <= 0 Then
        copyallsheet = ""
        Exit Function
    End If

    If FilterEmptyRows = 1 Then

        For Each ws In ThisWorkbook.Worksheets

            If ws.Name <> wsFormula.Name Then

                For r = 1 To RowCount

                    If CopyAllSheetRowHasData( _
                        ws, _
                        FirstRow + r - 1, _
                        FirstCol, _
                        ColCount) Then

                        OutputRowCount = OutputRowCount + 1
                    End If

                Next r

            End If

        Next ws

    Else
        OutputRowCount = SheetCount * RowCount
    End If

    If OutputRowCount = 0 Then
        copyallsheet = ""
        Exit Function
    End If

    ReDim Result(1 To OutputRowCount, 1 To ColCount + 1)

    outRow = 1

    For Each ws In ThisWorkbook.Worksheets

        If ws.Name <> wsFormula.Name Then

            For r = 1 To RowCount

                If FilterEmptyRows = 0 Or CopyAllSheetRowHasData( _
                    ws, _
                    FirstRow + r - 1, _
                    FirstCol, _
                    ColCount) Then

                    Result(outRow, 1) = ws.Name

                    For c = 1 To ColCount

                        Result(outRow, c + 1) = _
                            ws.Cells( _
                                FirstRow + r - 1, _
                                FirstCol + c - 1).Value

                    Next c

                    outRow = outRow + 1

                End If

            Next r

        End If

    Next ws

    copyallsheet = Result

End Function

Private Function CopyAllSheetRowHasData( _
    ByVal ws As Worksheet, _
    ByVal RowNumber As Long, _
    ByVal FirstColumn As Long, _
    ByVal ColumnCount As Long) As Boolean

    Dim cellValue As Variant
    Dim c As Long

    For c = 0 To ColumnCount - 1
        cellValue = ws.Cells(RowNumber, FirstColumn + c).Value2

        If IsError(cellValue) Then
            CopyAllSheetRowHasData = True
            Exit Function
        End If

        If Len(CStr(cellValue)) > 0 Then
            CopyAllSheetRowHasData = True
            Exit Function
        End If
    Next c

End Function
