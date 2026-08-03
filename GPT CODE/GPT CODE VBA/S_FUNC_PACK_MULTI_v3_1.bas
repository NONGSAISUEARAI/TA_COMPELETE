Attribute VB_Name = "S_FUNC_PACK_MULTI_v3_1"
Option Explicit

' PACK_MULTI v3.1 is based on PACK_MULTI v2.8.
' Length cells may be either numeric or text in this form:
'     3000 (any material name or number)
' The leading number is used for calculations. The original text is retained
' in Stock, Item1..Item40, and UNPACK output cells.
'
' Syntax:
' =PACK_MULTI_v3_1(ValueRange,QtyRange,targetRange,TargetQtyRange, _
'                  TargetWasteRange,[MaxItemsPerStock],[Allowance], _
'                  [MaxSearchNodes])
Public Function PACK_MULTI_v3_1( _
    ByVal ValueRange As Range, _
    ByVal QtyRange As Range, _
    ByVal targetRange As Range, _
    ByVal TargetQtyRange As Range, _
    ByVal TargetWasteRange As Range, _
    Optional ByVal MaxItemsPerStock As Long = 8, _
    Optional ByVal Allowance As Double = 5, _
    Optional ByVal MaxSearchNodes As Long = 50000) As Variant

    Const OUTPUT_ITEM_COLUMNS As Long = 40
    Const EPSILON As Double = 0.0000001

    Dim itemValues As Variant
    Dim itemQuantities As Variant
    Dim stockValues As Variant
    Dim stockQuantities As Variant
    Dim stockWastes As Variant
    Dim items() As Double
    Dim itemLabels() As Variant
    Dim itemUsed() As Boolean
    Dim stockList() As Double
    Dim stockLabels() As Variant
    Dim wasteList() As Double
    Dim groups() As Collection
    Dim groupStock() As Double
    Dim groupStockLabel() As Variant
    Dim groupWaste() As Double
    Dim result() As Variant
    Dim parsedLength As Double
    Dim parsedLabel As Variant
    Dim itemCount As Long
    Dim stockCount As Long
    Dim unpackCount As Long
    Dim unpackRows As Long
    Dim unpackRow As Long
    Dim unpackColumn As Long
    Dim totalRows As Long
    Dim totalColumns As Long
    Dim stockIndex As Long
    Dim nodeCount As Long
    Dim searchStopped As Boolean
    Dim bestGap As Double
    Dim bestCombo As Collection
    Dim currentCombo As Collection
    Dim rawValue As Double
    Dim usedValue As Double
    Dim gapValue As Double
    Dim quantity As Long
    Dim itemIndex As Long
    Dim i As Long
    Dim j As Long
    Dim idx As Long
    Dim x As Variant

    If MaxItemsPerStock < 1 _
        Or MaxItemsPerStock > OUTPUT_ITEM_COLUMNS _
        Or MaxSearchNodes < 1 _
        Or Allowance < 0 Then

        PACK_MULTI_v3_1 = CVErr(xlErrValue)
        Exit Function
    End If

    If ValueRange.Cells.CountLarge <> QtyRange.Cells.CountLarge _
        Or targetRange.Cells.CountLarge <> TargetQtyRange.Cells.CountLarge _
        Or targetRange.Cells.CountLarge <> TargetWasteRange.Cells.CountLarge Then

        PACK_MULTI_v3_1 = CVErr(xlErrRef)
        Exit Function
    End If

    itemValues = RangeValuesV31(ValueRange)
    itemQuantities = RangeValuesV31(QtyRange)
    stockValues = RangeValuesV31(targetRange)
    stockQuantities = RangeValuesV31(TargetQtyRange)
    stockWastes = RangeValuesV31(TargetWasteRange)

    For i = 1 To ValueRange.Cells.CountLarge
        If Not TryGetNonNegativeLongV31( _
            ArrayValueV31(itemQuantities, i), quantity) Then

            PACK_MULTI_v3_1 = CVErr(xlErrValue)
            Exit Function
        End If

        If quantity > 0 Then
            If Not TryParseLengthV31( _
                ArrayValueV31(itemValues, i), _
                parsedLength, _
                parsedLabel) Then

                PACK_MULTI_v3_1 = CVErr(xlErrValue)
                Exit Function
            End If

            If itemCount > 2147483647# - quantity Then
                PACK_MULTI_v3_1 = CVErr(xlErrNum)
                Exit Function
            End If

            itemCount = itemCount + quantity
        End If
    Next i

    If itemCount = 0 Then
        PACK_MULTI_v3_1 = ""
        Exit Function
    End If

    ReDim items(1 To itemCount)
    ReDim itemLabels(1 To itemCount)
    ReDim itemUsed(1 To itemCount)
    idx = 1

    For i = 1 To ValueRange.Cells.CountLarge
        If Not TryGetNonNegativeLongV31( _
            ArrayValueV31(itemQuantities, i), quantity) Then

            PACK_MULTI_v3_1 = CVErr(xlErrValue)
            Exit Function
        End If

        If quantity > 0 Then
            If Not TryParseLengthV31( _
                ArrayValueV31(itemValues, i), _
                parsedLength, _
                parsedLabel) Then

                PACK_MULTI_v3_1 = CVErr(xlErrValue)
                Exit Function
            End If

            For j = 1 To quantity
                items(idx) = parsedLength
                itemLabels(idx) = parsedLabel
                idx = idx + 1
            Next j
        End If
    Next i

    QuickSortDescendingV31 _
        items, itemLabels, LBound(items), UBound(items)

    For i = 1 To targetRange.Cells.CountLarge
        If Not TryGetNonNegativeLongV31( _
            ArrayValueV31(stockQuantities, i), quantity) Then

            PACK_MULTI_v3_1 = CVErr(xlErrValue)
            Exit Function
        End If

        If quantity > 0 Then
            If Not TryParseLengthV31( _
                ArrayValueV31(stockValues, i), _
                parsedLength, _
                parsedLabel) _
                Or Not IsNonNegativeNumberV31( _
                    ArrayValueV31(stockWastes, i)) Then

                PACK_MULTI_v3_1 = CVErr(xlErrValue)
                Exit Function
            End If

            If stockCount > 2147483647# - quantity Then
                PACK_MULTI_v3_1 = CVErr(xlErrNum)
                Exit Function
            End If

            stockCount = stockCount + quantity
        End If
    Next i

    If stockCount = 0 Then
        PACK_MULTI_v3_1 = ""
        Exit Function
    End If

    ReDim stockList(1 To stockCount)
    ReDim stockLabels(1 To stockCount)
    ReDim wasteList(1 To stockCount)
    idx = 1

    For i = 1 To targetRange.Cells.CountLarge
        If Not TryGetNonNegativeLongV31( _
            ArrayValueV31(stockQuantities, i), quantity) Then

            PACK_MULTI_v3_1 = CVErr(xlErrValue)
            Exit Function
        End If

        If quantity > 0 Then
            If Not TryParseLengthV31( _
                ArrayValueV31(stockValues, i), _
                parsedLength, _
                parsedLabel) Then

                PACK_MULTI_v3_1 = CVErr(xlErrValue)
                Exit Function
            End If

            For j = 1 To quantity
                stockList(idx) = parsedLength
                stockLabels(idx) = parsedLabel
                wasteList(idx) = CDbl(ArrayValueV31(stockWastes, i))
                idx = idx + 1
            Next j
        End If
    Next i

    ReDim groups(1 To stockCount)
    ReDim groupStock(1 To stockCount)
    ReDim groupStockLabel(1 To stockCount)
    ReDim groupWaste(1 To stockCount)

    For i = 1 To stockCount
        Set groups(i) = New Collection
        groupStock(i) = stockList(i)
        groupStockLabel(i) = stockLabels(i)
        groupWaste(i) = wasteList(i)
    Next i

    For stockIndex = 1 To stockCount
        Set bestCombo = New Collection
        bestGap = 1E+308
        nodeCount = 0
        searchStopped = False

        FindGreedyComboV31 _
            items, itemUsed, itemCount, groupStock(stockIndex), _
            groupWaste(stockIndex), Allowance, MaxItemsPerStock, _
            bestCombo, bestGap

        If bestGap > EPSILON Then
            Set currentCombo = New Collection

            FindComboV31 _
                items, itemUsed, itemCount, groupStock(stockIndex), _
                groupWaste(stockIndex), Allowance, 1, currentCombo, 0, _
                MaxItemsPerStock, MaxSearchNodes, nodeCount, _
                searchStopped, bestCombo, bestGap
        End If

        For Each x In bestCombo
            itemIndex = CLng(x)
            groups(stockIndex).Add itemIndex
            itemUsed(itemIndex) = True
        Next x
    Next stockIndex

    For i = 1 To itemCount
        If Not itemUsed(i) Then unpackCount = unpackCount + 1
    Next i

    unpackRows = (unpackCount + OUTPUT_ITEM_COLUMNS - 1) \ _
        OUTPUT_ITEM_COLUMNS
    If unpackRows < 1 Then unpackRows = 1

    totalRows = stockCount + 1 + unpackRows
    totalColumns = OUTPUT_ITEM_COLUMNS + 8
    ReDim result(1 To totalRows, 1 To totalColumns)

    For i = 1 To totalRows
        For j = 1 To totalColumns
            result(i, j) = ""
        Next j
    Next i

    result(1, 1) = "Group"
    result(1, 2) = "Stock"

    For i = 1 To OUTPUT_ITEM_COLUMNS
        result(1, i + 2) = "Item" & i
    Next i

    result(1, OUTPUT_ITEM_COLUMNS + 3) = "Count"
    result(1, OUTPUT_ITEM_COLUMNS + 4) = "RawSum"
    result(1, OUTPUT_ITEM_COLUMNS + 5) = "Used"
    result(1, OUTPUT_ITEM_COLUMNS + 6) = "Allowed Waste"
    result(1, OUTPUT_ITEM_COLUMNS + 7) = "Gap"
    result(1, OUTPUT_ITEM_COLUMNS + 8) = "Gap %"

    For i = 1 To stockCount
        result(i + 1, 1) = i
        result(i + 1, 2) = groupStockLabel(i)

        For j = 1 To groups(i).Count
            itemIndex = CLng(groups(i)(j))
            result(i + 1, j + 2) = itemLabels(itemIndex)
        Next j

        rawValue = CollectionSumV31(groups(i), items)
        usedValue = rawValue + groups(i).Count * Allowance
        gapValue = groupStock(i) - usedValue

        result(i + 1, OUTPUT_ITEM_COLUMNS + 3) = groups(i).Count
        result(i + 1, OUTPUT_ITEM_COLUMNS + 4) = rawValue
        result(i + 1, OUTPUT_ITEM_COLUMNS + 5) = usedValue
        result(i + 1, OUTPUT_ITEM_COLUMNS + 6) = groupWaste(i)
        result(i + 1, OUTPUT_ITEM_COLUMNS + 7) = gapValue

        If groupStock(i) <> 0 Then
            result(i + 1, OUTPUT_ITEM_COLUMNS + 8) = _
                Round((gapValue / groupStock(i)) * 100, 2)
        End If
    Next i

    unpackRow = stockCount + 2
    result(unpackRow, 1) = "UNPACK"
    idx = 0

    For i = 1 To itemCount
        If Not itemUsed(i) Then
            If idx > 0 And idx Mod OUTPUT_ITEM_COLUMNS = 0 Then
                unpackRow = unpackRow + 1
                result(unpackRow, 1) = _
                    "UNPACK " & ((idx \ OUTPUT_ITEM_COLUMNS) + 1)
            End If

            unpackColumn = (idx Mod OUTPUT_ITEM_COLUMNS) + 3
            result(unpackRow, unpackColumn) = itemLabels(i)
            idx = idx + 1
        End If
    Next i

    PACK_MULTI_v3_1 = result
