Attribute VB_Name = "A_FUNC_FORCSV"
Option Explicit

' Syntax:
' =FORCSV(A1:D1, ",")
' =FORCSV(A1:D1, ",", TRUE)   ' Remove blank cells
' =FORCSV(A1:D1, ",", FALSE)  ' Keep blank positions
'
' Joins non-blank cells in source order using Argument as the separator.
' RemoveBlank defaults to TRUE for backward compatibility.
Public Function FORCSV( _
    ByVal SourceRange As Range, _
    Optional ByVal Argument As String = ",", _
    Optional ByVal RemoveBlank As Boolean = True) As Variant

    Dim cell As Range
    Dim result As String
    Dim cellValue As Variant
    Dim hasValue As Boolean
    Dim includeCell As Boolean
    Dim isFirstOutput As Boolean

    If SourceRange Is Nothing Then
        FORCSV = CVErr(xlErrRef)
        Exit Function
    End If

    isFirstOutput = True

    For Each cell In SourceRange.Cells
        cellValue = cell.Value2

        If IsError(cellValue) Then
            FORCSV = cellValue
            Exit Function
        End If

        hasValue = Not IsEmpty(cellValue)
        If hasValue Then hasValue = (Len(CStr(cellValue)) > 0)
        includeCell = hasValue Or Not RemoveBlank

        If includeCell Then
            If Not isFirstOutput Then result = result & Argument
            If hasValue Then result = result & CStr(cellValue)
            isFirstOutput = False
        End If
    Next cell

    FORCSV = result
End Function
