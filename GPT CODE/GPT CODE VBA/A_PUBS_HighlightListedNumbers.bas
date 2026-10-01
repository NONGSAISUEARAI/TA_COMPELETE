Attribute VB_Name = "A_PUBS_HighlightListedNumbers"
Option Explicit

' Select the cell containing one number or a comma/newline-separated list,
' then run this macro. Exact numeric matches in column A are highlighted from column A
' through the last used column on the same row.
Public Sub HighlightListedNumbersInColumnA()
    Dim ws As Worksheet
    Dim targetCell As Range
    Dim lastUsedCell As Range
    Dim targets As Object
    Dim targetText As String
    Dim item As Variant
    Dim cellValue As Variant
    Dim numberValue As Double
    Dim lastRow As Long
    Dim lastColumn As Long
    Dim rowNumber As Long
    Dim matchCount As Long

    Set targetCell = ActiveCell
    Set ws = targetCell.Worksheet
    cellValue = targetCell.Value2
    If IsError(cellValue) Or IsEmpty(cellValue) Then
        MsgBox "Select a cell containing one or more numbers.", vbExclamation
        Exit Sub
    End If
    targetText = Trim$(CStr(cellValue))
    If Len(targetText) = 0 Then
        MsgBox "Select a cell containing one or more numbers.", vbExclamation
        Exit Sub
    End If

    Set lastUsedCell = ws.Cells.Find( _
        What:="*", After:=ws.Range("A1"), LookIn:=xlFormulas, _
        LookAt:=xlPart, SearchOrder:=xlByColumns, _
        SearchDirection:=xlPrevious, MatchCase:=False)
    If lastUsedCell Is Nothing Then
        MsgBox "This sheet has no data.", vbInformation
        Exit Sub
    End If

    lastColumn = lastUsedCell.Column
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row

    ' Accept numbers separated by commas, semicolons, spaces, or line breaks.
    targetText = Replace(targetText, vbCrLf, ",")
    targetText = Replace(targetText, vbCr, ",")
    targetText = Replace(targetText, vbLf, ",")
    targetText = Replace(targetText, vbTab, ",")
    targetText = Replace(targetText, ";", ",")
    targetText = Replace(targetText, " ", ",")
    Set targets = CreateObject("Scripting.Dictionary")
    For Each item In Split(targetText, ",")
        If Len(CStr(item)) > 0 Then
            If Not IsNumeric(item) Then
                MsgBox "The selected cell contains an invalid number: " & CStr(item), vbExclamation
                Exit Sub
            End If
            numberValue = CDbl(item)
            If numberValue <> Fix(numberValue) Then
                MsgBox "Use whole numbers only: " & CStr(item), vbExclamation
                Exit Sub
            End If
            targets(CStr(numberValue)) = True
        End If
    Next item
    If targets.Count = 0 Then
        MsgBox "The selected cell contains no numbers.", vbExclamation
        Exit Sub
    End If

    For rowNumber = 1 To lastRow
        cellValue = ws.Cells(rowNumber, "A").Value2
        If Not IsError(cellValue) Then
            If IsNumeric(cellValue) Then
                numberValue = CDbl(cellValue)
                If numberValue = Fix(numberValue) Then
                    If targets.Exists(CStr(numberValue)) Then
                        ws.Range(ws.Cells(rowNumber, 1), _
                                 ws.Cells(rowNumber, lastColumn)).Interior.Color = RGB(255, 242, 204)
                        matchCount = matchCount + 1
                    End If
                End If
            End If
        End If
    Next rowNumber

    MsgBox "Highlighted " & matchCount & " matching rows.", vbInformation
End Sub
