Attribute VB_Name = "A_FUNC_CountUnique_V4"
Option Explicit

' Supports 2, 3 or 4 condition ranges.
' Condition 1 = row labels; Conditions 2-4 = column header levels.
' Sort flag: 1 = ascending, 0 = source order.
' Syntax:
' =COUNTUNIQUE_V4(C1,S1,C2,S2)
' =COUNTUNIQUE_V4(C1,S1,C2,S2,Heading)
' =COUNTUNIQUE_V4(C1,S1,C2,S2,C3,S3)
' =COUNTUNIQUE_V4(C1,S1,C2,S2,C3,S3,Heading)
' =COUNTUNIQUE_V4(C1,S1,C2,S2,C3,S3,C4,S4)
' =COUNTUNIQUE_V4(C1,S1,C2,S2,C3,S3,C4,S4,Heading,RemoveBlank)
' RemoveBlank checks the count cells across all Condition 1 rows:
'   TRUE = remove result columns that contain no count at all
'   FALSE = keep every Condition 2-4 combination
Public Function COUNTUNIQUE_V4( _
    ByVal Condition1Range As Range, ByVal Sort1 As Variant, _
    ByVal Condition2Range As Range, ByVal Sort2 As Variant, _
    Optional ByVal Condition3Argument As Variant, Optional ByVal Sort3 As Variant, _
    Optional ByVal Condition4Argument As Variant, Optional ByVal Sort4 As Variant, _
    Optional ByVal Heading As Variant, _
    Optional ByVal RemoveBlank As Variant) As Variant

    Dim valueLists(1 To 4) As Collection
    Dim valueDicts(1 To 4) As Object
    Dim outputCombinations As Collection
    Dim values(1 To 4) As Variant
    Dim conditionRanges(1 To 4) As Range
    Dim sortFlags(1 To 4) As Long
    Dim countDict As Object
    Dim result() As Variant
    Dim rowValues(1 To 4) As Variant
    Dim keys(1 To 4) As String
    Dim combinationKey As String
    Dim combinationParts As Variant
    Dim hasCondition3 As Boolean
    Dim hasCondition4 As Boolean
    Dim hasHeading As Boolean
    Dim removeBlankFlag As Boolean
    Dim headingUsedAsRemoveBlank As Boolean
    Dim conditionCount As Long
    Dim headerRowCount As Long
    Dim headingRowCount As Long
    Dim headerStartRow As Long
    Dim totalColumns As Long
    Dim outputColumn As Long
    Dim outputRow As Long
    Dim condition3ValueCount As Long
    Dim condition4ValueCount As Long
    Dim previousGroupIndex As Long
    Dim previousSubHeaderIndex As Long
    Dim includeColumn As Boolean
    Dim rowIndex As Long
    Dim i As Long, j As Long, k As Long, n As Long

    Set conditionRanges(1) = Condition1Range
    Set conditionRanges(2) = Condition2Range

    If Not TryGetSortFlagV4(Sort1, sortFlags(1)) _
        Or Not TryGetSortFlagV4(Sort2, sortFlags(2)) Then
        COUNTUNIQUE_V4 = CVErr(xlErrValue)
        Exit Function
    End If

    If Not IsMissing(Condition3Argument) Then
        If IsObject(Condition3Argument) Then
            On Error Resume Next
            Set conditionRanges(3) = Condition3Argument
            On Error GoTo 0
            If conditionRanges(3) Is Nothing Or IsMissing(Sort3) Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If
            If Not TryGetSortFlagV4(Sort3, sortFlags(3)) Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If
            hasCondition3 = True
        ElseIf IsMissing(Sort3) And IsMissing(Condition4Argument) _
            And IsMissing(Sort4) And IsMissing(Heading) Then
            Heading = Condition3Argument
        Else
            COUNTUNIQUE_V4 = CVErr(xlErrValue)
            Exit Function
        End If
    ElseIf Not IsMissing(Sort3) Then
        COUNTUNIQUE_V4 = CVErr(xlErrValue)
        Exit Function
    End If

    If Not IsMissing(Condition4Argument) Then
        If Not hasCondition3 Then
            COUNTUNIQUE_V4 = CVErr(xlErrValue)
            Exit Function
        End If
        If IsObject(Condition4Argument) Then
            On Error Resume Next
            Set conditionRanges(4) = Condition4Argument
            On Error GoTo 0
            If conditionRanges(4) Is Nothing Or IsMissing(Sort4) Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If
            If Not TryGetSortFlagV4(Sort4, sortFlags(4)) Then
                COUNTUNIQUE_V4 = CVErr(xlErrValue)
                Exit Function
            End If
            hasCondition4 = True
        ElseIf IsMissing(Sort4) And IsMissing(Heading) Then
            Heading = Condition4Argument
        Else
            COUNTUNIQUE_V4 = CVErr(xlErrValue)
            Exit Function
        End If
    ElseIf Not IsMissing(Sort4) Then
        COUNTUNIQUE_V4 = CVErr(xlErrValue)
        Exit Function
    End If

    removeBlankFlag = True
    If Not IsMissing(RemoveBlank) Then
        If Not TryGetBooleanV4(RemoveBlank, removeBlankFlag) Then
            COUNTUNIQUE_V4 = CVErr(xlErrValue)
            Exit Function
        End If
    ElseIf Not IsMissing(Heading) Then
        If VarType(Heading) = vbBoolean Then
            removeBlankFlag = CBool(Heading)
            headingUsedAsRemoveBlank = True
        End If
    End If

    If Not IsMissing(Heading) And Not headingUsedAsRemoveBlank Then
        If Not IsError(Heading) Then hasHeading = (Len(CStr(Heading)) > 0)
    End If

    conditionCount = 2
    If hasCondition3 Then conditionCount = 3
    If hasCondition4 Then conditionCount = 4

    For n = 2 To conditionCount
        If conditionRanges(1).Cells.CountLarge <> conditionRanges(n).Cells.CountLarge Then
            COUNTUNIQUE_V4 = CVErr(xlErrRef)
            Exit Function
        End If
    Next n

    For n = 1 To 4
        Set valueLists(n) = New Collection
        Set valueDicts(n) = CreateObject("Scripting.Dictionary")
        valueDicts(n).CompareMode = vbTextCompare
    Next n
    Set countDict = CreateObject("Scripting.Dictionary")
    countDict.CompareMode = vbTextCompare

    For i = 1 To conditionRanges(1).Cells.CountLarge
        For n = 1 To conditionCount
            rowValues(n) = conditionRanges(n).Cells(i).Value2
            If Not IsUsableValueV4(rowValues(n)) Then GoTo SkipSourceRow
            keys(n) = ValueKeyV4(rowValues(n))
        Next n

        For n = 1 To conditionCount
            If Not valueDicts(n).Exists(keys(n)) Then
                valueDicts(n).Add keys(n), valueLists(n).Count + 1
                valueLists(n).Add rowValues(n)
            End If
        Next n

        combinationKey = BuildCombinationKeyV4(keys, conditionCount)
        If countDict.Exists(combinationKey) Then
            countDict(combinationKey) = countDict(combinationKey) + 1
        Else
            countDict.Add combinationKey, 1
        End If
