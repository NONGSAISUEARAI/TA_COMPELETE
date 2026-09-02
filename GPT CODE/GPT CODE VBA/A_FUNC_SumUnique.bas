Attribute VB_Name = "A_FUNC_SumUnique"
Option Explicit

' Returns a two-column spill array:
' Column 1 = Unique List
' Column 2 = Total Value
'
' Examples:
' =SUMUNIQUE(A1:A20,,0)
' =SUMUNIQUE(A1:A20,B1:B20,1)
' SortFlag: 1 = sort ascending, 0 = keep source order
Public Function SUMUNIQUE( _
    ByVal UniqueRange As Range, _
    Optional ByVal SumRange As Range, _
    Optional ByVal SortFlag As Variant = 0) As Variant

    Dim dict As Object
    Dim uniqueValues As Collection
    Dim result() As Variant
    Dim keyValue As Variant
    Dim sumValue As Variant
    Dim dictKey As String
    Dim sortValue As Long
    Dim i As Long

    If Not TryGetSumUniqueSortFlag(SortFlag, sortValue) Then
        SUMUNIQUE = CVErr(xlErrValue)
        Exit Function
    End If

    If SumRange Is Nothing Then
        Set SumRange = UniqueRange
    End If

    If UniqueRange.Cells.CountLarge <> SumRange.Cells.CountLarge Then
        SUMUNIQUE = CVErr(xlErrRef)
        Exit Function
    End If

    Set dict = CreateObject("Scripting.Dictionary")
    Set uniqueValues = New Collection
    dict.CompareMode = vbTextCompare

    For i = 1 To UniqueRange.Cells.CountLarge
        keyValue = UniqueRange.Cells(i).Value2

        If Not IsError(keyValue) Then
            If Len(Trim$(CStr(keyValue))) > 0 Then
                dictKey = TypeName(keyValue) & "|" & CStr(keyValue)

                If Not dict.Exists(dictKey) Then
                    dict.Add dictKey, uniqueValues.Count + 1
                    uniqueValues.Add keyValue
                End If
            End If
        End If
    Next i

    If uniqueValues.Count = 0 Then
        SUMUNIQUE = ""
        Exit Function
    End If

    If sortValue = 1 Then SortSumUniqueValues uniqueValues

    ReDim result(1 To uniqueValues.Count + 1, 1 To 2)
    result(1, 1) = "Unique List"
    result(1, 2) = "Total Value"

    For i = 1 To uniqueValues.Count
        keyValue = uniqueValues(i)
        sumValue = Application.SumIfs(SumRange, UniqueRange, keyValue)

        result(i + 1, 1) = keyValue
        result(i + 1, 2) = sumValue
    Next i

    SUMUNIQUE = result
End Function

Private Function TryGetSumUniqueSortFlag( _
    ByVal flagValue As Variant, _
    ByRef resultFlag As Long) As Boolean

    If IsError(flagValue) Or IsObject(flagValue) Or IsEmpty(flagValue) Then Exit Function
    If Not IsNumeric(flagValue) Then Exit Function
    If CDbl(flagValue) <> Fix(CDbl(flagValue)) Then Exit Function

    resultFlag = CLng(flagValue)
    TryGetSumUniqueSortFlag = (resultFlag = 0 Or resultFlag = 1)
End Function

Private Sub SortSumUniqueValues(ByRef values As Collection)
    Dim sortedValues() As Variant
    Dim temporaryValue As Variant
    Dim i As Long
    Dim j As Long

    ReDim sortedValues(1 To values.Count)

    For i = 1 To values.Count
        sortedValues(i) = values(i)
    Next i

    For i = LBound(sortedValues) To UBound(sortedValues) - 1
        For j = i + 1 To UBound(sortedValues)
            If SumUniqueValueComesAfter(sortedValues(i), sortedValues(j)) Then
                temporaryValue = sortedValues(i)
                sortedValues(i) = sortedValues(j)
                sortedValues(j) = temporaryValue
            End If
        Next j
    Next i

    Set values = New Collection

    For i = LBound(sortedValues) To UBound(sortedValues)
        values.Add sortedValues(i)
    Next i
End Sub

Private Function SumUniqueValueComesAfter( _
    ByVal firstValue As Variant, _
    ByVal secondValue As Variant) As Boolean

    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        SumUniqueValueComesAfter = (CDbl(firstValue) > CDbl(secondValue))
    Else
        SumUniqueValueComesAfter = _
            (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function
