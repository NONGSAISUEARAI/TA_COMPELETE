Attribute VB_Name = "A_FUNC_CountUnique_V1"
Option Explicit

' Returns a two-column spill array:
' Column 1 = Unique List
' Column 2 = Count
'
' Example:
' =COUNTUNIQUE(A1:A20)
' =COUNTUNIQUE(A1:A20,1)
'
' SortFlag:
'   0 or omitted = keep source order
'   1 = sort ascending
Public Function COUNTUNIQUE( _
    ByVal UniqueRange As Range, _
    Optional ByVal SortFlag As Variant = 0) As Variant

    Dim dict As Object
    Dim uniqueValues As Collection
    Dim sortedValues() As Variant
    Dim result() As Variant
    Dim keyValue As Variant
    Dim dictKey As String
    Dim sortMode As Long
    Dim i As Long

    If Not TryGetSortFlagV1(SortFlag, sortMode) Then
        COUNTUNIQUE = CVErr(xlErrValue)
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
                    dict.Add dictKey, 1
                    uniqueValues.Add keyValue
                Else
                    dict(dictKey) = dict(dictKey) + 1
                End If
            End If
        End If
    Next i

    If uniqueValues.Count = 0 Then
        COUNTUNIQUE = ""
        Exit Function
    End If

    ReDim sortedValues(1 To uniqueValues.Count)

    For i = 1 To uniqueValues.Count
        sortedValues(i) = uniqueValues(i)
    Next i

    If sortMode = 1 Then
        SortValuesAscendingV1 sortedValues
    End If

    ReDim result(1 To uniqueValues.Count + 1, 1 To 2)
    result(1, 1) = "Unique List"
    result(1, 2) = "Count"

    For i = 1 To UBound(sortedValues)
        keyValue = sortedValues(i)
        dictKey = TypeName(keyValue) & "|" & CStr(keyValue)

        result(i + 1, 1) = keyValue
        result(i + 1, 2) = dict(dictKey)
    Next i

    COUNTUNIQUE = result
End Function

Private Function TryGetSortFlagV1( _
    ByVal flagValue As Variant, _
    ByRef resultFlag As Long) As Boolean

    If IsError(flagValue) Or IsObject(flagValue) Or IsEmpty(flagValue) Then Exit Function
    If Not IsNumeric(flagValue) Then Exit Function
    If CDbl(flagValue) <> Fix(CDbl(flagValue)) Then Exit Function

    resultFlag = CLng(flagValue)
    TryGetSortFlagV1 = (resultFlag = 0 Or resultFlag = 1)
End Function

Private Sub SortValuesAscendingV1(ByRef values() As Variant)
    Dim i As Long
    Dim j As Long
    Dim temporaryValue As Variant

    For i = LBound(values) To UBound(values) - 1
        For j = i + 1 To UBound(values)
            If ValueComesAfterV1(values(i), values(j)) Then
                temporaryValue = values(i)
                values(i) = values(j)
                values(j) = temporaryValue
            End If
        Next j
    Next i
End Sub

Private Function ValueComesAfterV1( _
    ByVal firstValue As Variant, _
    ByVal secondValue As Variant) As Boolean

    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        ValueComesAfterV1 = (CDbl(firstValue) > CDbl(secondValue))
    Else
        ValueComesAfterV1 = _
            (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function
