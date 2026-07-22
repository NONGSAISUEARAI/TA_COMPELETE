Attribute VB_Name = "A_FUNC_CountUnique_V2"
Option Explicit

' Builds a three-axis count table as a dynamic spill array.
' Condition 1 = vertical row labels
' Condition 2 = horizontal group headers
' Condition 3 = optional subheaders under each Condition 2 group
'
' Example:
' =COUNTUNIQUE_V2(Condition1Range,Condition2Range)
' =COUNTUNIQUE_V2(Condition1Range,Condition2Range,Condition3Range,Heading)
' =COUNTUNIQUE_V2(Condition1Range,Condition2Range,,Heading)
Public Function COUNTUNIQUE_V2( _
    ByVal Condition1Range As Range, _
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
    Dim Condition3Range As Range
    Dim i As Long
    Dim j As Long
    Dim k As Long

    If Not IsMissing(Condition3Argument) Then
        If IsObject(Condition3Argument) Then
            Set Condition3Range = Condition3Argument
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

        COUNTUNIQUE_V2 = CVErr(xlErrRef)
        Exit Function
    End If

    If hasCondition3 Then
        If Condition1Range.Cells.CountLarge <> Condition3Range.Cells.CountLarge Then
            COUNTUNIQUE_V2 = CVErr(xlErrRef)
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
            subHeaderValue = Condition3Range.Cells(i).Value2
        Else
            subHeaderValue = "__NO_CONDITION_3__"
        End If

        If IsUsableValueV2(groupValue) _
            And IsUsableValueV2(rowLabelValue) _
            And (Not hasCondition3 Or IsUsableValueV2(subHeaderValue)) Then

            groupKey = ValueKeyV2(groupValue)
            subHeaderKey = ValueKeyV2(subHeaderValue)
            rowLabelKey = ValueKeyV2(rowLabelValue)

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

    If groupList.Count = 0 Then
        COUNTUNIQUE_V2 = ""
        Exit Function
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
        1 To rowLabelList.Count + headerRowCount + headingRowCount, _
        1 To totalColumns)

    ' Prevent unused spill cells from appearing as zero.
    For i = 1 To UBound(result, 1)
        For j = 1 To UBound(result, 2)
            result(i, j) = ""
        Next j
    Next i

    If hasHeading Then
        result(1, 1) = Heading
    End If

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

    For k = 1 To rowLabelList.Count
        rowLabelValue = rowLabelList(k)
        rowLabelKey = ValueKeyV2(rowLabelValue)
        outputRow = k + headerRowCount + headingRowCount
        result(outputRow, 1) = rowLabelValue
        outputColumn = 2

        For i = 1 To groupList.Count
            groupKey = ValueKeyV2(groupList(i))

            For j = 1 To subHeaderList.Count
                subHeaderKey = ValueKeyV2(subHeaderList(j))
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

    COUNTUNIQUE_V2 = result
End Function

Private Function IsUsableValueV2(ByVal value As Variant) As Boolean
    If IsError(value) Then Exit Function
    IsUsableValueV2 = (Len(Trim$(CStr(value))) > 0)
End Function

Private Function ValueKeyV2(ByVal value As Variant) As String
    ValueKeyV2 = TypeName(value) & "|" & CStr(value)
End Function
