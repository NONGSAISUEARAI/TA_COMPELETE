Attribute VB_Name = "S_FUNC_Pack_Summary_v2_10"
Option Explicit

' Compatible with the fixed 40-item output of PACK_MULTI_v2_8.
' Item usage is read from Item1 through Item40.
' Summary columns are still located by their header names.
Public Function PACK_SUMMARY_v2_10( _
    ByVal ResultRange As Range, _
    ByVal SourceLengthRange As Range, _
    ByVal SourceQtyRange As Range, _
    Optional ByVal ItemListRowOffset As Long = 18) As Variant

    Dim data As Variant
    Dim targetDict As Object
    Dim targetWasteDict As Object
    Dim itemDict As Object
    Dim sourceDict As Object
    Dim result() As Variant
    Dim sourceKeys As Variant
    Dim key As Variant
    Dim targetKey As Double
    Dim sourceLength As Double
    Dim sourceQty As Double
    Dim gapValue As Double
    Dim totalTarget As Double
    Dim totalUsed As Double
    Dim totalGap As Double
    Dim runningTotal As Double
    Dim stockUse As Double
    Dim gapPercentTotal As Double
    Dim headerRow As Long
    Dim colGroup As Long
    Dim colTarget As Long
    Dim colCount As Long
    Dim colUsed As Long
    Dim colGap As Long
    Dim colGapPercent As Long
    Dim colItemStart As Long
    Dim colItemEnd As Long
    Dim rowCount As Long
    Dim itemValue As Double
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim keyIndex As Long

    If ResultRange.Cells.CountLarge < 2 Then
        PACK_SUMMARY_v2_10 = CVErr(xlErrRef)
        Exit Function
    End If

    If SourceLengthRange.Cells.CountLarge <> SourceQtyRange.Cells.CountLarge Then
        PACK_SUMMARY_v2_10 = CVErr(xlErrRef)
        Exit Function
    End If

    data = ResultRange.Value2

    headerRow = FindPackHeaderRowV210(data)

    If headerRow = 0 Then
        PACK_SUMMARY_v2_10 = CVErr(xlErrRef)
        Exit Function
    End If

    colGroup = FindHeaderColumnV210(data, headerRow, "Group")
    colTarget = FindHeaderColumnV210(data, headerRow, "Stock")
    colCount = FindHeaderColumnV210(data, headerRow, "Count")
    colUsed = FindHeaderColumnV210(data, headerRow, "Used")
    colGap = FindHeaderColumnV210(data, headerRow, "Gap")
    colGapPercent = FindHeaderColumnV210(data, headerRow, "Gap %")
    colItemStart = FindHeaderColumnV210(data, headerRow, "Item1")
    colItemEnd = FindHeaderColumnV210(data, headerRow, "Item40")

    If colGroup = 0 Or colTarget = 0 Or colCount = 0 _
        Or colUsed = 0 Or colGap = 0 Or colGapPercent = 0 _
        Or colItemStart = 0 Or colItemEnd = 0 Then
        PACK_SUMMARY_v2_10 = CVErr(xlErrRef)
        Exit Function
    End If

    If colItemEnd - colItemStart + 1 <> 40 _
        Or colCount <> colItemEnd + 1 Then
        PACK_SUMMARY_v2_10 = CVErr(xlErrRef)
        Exit Function
    End If

    Set targetDict = CreateObject("Scripting.Dictionary")
    Set targetWasteDict = CreateObject("Scripting.Dictionary")
    Set itemDict = CreateObject("Scripting.Dictionary")
    Set sourceDict = CreateObject("Scripting.Dictionary")

    For i = headerRow + 1 To UBound(data, 1)
        If IsUnpackRowV210(data(i, colGroup)) Then Exit For

        If IsUsableNumberV210(data(i, colGroup)) Then
            If IsUsableNumberV210(data(i, colGapPercent)) Then
                If Round(CDbl(data(i, colGapPercent)), 2) < 100 Then
                    If IsUsableNumberV210(data(i, colTarget)) Then
                        totalTarget = totalTarget + CDbl(data(i, colTarget))
                        targetKey = CDbl(data(i, colTarget))

                        If targetDict.Exists(targetKey) Then
                            targetDict(targetKey) = targetDict(targetKey) + 1
                        Else
                            targetDict.Add targetKey, 1
                        End If

                        If Not targetWasteDict.Exists(targetKey) Then
                            targetWasteDict.Add targetKey, 0#
                        End If

                        If IsUsableNumberV210(data(i, colGap)) Then
                            gapValue = CDbl(data(i, colGap))
                            targetWasteDict(targetKey) = _
                                targetWasteDict(targetKey) + gapValue
                        End If
                    End If

                    If IsUsableNumberV210(data(i, colUsed)) Then
                        totalUsed = totalUsed + CDbl(data(i, colUsed))
                    End If

                    If IsUsableNumberV210(data(i, colGap)) Then
                        totalGap = totalGap + CDbl(data(i, colGap))
                    End If

                    For k = colItemStart To colItemEnd
                        If IsUsableNumberV210(data(i, k)) Then
                            itemValue = CDbl(data(i, k))

                            If itemValue > 0 Then
                                If itemDict.Exists(itemValue) Then
                                    itemDict(itemValue) = itemDict(itemValue) + 1
                                Else
                                    itemDict.Add itemValue, 1
                                End If
                            End If
                        End If
                    Next k
                End If
            End If
        End If
    Next i

    For i = 1 To SourceLengthRange.Cells.CountLarge
        If Not IsError(SourceLengthRange.Cells(i).Value2) _
            And Not IsError(SourceQtyRange.Cells(i).Value2) Then

            If IsNumeric(SourceLengthRange.Cells(i).Value2) _
                And IsNumeric(SourceQtyRange.Cells(i).Value2) Then

                sourceLength = CDbl(SourceLengthRange.Cells(i).Value2)
                sourceQty = CDbl(SourceQtyRange.Cells(i).Value2)

                If sourceDict.Exists(sourceLength) Then
                    sourceDict(sourceLength) = sourceDict(sourceLength) + sourceQty
                Else
                    sourceDict.Add sourceLength, sourceQty
                End If

                runningTotal = runningTotal + (sourceLength * sourceQty)
            End If
        End If
    Next i

    If totalTarget <> 0 Then
        gapPercentTotal = Round((totalGap / totalTarget) * 100, 2)
    End If

    For Each key In targetDict
        stockUse = stockUse + (CDbl(key) * targetDict(key))
    Next key

    If ItemListRowOffset < 1 Then ItemListRowOffset = 1

    rowCount = 17 + targetDict.Count + sourceDict.Count + ItemListRowOffset
    ReDim result(1 To rowCount, 1 To 5)

    For i = 1 To rowCount
        For k = 1 To 5
            result(i, k) = ""
        Next k
    Next i

    result(1, 1) = "SUMMARY REPORT"
    result(2, 1) = "Target Total"
    result(2, 2) = ZeroBlankV210(totalTarget)
    result(3, 1) = "Used Total"
    result(3, 2) = ZeroBlankV210(totalUsed)
    result(4, 1) = "Running Total"
    result(4, 2) = ZeroBlankV210(runningTotal)
    result(5, 1) = "Stock Use"
    result(5, 2) = ZeroBlankV210(stockUse)
    result(6, 1) = "Gap Total"
    result(6, 2) = ZeroBlankV210(totalGap)
    result(7, 1) = "Gap Total %"
    result(7, 2) = ZeroBlankV210(gapPercentTotal)

    result(9, 1) = "Target used list"
    result(10, 1) = "Target"
    result(10, 2) = "Used Qty"
    result(10, 3) = "Total Length"
    result(10, 4) = "Total Waste"
    result(10, 5) = "Total Waste %"

    j = 11

    For Each key In targetDict
        result(j, 1) = key
        result(j, 2) = ZeroBlankV210(targetDict(key))
        result(j, 3) = ZeroBlankV210(CDbl(key) * targetDict(key))

        If targetWasteDict.Exists(key) Then
            result(j, 4) = ZeroBlankV210(targetWasteDict(key))

            If (CDbl(key) * targetDict(key)) <> 0 Then
                result(j, 5) = _
                    ZeroBlankV210(Round((targetWasteDict(key) / _
                    (CDbl(key) * targetDict(key))) * 100, 2))
            End If
        End If

        j = j + 1
    Next key

    j = j + ItemListRowOffset - 1
    result(j, 1) = "Item used list"
    j = j + 1

    result(j, 1) = "Length"
    result(j, 2) = "Source Qty"
    result(j, 3) = "Used Qty"
    result(j, 4) = "Remaining"
    j = j + 1

    If sourceDict.Count > 0 Then
        sourceKeys = sourceDict.Keys
        QuickSortNumericAscendingV210 _
            sourceKeys, LBound(sourceKeys), UBound(sourceKeys)

        For keyIndex = LBound(sourceKeys) To UBound(sourceKeys)
            key = sourceKeys(keyIndex)
            result(j, 1) = key
            result(j, 2) = ZeroBlankV210(sourceDict(key))

            If itemDict.Exists(key) Then
                result(j, 3) = ZeroBlankV210(itemDict(key))
            End If

            result(j, 4) = _
                ZeroBlankV210(sourceDict(key) - Val(result(j, 3)))
            j = j + 1
        Next keyIndex
    End If

    PACK_SUMMARY_v2_10 = result
