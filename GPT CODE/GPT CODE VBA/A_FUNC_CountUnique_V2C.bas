Attribute VB_Name = "A_FUNC_CountUnique_V2C"
Option Explicit

' Sort arguments accept:
'   0 = source order; 1 = ascending by condition value
'   a matching range of sort keys (including cells calculated by formulas)
'   an array returned by an Excel formula, with one key per source row
' Custom keys sort ascending. Equal keys keep the first-seen source order.
' =COUNTUNIQUE_V2C(C1,Sort1,C2,Sort2,[Heading])
' =COUNTUNIQUE_V2C(C1,Sort1,C2,Sort2,C3,Sort3,[Heading])
' Inline array formula example: sort the CSV text in N by its second field.
' =COUNTUNIQUE_V2C(N3:N2500,IFERROR(--TEXTBEFORE(TEXTAFTER(N3:N2500,","),","),""),A3:A2500,0,"Summary")
Public Function COUNTUNIQUE_V2C( _
    ByVal Condition1Range As Range, ByVal Sort1 As Variant, _
    ByVal Condition2Range As Range, ByVal Sort2 As Variant, _
    Optional ByVal Condition3Argument As Variant, Optional ByVal Sort3 As Variant, _
    Optional ByVal Heading As Variant) As Variant

    Dim condition3Range As Range
    Dim hasCondition3 As Boolean, hasHeading As Boolean
    Dim sortMode1 As Long, sortMode2 As Long, sortMode3 As Long
    Dim sortValues1() As Variant, sortValues2() As Variant, sortValues3() As Variant
    Dim rowDict As Object, groupDict As Object, subDict As Object, countDict As Object
    Dim rowSortDict As Object, groupSortDict As Object, subSortDict As Object
    Dim rowList As Collection, groupList As Collection, subList As Collection
    Dim rowValues() As Variant, groupValues() As Variant, subValues() As Variant
    Dim result() As Variant
    Dim rowValue As Variant, groupValue As Variant, subValue As Variant
    Dim rowKey As String, groupKey As String, subKey As String, countKey As String
    Dim sourceCount As Long, headerRows As Long, headingRows As Long
    Dim headerStart As Long, outputRow As Long, outputColumn As Long
    Dim i As Long, j As Long, k As Long

    If Condition1Range.Cells.CountLarge <> Condition2Range.Cells.CountLarge Then
        COUNTUNIQUE_V2C = CVErr(xlErrRef)
        Exit Function
    End If
    sourceCount = Condition1Range.Cells.Count

    If Not IsMissing(Condition3Argument) Then
        If IsObject(Condition3Argument) Then
            On Error Resume Next
            Set condition3Range = Condition3Argument
            On Error GoTo 0
            If condition3Range Is Nothing Then
                COUNTUNIQUE_V2C = CountUniqueV2CUsage()
                Exit Function
            End If
            hasCondition3 = True
        ElseIf IsMissing(Sort3) And IsMissing(Heading) Then
            Heading = Condition3Argument
        Else
            COUNTUNIQUE_V2C = CountUniqueV2CUsage()
            Exit Function
        End If
    ElseIf Not IsMissing(Sort3) Then
        COUNTUNIQUE_V2C = CountUniqueV2CUsage()
        Exit Function
    End If

    If hasCondition3 Then
        If condition3Range.Cells.CountLarge <> sourceCount Or IsMissing(Sort3) Then
            COUNTUNIQUE_V2C = CountUniqueV2CUsage()
            Exit Function
        End If
    End If

    If Not CountUniqueV2CParseSort(Sort1, sourceCount, sortMode1, sortValues1) _
        Or Not CountUniqueV2CParseSort(Sort2, sourceCount, sortMode2, sortValues2) Then
        COUNTUNIQUE_V2C = CountUniqueV2CUsage()
        Exit Function
    End If
    If hasCondition3 Then
        If Not CountUniqueV2CParseSort(Sort3, sourceCount, sortMode3, sortValues3) Then
            COUNTUNIQUE_V2C = CountUniqueV2CUsage()
            Exit Function
        End If
    End If
    If Not IsMissing(Heading) Then
        If Not IsError(Heading) Then hasHeading = (Len(CStr(Heading)) > 0)
    End If

    Set rowDict = CreateObject("Scripting.Dictionary")
    Set groupDict = CreateObject("Scripting.Dictionary")
    Set subDict = CreateObject("Scripting.Dictionary")
    Set countDict = CreateObject("Scripting.Dictionary")
    Set rowSortDict = CreateObject("Scripting.Dictionary")
    Set groupSortDict = CreateObject("Scripting.Dictionary")
    Set subSortDict = CreateObject("Scripting.Dictionary")
    rowDict.CompareMode = vbTextCompare
    groupDict.CompareMode = vbTextCompare
    subDict.CompareMode = vbTextCompare
    countDict.CompareMode = vbTextCompare
    rowSortDict.CompareMode = vbTextCompare
    groupSortDict.CompareMode = vbTextCompare
    subSortDict.CompareMode = vbTextCompare
    Set rowList = New Collection
    Set groupList = New Collection
    Set subList = New Collection

    For i = 1 To sourceCount
        rowValue = Condition1Range.Cells(i).Value2
        groupValue = Condition2Range.Cells(i).Value2
        If hasCondition3 Then
            subValue = condition3Range.Cells(i).Value2
        Else
            subValue = "__NO_CONDITION_3__"
        End If

        If CountUniqueV2CUsable(rowValue) And CountUniqueV2CUsable(groupValue) _
            And (Not hasCondition3 Or CountUniqueV2CUsable(subValue)) Then
            rowKey = CountUniqueV2CKey(rowValue)
            groupKey = CountUniqueV2CKey(groupValue)
            subKey = CountUniqueV2CKey(subValue)

            If Not rowDict.Exists(rowKey) Then
                rowDict.Add rowKey, rowList.Count + 1
                rowList.Add rowValue
                If sortMode1 = 2 Then rowSortDict.Add rowKey, sortValues1(i)
            End If
            If Not groupDict.Exists(groupKey) Then
                groupDict.Add groupKey, groupList.Count + 1
                groupList.Add groupValue
                If sortMode2 = 2 Then groupSortDict.Add groupKey, sortValues2(i)
            End If
            If Not subDict.Exists(subKey) Then
                subDict.Add subKey, subList.Count + 1
                subList.Add subValue
                If hasCondition3 And sortMode3 = 2 Then subSortDict.Add subKey, sortValues3(i)
            End If

            countKey = groupKey & ChrW$(30) & subKey & ChrW$(30) & rowKey
            If countDict.Exists(countKey) Then
                countDict(countKey) = countDict(countKey) + 1
            Else
                countDict.Add countKey, 1
            End If
        End If
    Next i
    If countDict.Count = 0 Then
        COUNTUNIQUE_V2C = ""
        Exit Function
    End If

    CountUniqueV2CToArray rowList, rowValues
    CountUniqueV2CToArray groupList, groupValues
    CountUniqueV2CToArray subList, subValues
    If sortMode1 <> 0 Then CountUniqueV2CSort rowValues, sortMode1, rowSortDict
    If sortMode2 <> 0 Then CountUniqueV2CSort groupValues, sortMode2, groupSortDict
    If hasCondition3 And sortMode3 <> 0 Then CountUniqueV2CSort subValues, sortMode3, subSortDict

    If hasCondition3 Then headerRows = 2 Else headerRows = 1
    If hasHeading Then headingRows = 1
    headerStart = headingRows + 1
    ReDim result(1 To UBound(rowValues) + headerRows + headingRows, _
                 1 To 1 + UBound(groupValues) * UBound(subValues))
    For i = 1 To UBound(result, 1)
        For j = 1 To UBound(result, 2)
            result(i, j) = ""
        Next j
    Next i
    If hasHeading Then result(1, 1) = Heading

    outputColumn = 2
    For i = 1 To UBound(groupValues)
        result(headerStart, outputColumn) = groupValues(i)
        For j = 1 To UBound(subValues)
            If hasCondition3 Then result(headerStart + 1, outputColumn) = subValues(j)
            outputColumn = outputColumn + 1
        Next j
    Next i

    For k = 1 To UBound(rowValues)
        rowKey = CountUniqueV2CKey(rowValues(k))
        outputRow = k + headerRows + headingRows
        result(outputRow, 1) = rowValues(k)
        outputColumn = 2
        For i = 1 To UBound(groupValues)
            groupKey = CountUniqueV2CKey(groupValues(i))
            For j = 1 To UBound(subValues)
                subKey = CountUniqueV2CKey(subValues(j))
                countKey = groupKey & ChrW$(30) & subKey & ChrW$(30) & rowKey
                If countDict.Exists(countKey) Then result(outputRow, outputColumn) = countDict(countKey)
                outputColumn = outputColumn + 1
            Next j
        Next i
    Next k
    COUNTUNIQUE_V2C = result
