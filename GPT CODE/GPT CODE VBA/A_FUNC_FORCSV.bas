Attribute VB_Name = "A_FUNC_FORCSV"
Option Explicit

' Syntax:
' =FORCSV(A1)
' =FORCSV(A1:D1,E1:G1,L1)
' =FORCSV(A1:D1, ",")
' =FORCSV(A1:D1, ",", TRUE)   ' Remove blank cells
' =FORCSV(A1:D1, ",", FALSE)  ' Keep blank positions
' =FORCSV(A1:D1,E1:G1,L1,";",FALSE)
'
' Joins cells from all ranges in argument order.
' The optional separator defaults to ","; RemoveBlank defaults to TRUE.
Public Function FORCSV( _
    ByVal SourceRange As Range, _
    ParamArray AdditionalArguments() As Variant) As Variant

    Dim sourceRanges As Collection
    Dim source As Range
    Dim cell As Range
    Dim argumentValue As Variant
    Dim result As String
    Dim cellValue As Variant
    Dim separator As String
    Dim removeBlank As Boolean
    Dim hasValue As Boolean
    Dim includeCell As Boolean
    Dim isFirstOutput As Boolean
    Dim hasSeparator As Boolean
    Dim hasRemoveBlank As Boolean

    If SourceRange Is Nothing Then
        FORCSV = CVErr(xlErrRef)
        Exit Function
    End If

    Set sourceRanges = New Collection
    sourceRanges.Add SourceRange
    separator = ","
    removeBlank = True

    For Each argumentValue In AdditionalArguments
        If IsObject(argumentValue) Then
            Set source = Nothing
            On Error Resume Next
            Set source = argumentValue
            On Error GoTo 0
            If source Is Nothing Then
                FORCSV = CVErr(xlErrValue)
                Exit Function
            End If
            sourceRanges.Add source
        ElseIf VarType(argumentValue) = vbString And Not hasSeparator Then
            separator = CStr(argumentValue)
            hasSeparator = True
        ElseIf VarType(argumentValue) = vbBoolean And Not hasRemoveBlank Then
            removeBlank = CBool(argumentValue)
            hasRemoveBlank = True
        Else
            FORCSV = CVErr(xlErrValue)
            Exit Function
        End If
    Next argumentValue

    isFirstOutput = True
    For Each source In sourceRanges
        For Each cell In source.Cells
            cellValue = cell.Value2

            If IsError(cellValue) Then
                FORCSV = cellValue
                Exit Function
            End If

            hasValue = Not IsEmpty(cellValue)
            If hasValue Then hasValue = (Len(CStr(cellValue)) > 0)
            includeCell = hasValue Or Not removeBlank

            If includeCell Then
                If Not isFirstOutput Then result = result & separator
                If hasValue Then result = result & CStr(cellValue)
                isFirstOutput = False
            End If
        Next cell
    Next source

    FORCSV = result
End Function