SkipSourceRow:
    Next i

    If valueLists(1).Count = 0 Then
        COUNTUNIQUE_V4 = ""
        Exit Function
    End If

    For n = 1 To conditionCount
        CollectionToArrayV4 valueLists(n), values(n)
        If sortFlags(n) = 1 Then SortValuesAscendingV4 values(n)
    Next n

    condition3ValueCount = 1
    condition4ValueCount = 1
    If conditionCount >= 3 Then condition3ValueCount = ArraySizeV4(values(3))
    If conditionCount = 4 Then condition4ValueCount = ArraySizeV4(values(4))

    Set outputCombinations = New Collection

    For i = 1 To ArraySizeV4(values(2))
        For j = 1 To condition3ValueCount
            For k = 1 To condition4ValueCount
                includeColumn = Not removeBlankFlag

                If removeBlankFlag Then
                    For rowIndex = 1 To ArraySizeV4(values(1))
                        keys(1) = ValueKeyV4(values(1)(rowIndex))
                        keys(2) = ValueKeyV4(values(2)(i))
                        If conditionCount >= 3 Then keys(3) = ValueKeyV4(values(3)(j))
                        If conditionCount = 4 Then keys(4) = ValueKeyV4(values(4)(k))

                        combinationKey = BuildCombinationKeyV4(keys, conditionCount)
                        If countDict.Exists(combinationKey) Then
                            includeColumn = True
                            Exit For
                        End If
                    Next rowIndex
                End If

                If includeColumn Then
                    outputCombinations.Add _
                        CStr(i) & ChrW$(31) & CStr(j) & ChrW$(31) & CStr(k)
                End If
            Next k
        Next j
    Next i

    headerRowCount = conditionCount - 1
    If hasHeading Then headingRowCount = 1
    headerStartRow = headingRowCount + 1
    totalColumns = 1 + outputCombinations.Count

    ReDim result( _
        1 To ArraySizeV4(values(1)) + headerRowCount + headingRowCount, _
        1 To totalColumns)
    FillResultWithBlanksV4 result
    If hasHeading Then result(1, 1) = Heading

    previousGroupIndex = 0
    previousSubHeaderIndex = 0

    For n = 1 To outputCombinations.Count
        combinationParts = Split(CStr(outputCombinations(n)), ChrW$(31))
        i = CLng(combinationParts(0))
        j = CLng(combinationParts(1))
        k = CLng(combinationParts(2))
        outputColumn = n + 1

        If i <> previousGroupIndex Then
            result(headerStartRow, outputColumn) = values(2)(i)
        End If

        If conditionCount >= 3 Then
            If i <> previousGroupIndex Or j <> previousSubHeaderIndex Then
                result(headerStartRow + 1, outputColumn) = values(3)(j)
            End If
        End If

        If conditionCount = 4 Then
            result(headerStartRow + 2, outputColumn) = values(4)(k)
        End If

        previousGroupIndex = i
        previousSubHeaderIndex = j
    Next n

    For rowIndex = 1 To ArraySizeV4(values(1))
        outputRow = rowIndex + headerRowCount + headingRowCount
        result(outputRow, 1) = values(1)(rowIndex)
        keys(1) = ValueKeyV4(values(1)(rowIndex))

        For n = 1 To outputCombinations.Count
            combinationParts = Split(CStr(outputCombinations(n)), ChrW$(31))
            i = CLng(combinationParts(0))
            j = CLng(combinationParts(1))
            k = CLng(combinationParts(2))
            outputColumn = n + 1

            keys(2) = ValueKeyV4(values(2)(i))
            If conditionCount >= 3 Then keys(3) = ValueKeyV4(values(3)(j))
            If conditionCount = 4 Then keys(4) = ValueKeyV4(values(4)(k))
            WriteCountV4 result, outputRow, outputColumn, countDict, keys, conditionCount
        Next n
    Next rowIndex

    COUNTUNIQUE_V4 = result
