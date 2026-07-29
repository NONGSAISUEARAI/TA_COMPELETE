Attribute VB_Name = "A_FUNC_CountUnique_V4"
Option Explicit

' Syntax:
' =COUNTUNIQUE_V4(Condition1Range,Sort1,Condition2Range,Sort2)
' =COUNTUNIQUE_V4(Condition1Range,Sort1,Condition2Range,Sort2,Heading)
' =COUNTUNIQUE_V4(Condition1Range,Sort1,Condition2Range,Sort2,Condition3Range,Sort3)
' =COUNTUNIQUE_V4(Condition1Range,Sort1,Condition2Range,Sort2,Condition3Range,Sort3,Heading)
'
' Sort1, Sort2 and Sort3:
'   1 = sort ascending
'   0 = keep source order
Public Function COUNTUNIQUE_V4( _
    ByVal Condition1Range As Range, _
    ByVal Sort1 As Variant, _
    ByVal Condition2Range As Range, _
    ByVal Sort2 As Variant, _
    Optional ByVal Condition3Argument As Variant, _
    Optional ByVal Sort3 As Variant, _
    Optional ByVal Heading As Variant) As Variant

    Dim groupDict As Object
    Dim subHeaderDict As Object
    Dim rowLabelDict As Object
    Dim countDict As Object
    Dim groupList As Collection
    Dim subHeaderList As Collection
    Dim rowLabelList As Collection
    Dim condition3Range As Range
    Dim rowLabels() As Variant
    Dim groups() As Variant
    Dim subHeaders() As Variant
    Dim result() As Variant
    Dim groupValue As Variant
    Dim subHeaderValue As Variant
    Dim rowLabelValue As Variant
    Dim groupKey As String
    Dim subHeaderKey As String
    Dim rowLabelKey As String
    Dim combinationKey As String
    Dim outputColumn As Long
    Dim outputRow As Long
    Dim totalColumns As Long
    Dim headerRowCount As Long
    Dim headingRowCount As Long
    Dim headerStartRow As Long
    Dim hasCondition3 As Boolean
    Dim hasHeading As Boolean
    Dim sortFlag1 As Long
    Dim sortFlag2 As Long
    Dim sortFlag3 As Long
    Dim i As Long
    Dim j As Long
    Dim k As Long

    If Not TryGetSortFlagV4(Sort1, sortFlag1) _
        Or Not TryGetSortFlagV4(Sort2, sortFlag2) Then
        COUNTUNIQUE_V4 = CVErr(xlErrValue)
        Exit Function
    End If

    If Not IsMissing(Condition3Argument) Then
        If IsObject(Condition3Argument) Then
            On Error Resume Next
            Set condition3Range = Condition3Argument
            On Error GoTo 0

            If condition3Range Is Nothing Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If

            hasCondition3 = True

            If IsMissing(Sort3) Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If

            If Not TryGetSortFlagV4(Sort3, sortFlag3) Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If
        ElseIf IsMissing(Sort3) And IsMissing(Heading) Then
            Heading = Condition3Argument
        Else
            COUNTUNIQUE_V4 = CVErr(xlErrValue)
            Exit Function
        End If
    ElseIf Not IsMissing(Sort3) Then
        COUNTUNIQUE_V4 = CVErr(xlErrValue)
        Exit Function
    End If

    If Not IsMissing(Heading) Then
        If Not IsError(Heading) Then
            hasHeading = (Len(CStr(Heading)) > 0)
        End If
    End If

    If Condition1Range.Cells.CountLarge <> Condition2Range.Cells.CountLarge Then
        COUNTUNIQUE_V4 = CVErr(xlErrRef)
        Exit Function
    End If

    If hasCondition3 Then
        If Condition1Range.Cells.CountLarge <> condition3Range.Cells.CountLarge Then
            COUNTUNIQUE_V4 = CVErr(xlErrRef)
            Exit Function
        End If
    End If

    Set groupDict = CreateObject("Scripting.Dictionary")
    Set subHeaderDict = CreateObject("Scripting.Dictionary")
    Set rowLabelDict = CreateObject("Scripting.Dictionary")
    Set countDict = CreateObject("Scripting.Dictionary")
    Set groupList = New Collection
    Set subHeaderList = New Collection
    Set rowLabelList = New Collection

    groupDict.CompareMode = vbTextCompare
    subHeaderDict.CompareMode = vbTextCompare
    rowLabelDict.CompareMode = vbTextCompare
    countDict.CompareMode = vbTextCompare

    For i = 1 To Condition1Range.Cells.CountLarge
        rowLabelValue = Condition1Range.Cells(i).Value2
        groupValue = Condition2Range.Cells(i).Value2

        If hasCondition3 Then
            subHeaderValue = condition3Range.Cells(i).Value2
        Else
            subHeaderValue = "__NO_CONDITION_3__"
        End If

        If IsUsableValueV4(groupValue) _
            And IsUsableValueV4(rowLabelValue) _
            And (Not hasCondition3 Or IsUsableValueV4(subHeaderValue)) Then

            groupKey = ValueKeyV4(groupValue)
            subHeaderKey = ValueKeyV4(subHeaderValue)
            rowLabelKey = ValueKeyV4(rowLabelValue)

            If Not groupDict.Exists(groupKey) Then
                groupDict.Add groupKey, groupList.Count + 1
                groupList.Add groupValue
            End If

            If Not subHeaderDict.Exists(subHeaderKey) Then
                subHeaderDict.Add subHeaderKey, subHeaderList.Count + 1
                subHeaderList.Add subHeaderValue
            End If

            If Not rowLabelDict.Exists(rowLabelKey) Then
                rowLabelDict.Add rowLabelKey, rowLabelList.Count + 1
                rowLabelList.Add rowLabelValue
            End If

            combinationKey = groupKey & ChrW$(30) _
                & subHeaderKey & ChrW$(30) & rowLabelKey

            If countDict.Exists(combinationKey) Then
                countDict(combinationKey) = countDict(combinationKey) + 1
            Else
                countDict.Add combinationKey, 1
            End If
        End If
    Next i

    If rowLabelList.Count = 0 Then
        COUNTUNIQUE_V4 = ""
        Exit Function
    End If

    CollectionToArrayV4 rowLabelList, rowLabels
    CollectionToArrayV4 groupList, groups
    CollectionToArrayV4 subHeaderList, subHeaders

    If sortFlag1 = 1 Then SortValuesAscendingV4 rowLabels
    If sortFlag2 = 1 Then SortValuesAscendingV4 groups
    If hasCondition3 And sortFlag3 = 1 Then SortValuesAscendingV4 subHeaders

    totalColumns = 1 + (UBound(groups) * UBound(subHeaders))

    If hasCondition3 Then
        headerRowCount = 2
    Else
        headerRowCount = 1
    End If

    If hasHeading Then headingRowCount = 1
    headerStartRow = headingRowCount + 1

    ReDim result( _
        1 To UBound(rowLabels) + headerRowCount + headingRowCount, _
        1 To totalColumns)

    For i = 1 To UBound(result, 1)
        For j = 1 To UBound(result, 2)
            result(i, j) = ""
        Next j
    Next i

    If hasHeading Then result(1, 1) = Heading

    outputColumn = 2

    For i = 1 To UBound(groups)
        result(headerStartRow, outputColumn) = groups(i)

        For j = 1 To UBound(subHeaders)
            If hasCondition3 Then
                result(headerStartRow + 1, outputColumn) = subHeaders(j)
            End If

            outputColumn = outputColumn + 1
        Next j
    Next i

    For k = 1 To UBound(rowLabels)
        rowLabelValue = rowLabels(k)
        rowLabelKey = ValueKeyV4(rowLabelValue)
        outputRow = k + headerRowCount + headingRowCount
        result(outputRow, 1) = rowLabelValue
        outputColumn = 2

        For i = 1 To UBound(groups)
            groupKey = ValueKeyV4(groups(i))

            For j = 1 To UBound(subHeaders)
                subHeaderKey = ValueKeyV4(subHeaders(j))
                combinationKey = groupKey & ChrW$(30) _
                    & subHeaderKey & ChrW$(30) & rowLabelKey

                If countDict.Exists(combinationKey) Then
                    result(outputRow, outputColumn) = countDict(combinationKey)
                Else
                    result(outputRow, outputColumn) = ""
                End If

                outputColumn = outputColumn + 1
            Next j
        Next i
    Next k

    COUNTUNIQUE_V4 = result
