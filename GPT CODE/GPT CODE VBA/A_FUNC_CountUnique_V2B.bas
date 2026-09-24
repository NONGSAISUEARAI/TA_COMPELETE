Attribute VB_Name = "A_FUNC_CountUnique_V2B"
Option Explicit

' COUNTUNIQUE_V2B adds sorting to V2 while retaining 2 or 3 conditions.
' Sort flags: 1 = ascending, 0 = keep source order.
' =COUNTUNIQUE_V2B(C1,Sort1,C2,Sort2)
' =COUNTUNIQUE_V2B(C1,Sort1,C2,Sort2,Heading)
' =COUNTUNIQUE_V2B(C1,Sort1,C2,Sort2,C3,Sort3)
' =COUNTUNIQUE_V2B(C1,Sort1,C2,Sort2,C3,Sort3,Heading)
Public Function COUNTUNIQUE_V2B( _
    ByVal Condition1Range As Range, ByVal Sort1 As Variant, _
    ByVal Condition2Range As Range, ByVal Sort2 As Variant, _
    Optional ByVal Condition3Argument As Variant, Optional ByVal Sort3 As Variant, _
    Optional ByVal Heading As Variant) As Variant

    Dim groupDict As Object, subDict As Object, rowDict As Object, countDict As Object
    Dim groups As Collection, subs As Collection, rows As Collection
    Dim groupValues() As Variant, subValues() As Variant, rowValues() As Variant, result() As Variant
    Dim c3 As Range, hasC3 As Boolean, hasHeading As Boolean
    Dim sortFlag1 As Long, sortFlag2 As Long, sortFlag3 As Long
    Dim g As Variant, s As Variant, r As Variant, amountKey As String
    Dim gKey As String, sKey As String, rKey As String
    Dim i As Long, j As Long, k As Long, outCol As Long, outRow As Long
    Dim headerRows As Long, headingRows As Long, headerStart As Long, totalColumns As Long

    If Not CountUniqueV2BFlag(Sort1, sortFlag1) Or Not CountUniqueV2BFlag(Sort2, sortFlag2) Then
        COUNTUNIQUE_V2B = CountUniqueV2BUsage(): Exit Function
    End If

    If Not IsMissing(Condition3Argument) Then
        If IsObject(Condition3Argument) Then
            On Error Resume Next: Set c3 = Condition3Argument: On Error GoTo 0
            If c3 Is Nothing Or IsMissing(Sort3) Or Not CountUniqueV2BFlag(Sort3, sortFlag3) Then
                COUNTUNIQUE_V2B = CountUniqueV2BUsage(): Exit Function
            End If
            hasC3 = True
        ElseIf IsMissing(Sort3) And IsMissing(Heading) Then
            Heading = Condition3Argument
        Else
            COUNTUNIQUE_V2B = CountUniqueV2BUsage(): Exit Function
        End If
    ElseIf Not IsMissing(Sort3) Then
        COUNTUNIQUE_V2B = CountUniqueV2BUsage(): Exit Function
    End If

    If Condition1Range.Cells.CountLarge <> Condition2Range.Cells.CountLarge Then
        COUNTUNIQUE_V2B = CVErr(xlErrRef): Exit Function
    End If
    If hasC3 Then
        If Condition1Range.Cells.CountLarge <> c3.Cells.CountLarge Then
            COUNTUNIQUE_V2B = CVErr(xlErrRef): Exit Function
        End If
    End If
    If Not IsMissing(Heading) Then If Not IsError(Heading) Then hasHeading = (Len(CStr(Heading)) > 0)

    Set groupDict = CreateObject("Scripting.Dictionary"): groupDict.CompareMode = vbTextCompare
    Set subDict = CreateObject("Scripting.Dictionary"): subDict.CompareMode = vbTextCompare
    Set rowDict = CreateObject("Scripting.Dictionary"): rowDict.CompareMode = vbTextCompare
    Set countDict = CreateObject("Scripting.Dictionary"): countDict.CompareMode = vbTextCompare
    Set groups = New Collection: Set subs = New Collection: Set rows = New Collection

    For i = 1 To Condition1Range.Cells.CountLarge
        r = Condition1Range.Cells(i).Value2: g = Condition2Range.Cells(i).Value2
        If hasC3 Then s = c3.Cells(i).Value2 Else s = "__NO_CONDITION_3__"
        If CountUniqueV2BUsable(r) And CountUniqueV2BUsable(g) And (Not hasC3 Or CountUniqueV2BUsable(s)) Then
            rKey = CountUniqueV2BKey(r): gKey = CountUniqueV2BKey(g): sKey = CountUniqueV2BKey(s)
            If Not rowDict.Exists(rKey) Then
                rowDict.Add rKey, rows.Count + 1
                rows.Add r, rKey
            End If
            If Not groupDict.Exists(gKey) Then
                groupDict.Add gKey, groups.Count + 1
                groups.Add g, gKey
            End If
            If Not subDict.Exists(sKey) Then
                subDict.Add sKey, subs.Count + 1
                subs.Add s, sKey
            End If
            If countDict.Exists(gKey & ChrW$(30) & sKey & ChrW$(30) & rKey) Then
                countDict(gKey & ChrW$(30) & sKey & ChrW$(30) & rKey) = countDict(gKey & ChrW$(30) & sKey & ChrW$(30) & rKey) + 1
            Else
                countDict.Add gKey & ChrW$(30) & sKey & ChrW$(30) & rKey, 1
            End If
        End If
    Next i
    If countDict.Count = 0 Then COUNTUNIQUE_V2B = "": Exit Function

    CountUniqueV2BCollectionToArray rows, rowValues
    CountUniqueV2BCollectionToArray groups, groupValues
    CountUniqueV2BCollectionToArray subs, subValues
    If sortFlag1 = 1 Then CountUniqueV2BSort rowValues
    If sortFlag2 = 1 Then CountUniqueV2BSort groupValues
    If hasC3 And sortFlag3 = 1 Then CountUniqueV2BSort subValues

    headerRows = IIf(hasC3, 2, 1): If hasHeading Then headingRows = 1
    headerStart = headingRows + 1: totalColumns = 1 + UBound(groupValues) * UBound(subValues)
    ReDim result(1 To UBound(rowValues) + headerRows + headingRows, 1 To totalColumns)
    ' Empty Variant cells spill as 0 in Excel; use empty strings instead.
    For i = 1 To UBound(result, 1)
        For j = 1 To UBound(result, 2)
            result(i, j) = ""
        Next j
    Next i
    If hasHeading Then result(1, 1) = Heading
    outCol = 2
    For i = LBound(groupValues) To UBound(groupValues)
        result(headerStart, outCol) = groupValues(i)
        For j = LBound(subValues) To UBound(subValues)
            If hasC3 Then result(headerStart + 1, outCol) = subValues(j)
            outCol = outCol + 1
        Next j
    Next i
    For k = LBound(rowValues) To UBound(rowValues)
        rKey = CountUniqueV2BKey(rowValues(k)): outRow = k + headerRows + headingRows
        result(outRow, 1) = rowValues(k): outCol = 2
        For i = LBound(groupValues) To UBound(groupValues)
            gKey = CountUniqueV2BKey(groupValues(i))
            For j = LBound(subValues) To UBound(subValues)
                sKey = CountUniqueV2BKey(subValues(j))
                amountKey = gKey & ChrW$(30) & sKey & ChrW$(30) & rKey
                If countDict.Exists(amountKey) Then result(outRow, outCol) = countDict(amountKey)
                outCol = outCol + 1
            Next j
        Next i
    Next k
    COUNTUNIQUE_V2B = result