End Function

Private Sub FindGreedyComboV31( _
    ByRef items() As Double, _
    ByRef itemUsed() As Boolean, _
    ByVal itemCount As Long, _
    ByVal stock As Double, _
    ByVal waste As Double, _
    ByVal allowance As Double, _
    ByVal maxItems As Long, _
    ByRef bestCombo As Collection, _
    ByRef bestGap As Double)

    Dim candidate As Collection
    Dim rawSum As Double
    Dim usedValue As Double
    Dim gap As Double
    Dim i As Long

    Set candidate = New Collection

    For i = 1 To itemCount
        If Not itemUsed(i) Then
            usedValue = rawSum + items(i) _
                + (candidate.Count + 1) * allowance

            If usedValue <= stock Then
                candidate.Add i
                rawSum = rawSum + items(i)
                gap = stock - usedValue

                If gap <= waste And gap < bestGap Then
                    CopyCollectionV31 candidate, bestCombo
                    bestGap = gap
                End If

                If candidate.Count >= maxItems Then Exit For
            End If
        End If
    Next i
End Sub

Private Sub FindComboV31( _
    ByRef items() As Double, _
    ByRef itemUsed() As Boolean, _
    ByVal itemCount As Long, _
    ByVal stock As Double, _
    ByVal waste As Double, _
    ByVal allowance As Double, _
    ByVal startIndex As Long, _
    ByRef currentCombo As Collection, _
    ByVal currentSum As Double, _
    ByVal maxItems As Long, _
    ByVal maxSearchNodes As Long, _
    ByRef nodeCount As Long, _
    ByRef searchStopped As Boolean, _
    ByRef bestCombo As Collection, _
    ByRef bestGap As Double)

    Const EPSILON As Double = 0.0000001

    Dim newSum As Double
    Dim usedValue As Double
    Dim gap As Double
    Dim previousValue As Double
    Dim hasPreviousValue As Boolean
    Dim i As Long

    If searchStopped Then Exit Sub
    If currentCombo.Count >= maxItems Then Exit Sub

    For i = startIndex To itemCount
        If searchStopped Then Exit For

        If Not itemUsed(i) Then
            If Not hasPreviousValue _
                Or Abs(items(i) - previousValue) > EPSILON Then

                hasPreviousValue = True
                previousValue = items(i)
                nodeCount = nodeCount + 1

                If nodeCount >= maxSearchNodes Then
                    searchStopped = True
                    Exit For
                End If

                newSum = currentSum + items(i)
                usedValue = newSum _
                    + (currentCombo.Count + 1) * allowance

                If usedValue <= stock Then
                    currentCombo.Add i
                    gap = stock - usedValue

                    If gap <= waste And gap < bestGap Then
                        CopyCollectionV31 currentCombo, bestCombo
                        bestGap = gap

                        If bestGap <= EPSILON Then
                            currentCombo.Remove currentCombo.Count
                            searchStopped = True
                            Exit For
                        End If
                    End If

                    If currentCombo.Count < maxItems _
                        And gap > EPSILON Then

                        FindComboV31 _
                            items, itemUsed, itemCount, stock, waste, _
                            allowance, i + 1, currentCombo, newSum, _
                            maxItems, maxSearchNodes, nodeCount, _
                            searchStopped, bestCombo, bestGap
                    End If

                    currentCombo.Remove currentCombo.Count
                End If
            End If
        End If
    Next i