End Function

Private Function TryGetSortFlagV4( _
    ByVal flagValue As Variant, _
    ByRef resultFlag As Long) As Boolean

    If IsError(flagValue) Or IsObject(flagValue) Or IsEmpty(flagValue) Then Exit Function
    If Not IsNumeric(flagValue) Then Exit Function
    If CDbl(flagValue) <> Fix(CDbl(flagValue)) Then Exit Function

    resultFlag = CLng(flagValue)
    TryGetSortFlagV4 = (resultFlag = 0 Or resultFlag = 1)
End Function

Private Sub CollectionToArrayV4( _
    ByVal source As Collection, _
    ByRef values() As Variant)

    Dim i As Long

    ReDim values(1 To source.Count)

    For i = 1 To source.Count
        values(i) = source(i)
    Next i
End Sub

Private Sub SortValuesAscendingV4(ByRef values() As Variant)
    Dim i As Long
    Dim j As Long
    Dim temporaryValue As Variant

    For i = LBound(values) To UBound(values) - 1
        For j = i + 1 To UBound(values)
            If ValueComesAfterV4(values(i), values(j)) Then
                temporaryValue = values(i)
                values(i) = values(j)
                values(j) = temporaryValue
            End If
        Next j
    Next i
End Sub

Private Function ValueComesAfterV4( _
    ByVal firstValue As Variant, _
    ByVal secondValue As Variant) As Boolean

    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        ValueComesAfterV4 = (CDbl(firstValue) > CDbl(secondValue))
    Else
        ValueComesAfterV4 = _
            (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function

Private Function IsUsableValueV4(ByVal value As Variant) As Boolean
    If IsError(value) Then Exit Function
    IsUsableValueV4 = (Len(Trim$(CStr(value))) > 0)
End Function

Private Function ValueKeyV4(ByVal value As Variant) As String
    ValueKeyV4 = TypeName(value) & "|" & CStr(value)
End Function