End Function

Private Sub QuickSortNumericAscendingV210( _
    ByRef values As Variant, _
    ByVal first As Long, _
    ByVal last As Long)

    Dim low As Long
    Dim high As Long
    Dim pivot As Double
    Dim temporaryValue As Variant

    low = first
    high = last
    pivot = CDbl(values((first + last) \ 2))

    Do While low <= high
        Do While CDbl(values(low)) < pivot
            low = low + 1
        Loop

        Do While CDbl(values(high)) > pivot
            high = high - 1
        Loop

        If low <= high Then
            temporaryValue = values(low)
            values(low) = values(high)
            values(high) = temporaryValue
            low = low + 1
            high = high - 1
        End If
    Loop

    If first < high Then
        QuickSortNumericAscendingV210 values, first, high
    End If

    If low < last Then
        QuickSortNumericAscendingV210 values, low, last
    End If
End Sub

Private Function FindPackHeaderRowV210(ByVal data As Variant) As Long
    Dim maximumRow As Long
    Dim i As Long

    maximumRow = UBound(data, 1)
    If maximumRow > 10 Then maximumRow = 10

    For i = 1 To maximumRow
        If FindHeaderColumnV210(data, i, "Group") > 0 _
            And FindHeaderColumnV210(data, i, "Stock") > 0 Then
            FindPackHeaderRowV210 = i
            Exit Function
        End If
    Next i
End Function

Private Function FindHeaderColumnV210( _
    ByVal data As Variant, _
    ByVal headerRow As Long, _
    ByVal headerText As String) As Long

    Dim i As Long

    For i = 1 To UBound(data, 2)
        If Not IsError(data(headerRow, i)) Then
            If StrComp(Trim$(CStr(data(headerRow, i))), _
                headerText, vbTextCompare) = 0 Then

                FindHeaderColumnV210 = i
                Exit Function
            End If
        End If
    Next i
End Function

Private Function IsUsableNumberV210(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Then Exit Function
    IsUsableNumberV210 = IsNumeric(value)
End Function

Private Function IsUnpackRowV210(ByVal value As Variant) As Boolean
    Dim rowLabel As String

    If IsError(value) Or IsEmpty(value) Then Exit Function

    rowLabel = UCase$(Trim$(CStr(value)))
    IsUnpackRowV210 = (rowLabel = "UNPACK" _
        Or Left$(rowLabel, 7) = "UNPACK ")
End Function

Private Function ZeroBlankV210(ByVal value As Double) As Variant
    If value = 0 Then
        ZeroBlankV210 = ""
    Else
        ZeroBlankV210 = value
    End If
End Function
