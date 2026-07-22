Attribute VB_Name = "A_FUNC_copyallsheet_v2"
Option Explicit

Function copyallsheet_v2( _
    SourceRange As Range, _
    StartSheet As Variant, _
    CopySheetCount As Long)

    Dim wb As Workbook
    Dim ws As Worksheet
    Dim wsFormula As Worksheet
    Dim Result() As Variant

    Dim r As Long
    Dim c As Long
    Dim i As Long
    Dim outRow As Long
    Dim RowCount As Long
    Dim ColCount As Long
    Dim FirstRow As Long
    Dim FirstCol As Long
    Dim StartSheetIndex As Long
    Dim ActualSheetCount As Long
    Dim CellValue As Variant

    Application.Volatile True

    Set wsFormula = Application.Caller.Worksheet
    Set wb = wsFormula.Parent

    RowCount = SourceRange.Rows.Count
    ColCount = SourceRange.Columns.Count
    FirstRow = SourceRange.Row
    FirstCol = SourceRange.Column

    If CopySheetCount <= 0 Then
        copyallsheet_v2 = CVErr(xlErrValue)
        Exit Function
    End If

    'ค้นหาชีตเริ่มต้นจากชื่อชีตหรือหมายเลขลำดับชีต
    If IsNumeric(StartSheet) Then
        StartSheetIndex = CLng(StartSheet)
    Else
        For i = 1 To wb.Worksheets.Count
            If StrComp( _
                wb.Worksheets(i).Name, _
                CStr(StartSheet), _
                vbTextCompare) = 0 Then

                StartSheetIndex = i
                Exit For

            End If
        Next i
    End If

    If StartSheetIndex < 1 Or StartSheetIndex > wb.Worksheets.Count Then
        copyallsheet_v2 = CVErr(xlErrRef)
        Exit Function
    End If

    'นับจำนวนชีตที่สามารถ Copy ได้จริง โดยข้ามชีตที่วางสูตร
    For i = StartSheetIndex To wb.Worksheets.Count
        If wb.Worksheets(i).Name <> wsFormula.Name Then
            ActualSheetCount = ActualSheetCount + 1
            If ActualSheetCount = CopySheetCount Then Exit For
        End If
    Next i

    If ActualSheetCount = 0 Then
        copyallsheet_v2 = ""
        Exit Function
    End If

    ReDim Result( _
        1 To ActualSheetCount * RowCount, _
        1 To ColCount + 1)

    outRow = 1
    ActualSheetCount = 0

    'Copy ตามลำดับชีต โดยเริ่มจากชีตที่ผู้ใช้กำหนด
    For i = StartSheetIndex To wb.Worksheets.Count

        Set ws = wb.Worksheets(i)

        If ws.Name <> wsFormula.Name Then

            For r = 1 To RowCount

                Result(outRow, 1) = ws.Name

                For c = 1 To ColCount
                    CellValue = ws.Cells( _
                        FirstRow + r - 1, _
                        FirstCol + c - 1).Value2

                    'ถ้าเซลล์ไม่มีข้อมูล ให้คืนค่าเป็นข้อความว่างแทน 0
                    If IsEmpty(CellValue) Then
                        Result(outRow, c + 1) = ""
                    ElseIf IsError(CellValue) Then
                        Result(outRow, c + 1) = CellValue
                    ElseIf Len(CStr(CellValue)) = 0 Then
                        Result(outRow, c + 1) = ""
                    Else
                        Result(outRow, c + 1) = CellValue
                    End If
                Next c

                outRow = outRow + 1

            Next r

            ActualSheetCount = ActualSheetCount + 1
            If ActualSheetCount = CopySheetCount Then Exit For

        End If

    Next i

    copyallsheet_v2 = Result

End Function
