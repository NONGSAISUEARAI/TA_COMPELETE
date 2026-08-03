Attribute VB_Name = "S_FUNC_Pack_Summary_v3_1"
Option Explicit

' Compatible with PACK_MULTI_v3_1 and its fixed Item1..Item40 output.
' Numeric prefixes are used for calculations, while complete labels such as
' 3000 (Material A) remain separate entries in the summary.
Public Function PACK_SUMMARY_v3_1( _
    ByVal ResultRange As Range, _
    ByVal SourceLengthRange As Range, _
    ByVal SourceQtyRange As Range, _
    Optional ByVal ItemListRowOffset As Long = 18) As Variant

    Dim data As Variant
    Dim targetDict As Object
    Dim targetLengthDict As Object
    Dim targetLabelDict As Object
    Dim targetWasteDict As Object
    Dim itemDict As Object
    Dim sourceDict As Object
    Dim sourceLengthDict As Object
    Dim sourceLabelDict As Object
    Dim result() As Variant
    Dim sourceKeys As Variant
    Dim key As Variant
    Dim parsedLength As Double
    Dim parsedLabel As Variant
    Dim parsedKey As String
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
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim keyIndex As Long

    If ResultRange.Cells.CountLarge < 2 Then
        PACK_SUMMARY_v3_1 = CVErr(xlErrRef)
        Exit Function
    End If

    If SourceLengthRange.Cells.CountLarge <> SourceQtyRange.Cells.CountLarge Then
        PACK_SUMMARY_v3_1 = CVErr(xlErrRef)
        Exit Function
    End If

    data = ResultRange.Value2
    headerRow = FindPackHeaderRowV31(data)

    If headerRow = 0 Then
        PACK_SUMMARY_v3_1 = CVErr(xlErrRef)
        Exit Function
    End If

    colGroup = FindHeaderColumnV31(data, headerRow, "Group")
    colTarget = FindHeaderColumnV31(data, headerRow, "Stock")
    colCount = FindHeaderColumnV31(data, headerRow, "Count")
    colUsed = FindHeaderColumnV31(data, headerRow, "Used")
    colGap = FindHeaderColumnV31(data, headerRow, "Gap")
    colGapPercent = FindHeaderColumnV31(data, headerRow, "Gap %")
    colItemStart = FindHeaderColumnV31(data, headerRow, "Item1")
    colItemEnd = FindHeaderColumnV31(data, headerRow, "Item40")

    If colGroup = 0 Or colTarget = 0 Or colCount = 0 _
        Or colUsed = 0 Or colGap = 0 Or colGapPercent = 0 _
        Or colItemStart = 0 Or colItemEnd = 0 Then

        PACK_SUMMARY_v3_1 = CVErr(xlErrRef)
        Exit Function
    End If

    If colItemEnd - colItemStart + 1 <> 40 _
        Or colCount <> colItemEnd + 1 Then

        PACK_SUMMARY_v3_1 = CVErr(xlErrRef)
        Exit Function
    End If

    Set targetDict = NewTextDictionaryV31()
    Set targetLengthDict = NewTextDictionaryV31()
    Set targetLabelDict = NewTextDictionaryV31()
    Set targetWasteDict = NewTextDictionaryV31()
    Set itemDict = NewTextDictionaryV31()
    Set sourceDict = NewTextDictionaryV31()
    Set sourceLengthDict = NewTextDictionaryV31()
    Set sourceLabelDict = NewTextDictionaryV31()

    For i = headerRow + 1 To UBound(data, 1)
        If IsUnpackRowV31(data(i, colGroup)) Then Exit For

        If IsUsableNumberV31(data(i, colGroup)) _
            And IsUsableNumberV31(data(i, colGapPercent)) Then

            If Round(CDbl(data(i, colGapPercent)), 2) < 100 Then
                If TryParseLengthV31( _
                    data(i, colTarget), parsedLength, parsedLabel) Then

                    parsedKey = LengthLabelKeyV31(parsedLabel)
                    totalTarget = totalTarget + parsedLength

                    If targetDict.Exists(parsedKey) Then
                        targetDict(parsedKey) = targetDict(parsedKey) + 1
                    Else
                        targetDict.Add parsedKey, 1
                        targetLengthDict.Add parsedKey, parsedLength
                        targetLabelDict.Add parsedKey, parsedLabel
                        targetWasteDict.Add parsedKey, 0#
                    End If

                    If IsUsableNumberV31(data(i, colGap)) Then
                        gapValue = CDbl(data(i, colGap))
                        targetWasteDict(parsedKey) = _
                            targetWasteDict(parsedKey) + gapValue
                    End If
                End If

                If IsUsableNumberV31(data(i, colUsed)) Then
                    totalUsed = totalUsed + CDbl(data(i, colUsed))
                End If

                If IsUsableNumberV31(data(i, colGap)) Then
                    totalGap = totalGap + CDbl(data(i, colGap))
                End If

                For k = colItemStart To colItemEnd
                    If TryParseLengthV31( _
                        data(i, k), parsedLength, parsedLabel) Then

                        parsedKey = LengthLabelKeyV31(parsedLabel)

                        If itemDict.Exists(parsedKey) Then
                            itemDict(parsedKey) = itemDict(parsedKey) + 1
                        Else
                            itemDict.Add parsedKey, 1
                        End If
                    End If
                Next k
            End If
        End If
    Next i

    For i = 1 To SourceLengthRange.Cells.CountLarge
        If TryParseLengthV31( _
            SourceLengthRange.Cells(i).Value2, _
            parsedLength, _
            parsedLabel) Then

            If TryGetNonNegativeDoubleV31( _
                SourceQtyRange.Cells(i).Value2, sourceQty) Then

                parsedKey = LengthLabelKeyV31(parsedLabel)

                If sourceDict.Exists(parsedKey) Then
                    sourceDict(parsedKey) = sourceDict(parsedKey) + sourceQty
                Else
                    sourceDict.Add parsedKey, sourceQty
                    sourceLengthDict.Add parsedKey, parsedLength
                    sourceLabelDict.Add parsedKey, parsedLabel
                End If

                runningTotal = runningTotal + (parsedLength * sourceQty)
            End If
        End If
    Next i

    If totalTarget <> 0 Then
        gapPercentTotal = Round((totalGap / totalTarget) * 100, 2)
    End If

    For Each key In targetDict.Keys
        stockUse = stockUse _
            + (CDbl(targetLengthDict(key)) * CDbl(targetDict(key)))
    Next key

    If ItemListRowOffset < 1 Then ItemListRowOffset = 1

    rowCount = 17 + targetDict.Count + sourceDict.Count _
        + ItemListRowOffset
    ReDim result(1 To rowCount, 1 To 5)

    For i = 1 To rowCount
        For k = 1 To 5
            result(i, k) = ""
        Next k
    Next i

    result(1, 1) = "SUMMARY REPORT"
    result(2, 1) = "Target Total"
    result(2, 2) = ZeroBlankV31(totalTarget)
    result(3, 1) = "Used Total"
    result(3, 2) = ZeroBlankV31(totalUsed)
    result(4, 1) = "Running Total"
    result(4, 2) = ZeroBlankV31(runningTotal)
    result(5, 1) = "Stock Use"
    result(5, 2) = ZeroBlankV31(stockUse)
    result(6, 1) = "Gap Total"
    result(6, 2) = ZeroBlankV31(totalGap)
    result(7, 1) = "Gap Total %"
    result(7, 2) = ZeroBlankV31(gapPercentTotal)

    result(9, 1) = "Target used list"
    result(10, 1) = "Target"
    result(10, 2) = "Used Qty"
    result(10, 3) = "Total Length"
    result(10, 4) = "Total Waste"
    result(10, 5) = "Total Waste %"

    j = 11

    For Each key In targetDict.Keys
        result(j, 1) = targetLabelDict(key)
        result(j, 2) = ZeroBlankV31(CDbl(targetDict(key)))
        result(j, 3) = ZeroBlankV31( _
            CDbl(targetLengthDict(key)) * CDbl(targetDict(key)))
        result(j, 4) = ZeroBlankV31(CDbl(targetWasteDict(key)))

        If CDbl(result(j, 3)) <> 0 Then
            result(j, 5) = ZeroBlankV31( _
                Round((CDbl(targetWasteDict(key)) / _
                CDbl(result(j, 3))) * 100, 2))
        End If

        j = j + 1
    Next key

    j = j + ItemListRowOffset - 1
    result(j, 1) = "Item used list"
    j = j + 1

    result(j, 1) = "Length / Material"
    result(j, 2) = "Source Qty"
    result(j, 3) = "Used Qty"
    result(j, 4) = "Remaining"
    j = j + 1

    If sourceDict.Count > 0 Then
        sourceKeys = sourceDict.Keys
        QuickSortLengthKeysAscendingV31 _
            sourceKeys, sourceLengthDict, sourceLabelDict, _
            LBound(sourceKeys), UBound(sourceKeys)

        For keyIndex = LBound(sourceKeys) To UBound(sourceKeys)
            key = sourceKeys(keyIndex)
            result(j, 1) = sourceLabelDict(key)
            result(j, 2) = ZeroBlankV31(CDbl(sourceDict(key)))

            If itemDict.Exists(key) Then
                result(j, 3) = ZeroBlankV31(CDbl(itemDict(key)))
            End If

            result(j, 4) = ZeroBlankV31( _
                CDbl(sourceDict(key)) - Val(CStr(result(j, 3))))
            j = j + 1
        Next keyIndex
    End If

    PACK_SUMMARY_v3_1 = result
