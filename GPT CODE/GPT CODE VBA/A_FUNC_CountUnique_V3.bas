Attribute VB_Name = "A_FUNC_CountUnique_V3"
Option Explicit

' Syntax:
' =COUNTUNIQUE_V3(Condition1Range,SortFlag,Condition2Range)
' =COUNTUNIQUE_V3(Condition1Range,SortFlag,Condition2Range,Condition3Range,Heading)
' SortFlag: 1 = sort Condition 1 ascending, 0 = keep source order
Public Function COUNTUNIQUE_V3( _
    ByVal Condition1Range As Range, _
    ByVal SortFlag As Long, _
    ByVal Condition2Range As Range, _
    Optional ByVal Condition3Argument As Variant, _
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
    Dim i As Long
    Dim j As Long
    Dim k As Long

    If SortFlag <> 0 And SortFlag <> 1 Then
        COUNTUNIQUE_V3 = CVErr(xlErrValue)
        Exit Function
    End If

    If Not IsMissing(Condition3Argument) Then
        If IsObject(Condition3Argument) Then
            Set condition3Range = Condition3Argument
            hasCondition3 = True
        ElseIf IsMissing(Heading) Then
            Heading = Condition3Argument
        End If
    End If

    If Not IsMissing(Heading) Then
        If Not IsError(Heading) Then
            hasHeading = (Len(CStr(Heading)) > 0)
        End If
    End If

    If Condition1Range.Cells.CountLarge <> Condition2Range.Cells.CountLarge Then
        COUNTUNIQUE_V3 = CVErr(xlErrRef)
        Exit Function
    End If

    If hasCondition3 Then
        If Condition1Range.Cells.CountLarge <> condition3Range.Cells.CountLarge Then
            COUNTUNIQUE_V3 = CVErr(xlErrRef)
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

        If IsUsableValueV3(groupValue) _
            And IsUsableValueV3(rowLabelValue) _
            And (Not hasCondition3 Or IsUsableValueV3(subHeaderValue)) Then

            groupKey = ValueKeyV3(groupValue)
            subHeaderKey = ValueKeyV3(subHeaderValue)
            rowLabelKey = ValueKeyV3(rowLabelValue)

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
        COUNTUNIQUE_V3 = ""
        Exit Function
    End If

    ReDim rowLabels(1 To rowLabelList.Count)

    For i = 1 To rowLabelList.Count
        rowLabels(i) = rowLabelList(i)
    Next i

    If SortFlag = 1 Then
        SortValuesAscendingV3 rowLabels
    End If

    totalColumns = 1 + (groupList.Count * subHeaderList.Count)

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

    For i = 1 To groupList.Count
        result(headerStartRow, outputColumn) = groupList(i)

        For j = 1 To subHeaderList.Count
            If hasCondition3 Then
                result(headerStartRow + 1, outputColumn) = subHeaderList(j)
            End If

            outputColumn = outputColumn + 1
        Next j
    Next i

    For k = 1 To UBound(rowLabels)
        rowLabelValue = rowLabels(k)
        rowLabelKey = ValueKeyV3(rowLabelValue)
        outputRow = k + headerRowCount + headingRowCount
        result(outputRow, 1) = rowLabelValue
        outputColumn = 2

        For i = 1 To groupList.Count
            groupKey = ValueKeyV3(groupList(i))

            For j = 1 To subHeaderList.Count
                subHeaderKey = ValueKeyV3(subHeaderList(j))
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

    COUNTUNIQUE_V3 = result
End Function

Private Sub SortValuesAscendingV3(ByRef values() As Variant)
    Dim i As Long
    Dim j As Long
    Dim temporaryValue As Variant

    For i = LBound(values) To UBound(values) - 1
        For j = i + 1 To UBound(values)
            If ValueComesAfterV3(values(i), values(j)) Then
                temporaryValue = values(i)
                values(i) = values(j)
                values(j) = temporaryValue
            End If
        Next j
    Next i
End Sub

Private Function ValueComesAfterV3( _
    ByVal firstValue As Variant, _
    ByVal secondValue As Variant) As Boolean

    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        ValueComesAfterV3 = (CDbl(firstValue) > CDbl(secondValue))
    Else
        ValueComesAfterV3 = _
            (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function

Private Function IsUsableValueV3(ByVal value As Variant) As Boolean
    If IsError(value) Then Exit Function
    IsUsableValueV3 = (Len(Trim$(CStr(value))) > 0)
End Function

Private Function ValueKeyV3(ByVal value As Variant) As String
    ValueKeyV3 = TypeName(value) & "|" & CStr(value)
End Function