End Function

' Mode 0 = source order; 1 = ascending by value; 2 = custom sort keys.
Private Function CountUniqueV2CParseSort( _
    ByVal sortArgument As Variant, ByVal expectedCount As Long, _
    ByRef sortMode As Long, ByRef sortValues() As Variant) As Boolean

    Dim sourceRange As Range
    Dim i As Long, rowIndex As Long, columnIndex As Long
    Dim firstRow As Long, lastRow As Long, firstColumn As Long, lastColumn As Long
    Dim position As Long
    Dim numberValue As Double

    If IsObject(sortArgument) Then
        On Error Resume Next
        Set sourceRange = sortArgument
        On Error GoTo 0
        If sourceRange Is Nothing Then Exit Function
        If sourceRange.Cells.CountLarge = 1 Then
            If CountUniqueV2CFlag(sourceRange.Value2, sortMode) Then
                CountUniqueV2CParseSort = True
                Exit Function
            End If
        End If
        If sourceRange.Cells.CountLarge <> expectedCount Then Exit Function
        ReDim sortValues(1 To expectedCount)
        For i = 1 To expectedCount
            sortValues(i) = sourceRange.Cells(i).Value2
        Next i
        sortMode = 2
        CountUniqueV2CParseSort = True
        Exit Function
    End If

    If IsArray(sortArgument) Then
        On Error Resume Next
        firstRow = LBound(sortArgument, 1): lastRow = UBound(sortArgument, 1)
        If Err.Number <> 0 Then
            Err.Clear
            On Error GoTo 0
            Exit Function
        End If
        Err.Clear
        firstColumn = LBound(sortArgument, 2): lastColumn = UBound(sortArgument, 2)
        If Err.Number <> 0 Then
            Err.Clear
            On Error GoTo 0
            If lastRow - firstRow + 1 <> expectedCount Then Exit Function
            ReDim sortValues(1 To expectedCount)
            For rowIndex = firstRow To lastRow
                position = position + 1
                sortValues(position) = sortArgument(rowIndex)
            Next rowIndex
            sortMode = 2
            CountUniqueV2CParseSort = True
            Exit Function
        End If
        On Error GoTo 0
        If (lastRow - firstRow + 1) * (lastColumn - firstColumn + 1) <> expectedCount Then Exit Function
        ReDim sortValues(1 To expectedCount)
        For rowIndex = firstRow To lastRow
            For columnIndex = firstColumn To lastColumn
                position = position + 1
                sortValues(position) = sortArgument(rowIndex, columnIndex)
            Next columnIndex
        Next rowIndex
        sortMode = 2
        CountUniqueV2CParseSort = True
        Exit Function
    End If

    CountUniqueV2CParseSort = CountUniqueV2CFlag(sortArgument, sortMode)