End Function

Private Function NewTextDictionaryV31() As Object
    Dim dictionary As Object

    Set dictionary = CreateObject("Scripting.Dictionary")
    dictionary.CompareMode = vbTextCompare
    Set NewTextDictionaryV31 = dictionary
End Function

Private Sub QuickSortLengthKeysAscendingV31( _
    ByRef keys As Variant, _
    ByVal lengthDict As Object, _
    ByVal labelDict As Object, _
    ByVal first As Long, _
    ByVal last As Long)

    Dim low As Long
    Dim high As Long
    Dim pivotKey As Variant
    Dim temporaryKey As Variant

    low = first
    high = last
    pivotKey = keys((first + last) \ 2)

    Do While low <= high
        Do While CompareLengthKeysV31( _
            keys(low), pivotKey, lengthDict, labelDict) < 0

            low = low + 1
        Loop

        Do While CompareLengthKeysV31( _
            keys(high), pivotKey, lengthDict, labelDict) > 0

            high = high - 1
        Loop

        If low <= high Then
            temporaryKey = keys(low)
            keys(low) = keys(high)
            keys(high) = temporaryKey
            low = low + 1
            high = high - 1
        End If
    Loop

    If first < high Then
        QuickSortLengthKeysAscendingV31 _
            keys, lengthDict, labelDict, first, high
    End If

    If low < last Then
        QuickSortLengthKeysAscendingV31 _
            keys, lengthDict, labelDict, low, last
    End If
