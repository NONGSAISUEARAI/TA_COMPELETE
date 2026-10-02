Attribute VB_Name = "A_FUNC_SumUnique_V3"
Option Explicit

' Syntax:
' =SUMUNIQUE_V3(Condition1Range,Sort1,Condition2Range,Sort2,Condition3Range,Sort3,SumRange)
' =SUMUNIQUE_V3(Condition1Range,Sort1,Condition2Range,Sort2,Condition3Range,Sort3,SumRange,Heading)
'
' Sort1, Sort2 and Sort3:
'   1 = sort ascending
'   0 = keep source order
'
' Output:
'   Column 1 = Condition 1
'   Column 2 = Condition 2
'   Column 3 = Condition 3
'   Column 4 = Total Value
Public Function SUMUNIQUE_V3( _
    ByVal Condition1Range As Range, _
    ByVal Sort1 As Variant, _
    ByVal Condition2Range As Range, _
    ByVal Sort2 As Variant, _
    ByVal Condition3Range As Range, _
    ByVal Sort3 As Variant, _
    ByVal SumRange As Range, _
    Optional ByVal Heading As Variant) As Variant

    Dim condition1Dict As Object
    Dim condition2Dict As Object
    Dim condition3Dict As Object
    Dim totalDict As Object
    Dim condition1List As Collection
    Dim condition2List As Collection
    Dim condition3List As Collection
    Dim condition1Values() As Variant
    Dim condition2Values() As Variant
    Dim condition3Values() As Variant
    Dim result() As Variant
    Dim condition1Value As Variant
    Dim condition2Value As Variant
    Dim condition3Value As Variant
    Dim sumValue As Variant
    Dim condition1Key As String
    Dim condition2Key As String
    Dim condition3Key As String
    Dim combinationKey As String
    Dim sortFlag1 As Long
    Dim sortFlag2 As Long
    Dim sortFlag3 As Long
    Dim outputRow As Long
    Dim headingRows As Long
    Dim i As Long
    Dim j As Long
    Dim k As Long

    If Not TryGetSumUniqueV3SortFlag(Sort1, sortFlag1) _
        Or Not TryGetSumUniqueV3SortFlag(Sort2, sortFlag2) _
        Or Not TryGetSumUniqueV3SortFlag(Sort3, sortFlag3) Then
        SUMUNIQUE_V3 = CVErr(xlErrValue)
        Exit Function
    End If

    If Condition1Range.Cells.CountLarge <> Condition2Range.Cells.CountLarge _
        Or Condition1Range.Cells.CountLarge <> Condition3Range.Cells.CountLarge _
        Or Condition1Range.Cells.CountLarge <> SumRange.Cells.CountLarge Then
        SUMUNIQUE_V3 = CVErr(xlErrRef)
        Exit Function
    End If

    Set condition1Dict = CreateObject("Scripting.Dictionary")
    Set condition2Dict = CreateObject("Scripting.Dictionary")
    Set condition3Dict = CreateObject("Scripting.Dictionary")
    Set totalDict = CreateObject("Scripting.Dictionary")
    Set condition1List = New Collection
    Set condition2List = New Collection
    Set condition3List = New Collection

    condition1Dict.CompareMode = vbTextCompare
    condition2Dict.CompareMode = vbTextCompare
    condition3Dict.CompareMode = vbTextCompare
    totalDict.CompareMode = vbTextCompare

    For i = 1 To Condition1Range.Cells.CountLarge
        condition1Value = Condition1Range.Cells(i).Value2
        condition2Value = Condition2Range.Cells(i).Value2
        condition3Value = Condition3Range.Cells(i).Value2
        sumValue = SumRange.Cells(i).Value2

        If IsSumUniqueV3KeyUsable(condition1Value) _
            And IsSumUniqueV3KeyUsable(condition2Value) _
            And IsSumUniqueV3KeyUsable(condition3Value) _
            And IsSumUniqueV3AmountUsable(sumValue) Then

            condition1Key = SumUniqueV3ValueKey(condition1Value)
            condition2Key = SumUniqueV3ValueKey(condition2Value)
            condition3Key = SumUniqueV3ValueKey(condition3Value)
            combinationKey = condition1Key & ChrW$(30) _
                & condition2Key & ChrW$(30) & condition3Key

            If Not condition1Dict.Exists(condition1Key) Then
                condition1Dict.Add condition1Key, condition1List.Count + 1
                condition1List.Add condition1Value
            End If

            If Not condition2Dict.Exists(condition2Key) Then
                condition2Dict.Add condition2Key, condition2List.Count + 1
                condition2List.Add condition2Value
            End If

            If Not condition3Dict.Exists(condition3Key) Then
                condition3Dict.Add condition3Key, condition3List.Count + 1
                condition3List.Add condition3Value
            End If

            If totalDict.Exists(combinationKey) Then
                totalDict(combinationKey) = CDbl(totalDict(combinationKey)) + CDbl(sumValue)
            Else
                totalDict.Add combinationKey, CDbl(sumValue)
            End If
        End If
    Next i

    If totalDict.Count = 0 Then
        SUMUNIQUE_V3 = ""
        Exit Function
    End If

    SumUniqueV3CollectionToArray condition1List, condition1Values
    SumUniqueV3CollectionToArray condition2List, condition2Values
    SumUniqueV3CollectionToArray condition3List, condition3Values

    If sortFlag1 = 1 Then SortSumUniqueV3Values condition1Values
    If sortFlag2 = 1 Then SortSumUniqueV3Values condition2Values
    If sortFlag3 = 1 Then SortSumUniqueV3Values condition3Values

    If Not IsMissing(Heading) Then
        If Not IsError(Heading) Then
            If Len(CStr(Heading)) > 0 Then headingRows = 1
        End If
    End If

    ReDim result(1 To totalDict.Count + 1 + headingRows, 1 To 4)

    If headingRows = 1 Then result(1, 1) = Heading
    result(headingRows + 1, 1) = "Condition 1"
    result(headingRows + 1, 2) = "Condition 2"
    result(headingRows + 1, 3) = "Condition 3"
    result(headingRows + 1, 4) = "Total Value"
    outputRow = headingRows + 2

    For i = LBound(condition1Values) To UBound(condition1Values)
        condition1Key = SumUniqueV3ValueKey(condition1Values(i))

        For j = LBound(condition2Values) To UBound(condition2Values)
            condition2Key = SumUniqueV3ValueKey(condition2Values(j))

            For k = LBound(condition3Values) To UBound(condition3Values)
                condition3Key = SumUniqueV3ValueKey(condition3Values(k))
                combinationKey = condition1Key & ChrW$(30) _
                    & condition2Key & ChrW$(30) & condition3Key

                If totalDict.Exists(combinationKey) Then
                    result(outputRow, 1) = condition1Values(i)
                    result(outputRow, 2) = condition2Values(j)
                    result(outputRow, 3) = condition3Values(k)
                    result(outputRow, 4) = totalDict(combinationKey)
                    outputRow = outputRow + 1
                End If
            Next k
        Next j
    Next i

    SUMUNIQUE_V3 = result
