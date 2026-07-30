Attribute VB_Name = "S_FUNC_PACK_MULTI_v2_8"
Option Explicit

' Optimized packing function.
'
' Syntax:
' =PACK_MULTI_v2_8(ValueRange,QtyRange,targetRange,TargetQtyRange, _
'                  TargetWasteRange,[Allowance],[MaxSearchNodes])
'
' MaxSearchNodes limits the recursive search for each stock.
' A finite limit prevents large data sets from freezing Excel.
Public Function PACK_MULTI_v2_8( _
    ByVal ValueRange As Range, _
    ByVal QtyRange As Range, _
    ByVal targetRange As Range, _
    ByVal TargetQtyRange As Range, _
    ByVal TargetWasteRange As Range, _
    Optional ByVal Allowance As Double = 5, _
    Optional ByVal MaxSearchNodes As Long = 50000) As Variant

    Const MAX_ITEMS_PER_STOCK As Long = 8
    Const OUTPUT_ITEM_COLUMNS As Long = 40
    Const EPSILON As Double = 0.0000001

    Dim itemValues As Variant
    Dim itemQuantities As Variant
    Dim stockValues As Variant
    Dim stockQuantities As Variant
    Dim stockWastes As Variant
    Dim items() As Double
    Dim itemUsed() As Boolean
    Dim stockList() As Double
    Dim wasteList() As Double
    Dim groups() As Collection
    Dim groupStock() As Double
    Dim groupWaste() As Double
    Dim result() As Variant
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
    Dim i As Long
    Dim j As Long
    Dim idx As Long
    Dim x As Variant

    If MaxSearchNodes < 1 Or Allowance < 0 Then
        PACK_MULTI_v2_8 = CVErr(xlErrValue)
        Exit Function
    End If

    If ValueRange.Cells.CountLarge <> QtyRange.Cells.CountLarge _
        Or targetRange.Cells.CountLarge <> TargetQtyRange.Cells.CountLarge _
        Or targetRange.Cells.CountLarge <> TargetWasteRange.Cells.CountLarge Then
        PACK_MULTI_v2_8 = CVErr(xlErrRef)
        Exit Function
    End If

    itemValues = RangeValuesV28(ValueRange)
    itemQuantities = RangeValuesV28(QtyRange)
    stockValues = RangeValuesV28(targetRange)
    stockQuantities = RangeValuesV28(TargetQtyRange)
    stockWastes = RangeValuesV28(TargetWasteRange)

    For i = 1 To ValueRange.Cells.CountLarge
        If Not TryGetNonNegativeLongV28(ArrayValueV28(itemQuantities, i), quantity) Then
            PACK_MULTI_v2_8 = CVErr(xlErrValue)
            Exit Function
        End If

        If quantity > 0 Then
            If Not IsPositiveNumberV28(ArrayValueV28(itemValues, i)) Then
                PACK_MULTI_v2_8 = CVErr(xlErrValue)
                Exit Function
            End If

            If itemCount > 2147483647# - quantity Then
                PACK_MULTI_v2_8 = CVErr(xlErrNum)
                Exit Function
            End If

            itemCount = itemCount + quantity
        End If
    Next i

    If itemCount = 0 Then
        PACK_MULTI_v2_8 = ""
        Exit Function
    End If

    ReDim items(1 To itemCount)
    ReDim itemUsed(1 To itemCount)
    idx = 1

    For i = 1 To ValueRange.Cells.CountLarge
        quantity = CLng(ArrayValueV28(itemQuantities, i))

        For j = 1 To quantity
            items(idx) = CDbl(ArrayValueV28(itemValues, i))
            idx = idx + 1
        Next j
    Next i

    QuickSortDescendingV28 items, LBound(items), UBound(items)

    For i = 1 To targetRange.Cells.CountLarge
        If Not TryGetNonNegativeLongV28(ArrayValueV28(stockQuantities, i), quantity) Then
            PACK_MULTI_v2_8 = CVErr(xlErrValue)
            Exit Function
        End If

        If quantity > 0 Then
            If Not IsPositiveNumberV28(ArrayValueV28(stockValues, i)) _
                Or Not IsNonNegativeNumberV28(ArrayValueV28(stockWastes, i)) Then
                PACK_MULTI_v2_8 = CVErr(xlErrValue)
                Exit Function
            End If

            If stockCount > 2147483647# - quantity Then
                PACK_MULTI_v2_8 = CVErr(xlErrNum)
                Exit Function
            End If

            stockCount = stockCount + quantity
        End If
    Next i

    If stockCount = 0 Then
        PACK_MULTI_v2_8 = ""
        Exit Function
    End If

    ReDim stockList(1 To stockCount)
    ReDim wasteList(1 To stockCount)
    idx = 1

    For i = 1 To targetRange.Cells.CountLarge
        quantity = CLng(ArrayValueV28(stockQuantities, i))

        For j = 1 To quantity
            stockList(idx) = CDbl(ArrayValueV28(stockValues, i))
            wasteList(idx) = CDbl(ArrayValueV28(stockWastes, i))
            idx = idx + 1
        Next j
    Next i

    ReDim groups(1 To stockCount)
    ReDim groupStock(1 To stockCount)
    ReDim groupWaste(1 To stockCount)

    For i = 1 To stockCount
        Set groups(i) = New Collection
        groupStock(i) = stockList(i)
        groupWaste(i) = wasteList(i)
    Next i

    For stockIndex = 1 To stockCount
        Set bestCombo = New Collection
        bestGap = 1E+308
        nodeCount = 0
        searchStopped = False

        ' Establish a useful answer early so branch-and-bound can prune sooner.
        FindGreedyComboV28 _
            items, itemUsed, itemCount, groupStock(stockIndex), _
            groupWaste(stockIndex), Allowance, MAX_ITEMS_PER_STOCK, _
            bestCombo, bestGap

        If bestGap > Allowance + EPSILON Then
            Set currentCombo = New Collection

            FindComboV28 _
                items, itemUsed, itemCount, groupStock(stockIndex), _
                groupWaste(stockIndex), Allowance, 1, currentCombo, 0, _
                MAX_ITEMS_PER_STOCK, MaxSearchNodes, nodeCount, _
                searchStopped, bestCombo, bestGap
        End If

        For Each x In bestCombo
            groups(stockIndex).Add items(CLng(x))
            itemUsed(CLng(x)) = True
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
        result(i + 1, 2) = groupStock(i)

        For j = 1 To groups(i).Count
            result(i + 1, j + 2) = groups(i)(j)
        Next j

        rawValue = CollectionSumV28(groups(i))
        usedValue = rawValue + groups(i).Count * Allowance
        gapValue = groupStock(i) - rawValue

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
            result(unpackRow, unpackColumn) = items(i)
            idx = idx + 1
        End If
    Next i

    PACK_MULTI_v2_8 = result
