Attribute VB_Name = "A_PUBS_NumberSelectedTextTopDown"
Option Explicit

' Select one column of text cells, then run this macro.
' Nonblank text is replaced with 1, 2, 3... from top to bottom.
' Blank cells and cells that already contain numbers are left unchanged.
Public Sub NumberSelectedTextTopDown()
    Dim selectedCells As Range
    Dim cell As Range
    Dim cellValue As Variant
    Dim nextNumber As Long

    If TypeName(Selection) <> "Range" Then
        MsgBox "Select one column of text cells first.", vbExclamation
        Exit Sub
    End If

    Set selectedCells = Selection
    If selectedCells.Areas.Count <> 1 Or selectedCells.Columns.Count <> 1 Then
        MsgBox "Select one continuous column only.", vbExclamation
        Exit Sub
    End If

    nextNumber = 1
    For Each cell In selectedCells.Cells
        cellValue = cell.Value2
        If Not IsError(cellValue) Then
            If VarType(cellValue) = vbString Then
                If Len(Trim$(CStr(cellValue))) > 0 Then
                    cell.Value2 = nextNumber
                    nextNumber = nextNumber + 1
                End If
            End If
        End If
    Next cell

    MsgBox "Numbered " & (nextNumber - 1) & " cells.", vbInformation
End Sub