End Sub

Private Function CompareLengthKeysV31( _
    ByVal firstKey As Variant, _
    ByVal secondKey As Variant, _
    ByVal lengthDict As Object, _
    ByVal labelDict As Object) As Long

    Dim firstLength As Double
    Dim secondLength As Double

    firstLength = CDbl(lengthDict(firstKey))
    secondLength = CDbl(lengthDict(secondKey))

    If firstLength < secondLength Then
        CompareLengthKeysV31 = -1
    ElseIf firstLength > secondLength Then
        CompareLengthKeysV31 = 1
    Else
        CompareLengthKeysV31 = StrComp( _
            CStr(labelDict(firstKey)), _
            CStr(labelDict(secondKey)), _
            vbTextCompare)
    End If
End Function

Private Function TryParseLengthV31( _
    ByVal rawValue As Variant, _
    ByRef numericLength As Double, _
    ByRef displayValue As Variant) As Boolean

    Dim textValue As String
    Dim numberText As String
    Dim openPosition As Long

    If IsError(rawValue) Or IsEmpty(rawValue) Then Exit Function

    If IsNumeric(rawValue) Then
        numericLength = CDbl(rawValue)
        If numericLength <= 0 Then Exit Function

        displayValue = rawValue
        TryParseLengthV31 = True
        Exit Function
    End If

    textValue = Trim$(CStr(rawValue))
    If Len(textValue) = 0 Then Exit Function

    openPosition = InStr(1, textValue, "(", vbBinaryCompare)

    If openPosition > 0 Then
        If Right$(textValue, 1) <> ")" Then Exit Function
        numberText = Trim$(Left$(textValue, openPosition - 1))
    Else
        numberText = textValue
    End If

    If Len(numberText) = 0 Or Not IsNumeric(numberText) Then Exit Function

    numericLength = CDbl(numberText)
    If numericLength <= 0 Then Exit Function

    If openPosition > 0 Then
        displayValue = textValue
    Else
        displayValue = numericLength
    End If

    TryParseLengthV31 = True