End Function

Private Sub FindGreedyComboV28( _
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
            usedValue = rawSum + items(i) + (candidate.Count + 1) * allowance

            If usedValue <= stock Then
                candidate.Add i
                rawSum = rawSum + items(i)
                gap = stock - rawSum

                If gap <= waste And gap < bestGap Then
                    CopyCollectionV28 candidate, bestCombo
                    bestGap = gap
                End If

                If candidate.Count >= maxItems Then Exit For
            End If
        End If
    Next i
End Sub

Private Sub FindComboV28( _
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
            ' Equal lengths at the same recursion level create equivalent branches.
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
                usedValue = newSum + (currentCombo.Count + 1) * allowance

                If usedValue <= stock Then
                    currentCombo.Add i
                    gap = stock - newSum

                    If gap <= waste And gap < bestGap Then
                        CopyCollectionV28 currentCombo, bestCombo
                        bestGap = gap

                        ' No valid combination can beat the one-item allowance floor.
                        If bestGap <= allowance + EPSILON Then
                            currentCombo.Remove currentCombo.Count
                            searchStopped = True
                            Exit For
                        End If
                    End If

                    If currentCombo.Count < maxItems _
                        And gap > allowance + EPSILON Then

                        FindComboV28 _
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

Private Sub CopyCollectionV28( _
    ByVal source As Collection, _
    ByRef destination As Collection)

    Dim x As Variant

    Set destination = New Collection

    For Each x In source
        destination.Add x
    Next x
End Sub

Private Function CollectionSumV28(ByVal col As Collection) As Double
    Dim x As Variant

    For Each x In col
        CollectionSumV28 = CollectionSumV28 + CDbl(x)
    Next x
End Function

Private Sub QuickSortDescendingV28( _
    ByRef values() As Double, _
    ByVal first As Long, _
    ByVal last As Long)

    Dim low As Long
    Dim high As Long
    Dim pivot As Double
    Dim temporaryValue As Double

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
            low = low + 1
            high = high - 1
        End If
    Loop

    If first < high Then QuickSortDescendingV28 values, first, high
    If low < last Then QuickSortDescendingV28 values, low, last
End Sub

Private Function RangeValuesV28(ByVal source As Range) As Variant
    If source.Cells.CountLarge = 1 Then
        Dim singleValue(1 To 1, 1 To 1) As Variant
        singleValue(1, 1) = source.Value2
        RangeValuesV28 = singleValue
    Else
        RangeValuesV28 = source.Value2
    End If
End Function

Private Function ArrayValueV28( _
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
        ArrayValueV28 = CVErr(xlErrRef)
    Else
        ArrayValueV28 = values(rowIndex, columnIndex)
    End If
End Function

Private Function TryGetNonNegativeLongV28( _
    ByVal value As Variant, _
    ByRef resultValue As Long) As Boolean

    If IsError(value) Then Exit Function

    If IsEmpty(value) Or Len(Trim$(CStr(value))) = 0 Then
        resultValue = 0
        TryGetNonNegativeLongV28 = True
        Exit Function
    End If

    If Not IsNumeric(value) Then Exit Function
    If CDbl(value) < 0 Or CDbl(value) <> Fix(CDbl(value)) Then Exit Function
    If CDbl(value) > 2147483647# Then Exit Function

    resultValue = CLng(value)
    TryGetNonNegativeLongV28 = True
End Function

Private Function IsPositiveNumberV28(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Or Not IsNumeric(value) Then Exit Function
    IsPositiveNumberV28 = (CDbl(value) > 0)
End Function

Private Function IsNonNegativeNumberV28(ByVal value As Variant) As Boolean
    If IsError(value) Or IsEmpty(value) Or Not IsNumeric(value) Then Exit Function
    IsNonNegativeNumberV28 = (CDbl(value) >= 0)
End Function
