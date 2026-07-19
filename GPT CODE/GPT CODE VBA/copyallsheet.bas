Attribute VB_Name = "copyallsheet_module"
Option Explicit

Function copyallsheet(SourceRange As Range)

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

    ReDim Result(1 To SheetCount * RowCount, 1 To ColCount + 1)

    outRow = 1

    For Each ws In ThisWorkbook.Worksheets

        If ws.Name <> wsFormula.Name Then

            For r = 1 To RowCount

                Result(outRow, 1) = ws.Name

                For c = 1 To ColCount

                    Result(outRow, c + 1) = _
                        ws.Cells(FirstRow + r - 1, FirstCol + c - 1).Value

                Next c

                outRow = outRow + 1

            Next r

        End If

    Next ws

    copyallsheet = Result

End Function