End Sub

Private Sub CopyCollectionV31( _
    ByVal source As Collection, _
    ByRef destination As Collection)

    Dim x As Variant

    Set destination = New Collection

    For Each x In source
        destination.Add x
    Next x
End Sub

Private Function CollectionSumV31( _
    ByVal itemIndexes As Collection, _
    ByRef items() As Double) As Double

    Dim x As Variant

    For Each x In itemIndexes
        CollectionSumV31 = CollectionSumV31 + items(CLng(x))
    Next x
End Function

Private Sub QuickSortDescendingV31( _
    ByRef values() As Double, _
    ByRef labels() As Variant, _
    ByVal first As Long, _
    ByVal last As Long)

    Dim low As Long
    Dim high As Long
    Dim pivot As Double
    Dim temporaryValue As Double
    Dim temporaryLabel As Variant

    low = first
    high = last
    pivot = values((first + last) \ 2)

    Do While low <= high
        Do While values(low) > pivot
            low = low + 1
        Loop

        Do While values(high) < pivot
            high = high - 1
        Loop

        If low <= high Then
            temporaryValue = values(low)
            values(low) = values(high)
            values(high) = temporaryValue

            temporaryLabel = labels(low)
            labels(low) = labels(high)
            labels(high) = temporaryLabel

            low = low + 1
            high = high - 1
        End If
    Loop

    If first < high Then
        QuickSortDescendingV31 values, labels, first, high
    End If

    If low < last Then
        QuickSortDescendingV31 values, labels, low, last
    End If