End Function

Private Function CountUniqueV2CFlag(ByVal value As Variant, ByRef sortMode As Long) As Boolean
    If IsError(value) Or IsEmpty(value) Or IsNull(value) Then Exit Function
    If Not IsNumeric(value) Then Exit Function
    If CDbl(value) = 0 Or CDbl(value) = 1 Then
        sortMode = CLng(value)
        CountUniqueV2CFlag = True
    End If
End Function

Private Function CountUniqueV2CUsable(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Or IsNull(value) Then Exit Function
    CountUniqueV2CUsable = (Len(Trim$(CStr(value))) > 0)
End Function

Private Function CountUniqueV2CKey(ByVal value As Variant) As String
    CountUniqueV2CKey = TypeName(value) & "|" & CStr(value)
End Function

Private Sub CountUniqueV2CToArray(ByVal source As Collection, ByRef values() As Variant)
    Dim i As Long
    ReDim values(1 To source.Count)
    For i = 1 To source.Count
        values(i) = source(i)
    Next i
End Sub

Private Sub CountUniqueV2CSort(ByRef values() As Variant, ByVal sortMode As Long, ByVal sortKeys As Object)
    Dim i As Long, j As Long
    Dim temporary As Variant
    Dim leftKey As Variant, rightKey As Variant

    ' Insertion sort keeps the original order when two sort keys are equal.
    For i = LBound(values) + 1 To UBound(values)
        temporary = values(i)
        j = i - 1
        Do While j >= LBound(values)
            If sortMode = 2 Then
                leftKey = sortKeys(CountUniqueV2CKey(values(j)))
                rightKey = sortKeys(CountUniqueV2CKey(temporary))
            Else
                leftKey = values(j)
                rightKey = temporary
            End If
            If Not CountUniqueV2CComesAfter(leftKey, rightKey) Then Exit Do
            values(j + 1) = values(j)
            j = j - 1
        Loop
        values(j + 1) = temporary
    Next i
End Sub

Private Function CountUniqueV2CComesAfter(ByVal leftValue As Variant, ByVal rightValue As Variant) As Boolean
    Dim leftBlank As Boolean, rightBlank As Boolean
    leftBlank = Not CountUniqueV2CUsable(leftValue)
    rightBlank = Not CountUniqueV2CUsable(rightValue)
    If leftBlank Or rightBlank Then
        CountUniqueV2CComesAfter = (leftBlank And Not rightBlank)
    ElseIf IsNumeric(leftValue) And IsNumeric(rightValue) Then
        CountUniqueV2CComesAfter = (CDbl(leftValue) > CDbl(rightValue))
    Else
        CountUniqueV2CComesAfter = (StrComp(CStr(leftValue), CStr(rightValue), vbTextCompare) > 0)
    End If
End Function

Private Function CountUniqueV2CUsage() As Variant
    Dim result(1 To 6, 1 To 3) As Variant
    Dim i As Long, j As Long
    For i = 1 To UBound(result, 1)
        For j = 1 To UBound(result, 2)
            result(i, j) = ""
        Next j
    Next i
    result(1, 1) = "Invalid formula"
    result(2, 1) = "Two conditions"
    result(2, 3) = "=COUNTUNIQUE_V2C(A2:A100,1,B2:B100,0)"
    result(3, 1) = "Sort by formula results"
    result(3, 3) = "=COUNTUNIQUE_V2C(A2:A100,C2:C100,B2:B100,1)"
    result(4, 1) = "Three conditions"
    result(4, 3) = "=COUNTUNIQUE_V2C(A2:A100,1,B2:B100,0,D2:D100,1)"
    result(5, 1) = "Sort arguments"
    result(5, 3) = "0 = source order; 1 = ascending; or matching sort-key range"
    result(6, 1) = "Heading"
    result(6, 3) = "Optional final text argument"
    CountUniqueV2CUsage = result
End Function