End Function

Private Function CountUniqueV2BUsage() As Variant
    Dim a(1 To 5, 1 To 3) As Variant
    Dim i As Long, j As Long
    For i = 1 To UBound(a, 1)
        For j = 1 To UBound(a, 2)
            a(i, j) = ""
        Next j
    Next i
    a(1, 1) = "Invalid formula"
    a(2, 1) = "2 conditions": a(2, 3) = "=COUNTUNIQUE_V2B(A2:A100,1,B2:B100,0)"
    a(3, 1) = "3 conditions": a(3, 3) = "=COUNTUNIQUE_V2B(A2:A100,1,B2:B100,0,C2:C100,1)"
    a(4, 1) = "Sort flag": a(4, 3) = "1 = ascending | 0 = source order"
    a(5, 1) = "Heading": a(5, 3) = "Add a final text argument, for example \"CUTTING PLAN\""
    CountUniqueV2BUsage = a
End Function

Private Function CountUniqueV2BFlag(ByVal value As Variant, ByRef flag As Long) As Boolean
    If IsError(value) Or IsObject(value) Or IsEmpty(value) Or Not IsNumeric(value) Then Exit Function
    If CDbl(value) <> Fix(CDbl(value)) Then Exit Function
    flag = CLng(value): CountUniqueV2BFlag = (flag = 0 Or flag = 1)
End Function

Private Function CountUniqueV2BUsable(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Then Exit Function
    CountUniqueV2BUsable = (Len(Trim$(CStr(value))) > 0)
End Function

Private Function CountUniqueV2BKey(ByVal value As Variant) As String
    CountUniqueV2BKey = TypeName(value) & "|" & CStr(value)
End Function

Private Sub CountUniqueV2BCollectionToArray(ByVal source As Collection, ByRef values() As Variant)
    Dim i As Long: ReDim values(1 To source.Count)
    For i = 1 To source.Count: values(i) = source(i): Next i
End Sub

Private Sub CountUniqueV2BSort(ByRef values() As Variant)
    Dim i As Long, j As Long, temp As Variant
    For i = LBound(values) To UBound(values) - 1
        For j = i + 1 To UBound(values)
            If CountUniqueV2BComesAfter(values(i), values(j)) Then temp = values(i): values(i) = values(j): values(j) = temp
        Next j
    Next i
End Sub

Private Function CountUniqueV2BComesAfter(ByVal firstValue As Variant, ByVal secondValue As Variant) As Boolean
    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        CountUniqueV2BComesAfter = (CDbl(firstValue) > CDbl(secondValue))
    Else
        CountUniqueV2BComesAfter = (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function