End Sub

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

Private Function RangeValuesV31(ByVal source As Range) As Variant
    If source.Cells.CountLarge = 1 Then
        Dim singleValue(1 To 1, 1 To 1) As Variant
        singleValue(1, 1) = source.Value2
        RangeValuesV31 = singleValue
    Else
        RangeValuesV31 = source.Value2
    End If
End Function

Private Function ArrayValueV31( _
    ByVal values As Variant, _
    ByVal linearIndex As Long) As Variant

    Dim rowCount As Long
    Dim columnCount As Long
    Dim rowIndex As Long
    Dim columnIndex As Long

    rowCount = UBound(values, 1)
    columnCount = UBound(values, 2)
    rowIndex = ((linearIndex - 1) Mod rowCount) + 1
    columnIndex = ((linearIndex - 1) \ rowCount) + 1

    If columnIndex > columnCount Then
        ArrayValueV31 = CVErr(xlErrRef)
    Else
        ArrayValueV31 = values(rowIndex, columnIndex)
    End If
End Function

Private Function TryGetNonNegativeLongV31( _
    ByVal value As Variant, _
    ByRef resultValue As Long) As Boolean

    If IsError(value) Then Exit Function

    If IsEmpty(value) Or Len(Trim$(CStr(value))) = 0 Then
        resultValue = 0
        TryGetNonNegativeLongV31 = True
        Exit Function
    End If

    If Not IsNumeric(value) Then Exit Function
    If CDbl(value) < 0 Or CDbl(value) <> Fix(CDbl(value)) Then Exit Function
    If CDbl(value) > 2147483647# Then Exit Function

    resultValue = CLng(value)
    TryGetNonNegativeLongV31 = True
End Function

Private Function IsNonNegativeNumberV31(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Or Not IsNumeric(value) Then Exit Function
    IsNonNegativeNumberV31 = (CDbl(value) >= 0)
End Function