End Function

Private Sub WriteCountV4( _
    ByRef result() As Variant, ByVal outputRow As Long, ByVal outputColumn As Long, _
    ByVal countDict As Object, ByRef keys() As String, ByVal conditionCount As Long)

    Dim combinationKey As String
    combinationKey = BuildCombinationKeyV4(keys, conditionCount)
    If countDict.Exists(combinationKey) Then
        result(outputRow, outputColumn) = countDict(combinationKey)
    Else
        result(outputRow, outputColumn) = ""
    End If
End Sub

Private Function BuildCombinationKeyV4( _
    ByRef keys() As String, ByVal conditionCount As Long) As String

    Dim n As Long
    BuildCombinationKeyV4 = keys(1)
    For n = 2 To conditionCount
        BuildCombinationKeyV4 = BuildCombinationKeyV4 & ChrW$(30) & keys(n)
    Next n
End Function

Private Function TryGetBooleanV4( _
    ByVal flagValue As Variant, ByRef resultFlag As Boolean) As Boolean

    If IsError(flagValue) Or IsObject(flagValue) Or IsEmpty(flagValue) Then Exit Function

    If VarType(flagValue) = vbBoolean Then
        resultFlag = CBool(flagValue)
        TryGetBooleanV4 = True
    ElseIf IsNumeric(flagValue) Then
        If CDbl(flagValue) = 0 Or CDbl(flagValue) = 1 Then
            resultFlag = CBool(CLng(flagValue))
            TryGetBooleanV4 = True
        End If
    End If
End Function

Private Function TryGetSortFlagV4( _
    ByVal flagValue As Variant, ByRef resultFlag As Long) As Boolean

    If IsError(flagValue) Or IsObject(flagValue) Or IsEmpty(flagValue) Then Exit Function
    If Not IsNumeric(flagValue) Then Exit Function
    If CDbl(flagValue) <> Fix(CDbl(flagValue)) Then Exit Function
    resultFlag = CLng(flagValue)
    TryGetSortFlagV4 = (resultFlag = 0 Or resultFlag = 1)
End Function

Private Sub CollectionToArrayV4(ByVal source As Collection, ByRef values As Variant)
    Dim result() As Variant
    Dim i As Long
    ReDim result(1 To source.Count)
    For i = 1 To source.Count
        result(i) = source(i)
    Next i
    values = result
End Sub

Private Function ArraySizeV4(ByVal values As Variant) As Long
    ArraySizeV4 = UBound(values) - LBound(values) + 1
End Function

Private Sub FillResultWithBlanksV4(ByRef result() As Variant)
    Dim i As Long, j As Long
    For i = LBound(result, 1) To UBound(result, 1)
        For j = LBound(result, 2) To UBound(result, 2)
            result(i, j) = ""
        Next j
    Next i
End Sub

Private Sub SortValuesAscendingV4(ByRef values As Variant)
    Dim i As Long, j As Long
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
    ByVal firstValue As Variant, ByVal secondValue As Variant) As Boolean

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