End Function

Private Function TryGetSumUniqueV3SortFlag( _
    ByVal flagValue As Variant, _
    ByRef resultFlag As Long) As Boolean

    If IsError(flagValue) Or IsObject(flagValue) Or IsEmpty(flagValue) Then Exit Function
    If Not IsNumeric(flagValue) Then Exit Function
    If CDbl(flagValue) <> Fix(CDbl(flagValue)) Then Exit Function

    resultFlag = CLng(flagValue)
    TryGetSumUniqueV3SortFlag = (resultFlag = 0 Or resultFlag = 1)
End Function

Private Function IsSumUniqueV3KeyUsable(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Then Exit Function
    If Len(Trim$(CStr(value))) = 0 Then Exit Function
    If IsNumeric(value) Then
        If CDbl(value) = 0 Then Exit Function
    End If
    IsSumUniqueV3KeyUsable = True
End Function

Private Function IsSumUniqueV3AmountUsable(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Then Exit Function
    If Not IsNumeric(value) Then Exit Function
    If CDbl(value) = 0 Then Exit Function
    IsSumUniqueV3AmountUsable = True
End Function

Private Function SumUniqueV3ValueKey(ByVal value As Variant) As String
    SumUniqueV3ValueKey = TypeName(value) & "|" & CStr(value)
End Function

Private Sub SumUniqueV3CollectionToArray( _
    ByVal source As Collection, _
    ByRef values() As Variant)

    Dim i As Long
    ReDim values(1 To source.Count)

    For i = 1 To source.Count
        values(i) = source(i)
    Next i
End Sub

Private Sub SortSumUniqueV3Values(ByRef values() As Variant)
    Dim temporaryValue As Variant
    Dim i As Long
    Dim j As Long

    For i = LBound(values) To UBound(values) - 1
        For j = i + 1 To UBound(values)
            If SumUniqueV3ValueComesAfter(values(i), values(j)) Then
                temporaryValue = values(i)
                values(i) = values(j)
                values(j) = temporaryValue
            End If
        Next j
    Next i
End Sub

Private Function SumUniqueV3ValueComesAfter( _
    ByVal firstValue As Variant, _
    ByVal secondValue As Variant) As Boolean

    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        SumUniqueV3ValueComesAfter = (CDbl(firstValue) > CDbl(secondValue))
    Else
        SumUniqueV3ValueComesAfter = _
            (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function