End Function

Private Function LengthLabelKeyV31(ByVal displayValue As Variant) As String
    If IsNumeric(displayValue) Then
        LengthLabelKeyV31 = "N|" & CStr(CDbl(displayValue))
    Else
        LengthLabelKeyV31 = "T|" & Trim$(CStr(displayValue))
    End If
End Function

Private Function TryGetNonNegativeDoubleV31( _
    ByVal value As Variant, _
    ByRef resultValue As Double) As Boolean

    If IsError(value) Or IsEmpty(value) Then Exit Function
    If Len(Trim$(CStr(value))) = 0 Or Not IsNumeric(value) Then Exit Function

    resultValue = CDbl(value)
    If resultValue < 0 Then Exit Function

    TryGetNonNegativeDoubleV31 = True
End Function

Private Function FindPackHeaderRowV31(ByVal data As Variant) As Long
    Dim maximumRow As Long
    Dim i As Long

    maximumRow = UBound(data, 1)
    If maximumRow > 10 Then maximumRow = 10

    For i = 1 To maximumRow
        If FindHeaderColumnV31(data, i, "Group") > 0 _
            And FindHeaderColumnV31(data, i, "Stock") > 0 Then

            FindPackHeaderRowV31 = i
            Exit Function
        End If
    Next i
End Function

Private Function FindHeaderColumnV31( _
    ByVal data As Variant, _
    ByVal headerRow As Long, _
    ByVal headerText As String) As Long

    Dim i As Long

    For i = 1 To UBound(data, 2)
        If Not IsError(data(headerRow, i)) Then
            If StrComp( _
                Trim$(CStr(data(headerRow, i))), _
                headerText, _
                vbTextCompare) = 0 Then

                FindHeaderColumnV31 = i
                Exit Function
            End If
        End If
    Next i
End Function

Private Function IsUsableNumberV31(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Then Exit Function
    IsUsableNumberV31 = IsNumeric(value)
End Function

Private Function IsUnpackRowV31(ByVal value As Variant) As Boolean
    Dim rowLabel As String

    If IsError(value) Or IsEmpty(value) Then Exit Function

    rowLabel = UCase$(Trim$(CStr(value)))
    IsUnpackRowV31 = (rowLabel = "UNPACK" _
        Or Left$(rowLabel, 7) = "UNPACK ")
End Function

Private Function ZeroBlankV31(ByVal value As Double) As Variant
    If value = 0 Then
        ZeroBlankV31 = ""
    Else
        ZeroBlankV31 = value
    End If
End Function
