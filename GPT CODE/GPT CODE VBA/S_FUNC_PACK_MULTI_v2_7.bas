Attribute VB_Name = "S_FUNC_PACK_MULTI_v2_7"
Option Explicit


Function PACK_MULTI_v2_7( _
    ValueRange As Range, _
    QtyRange As Range, _
    targetRange As Range, _
    TargetQtyRange As Range, _
    TargetWasteRange As Range, _
    Optional Allowance As Double = 5)


Dim i As Long
Dim j As Long
Dim idx As Long
Dim temp As Double



'=================================
' Expand Material
'=================================

Dim Items() As Double
Dim ItemUsed() As Boolean

Dim itemCount As Long



For i = 1 To ValueRange.Rows.Count

    itemCount = itemCount + CLng(QtyRange.Cells(i, 1).Value)

Next i



If itemCount = 0 Then Exit Function



ReDim Items(1 To itemCount)
ReDim ItemUsed(1 To itemCount)



idx = 1



For i = 1 To ValueRange.Rows.Count


    For j = 1 To CLng(QtyRange.Cells(i, 1).Value)


        Items(idx) = CDbl(ValueRange.Cells(i, 1).Value)


        idx = idx + 1


    Next j


Next i





'=================================
' Sort Material Descending
'=================================

For i = 1 To itemCount - 1

    For j = i + 1 To itemCount


        If Items(i) < Items(j) Then


            temp = Items(i)

            Items(i) = Items(j)

            Items(j) = temp


        End If


    Next j

Next i





'=================================
' Expand Stock List
' Stock + Waste ??????
'=================================

Dim StockList() As Double
Dim WasteList() As Double

Dim StockCount As Long



For i = 1 To targetRange.Rows.Count


    StockCount = StockCount + _
                 CLng(TargetQtyRange.Cells(i, 1).Value)


Next i



If StockCount = 0 Then Exit Function



ReDim StockList(1 To StockCount)
ReDim WasteList(1 To StockCount)



idx = 1



For i = 1 To targetRange.Rows.Count


    For j = 1 To CLng(TargetQtyRange.Cells(i, 1).Value)



        StockList(idx) = CDbl(targetRange.Cells(i, 1).Value)


        WasteList(idx) = CDbl(TargetWasteRange.Cells(i, 1).Value)



        idx = idx + 1



    Next j


Next i





'=================================
' Create Group Storage
'=================================

Dim Groups() As Collection

Dim GroupStock() As Double

Dim GroupWaste() As Double



ReDim Groups(1 To StockCount)

ReDim GroupStock(1 To StockCount)

ReDim GroupWaste(1 To StockCount)



For i = 1 To StockCount


    Set Groups(i) = New Collection


    GroupStock(i) = StockList(i)

    GroupWaste(i) = WasteList(i)


Next i





'=================================
' Packing Engine
'=================================

Dim StockIndex As Long

Dim BestCombo As Collection

Dim BestGap As Double



For StockIndex = 1 To StockCount



    Set BestCombo = New Collection


    BestGap = 999999999





    Call FindCombo_v26( _
        Items, _
        ItemUsed, _
        itemCount, _
        GroupStock(StockIndex), _
        GroupWaste(StockIndex), _
        Allowance, _
        1, _
        New Collection, _
        0, _
        BestCombo, _
        BestGap)





    If BestCombo.Count > 0 Then



        Dim x As Variant



        For Each x In BestCombo


            Groups(StockIndex).Add Items(x)


            ItemUsed(x) = True


        Next x



    End If



Next StockIndex

'=================================
' Output
'=================================

Dim MaxItem As Long

MaxItem = 40


Dim Result()

Dim TotalRow As Long



TotalRow = StockCount + 2



ReDim Result( _
    1 To TotalRow, _
    1 To MaxItem + 8)


For i = 1 To TotalRow

    For j = 1 To MaxItem + 8

        Result(i, j) = ""

    Next j

Next i





Result(1, 1) = "Group"

Result(1, 2) = "Stock"



For i = 1 To MaxItem

    Result(1, i + 2) = "Item" & i

Next i



Result(1, MaxItem + 3) = "Count"

Result(1, MaxItem + 4) = "RawSum"

Result(1, MaxItem + 5) = "Used"

Result(1, MaxItem + 6) = "Allowed Waste"

Result(1, MaxItem + 7) = "Gap"

Result(1, MaxItem + 8) = "Gap %"





Dim RawValue As Double

Dim UsedValue As Double

Dim GapValue As Double





For i = 1 To StockCount



    Result(i + 1, 1) = i


    Result(i + 1, 2) = GroupStock(i)





    For j = 1 To Groups(i).Count


        Result(i + 1, j + 2) = Groups(i)(j)


    Next j





    RawValue = CollectionSum_v26(Groups(i))


    UsedValue = RawValue + _
                Groups(i).Count * Allowance



    GapValue = GroupStock(i) - RawValue





    Result(i + 1, MaxItem + 3) = Groups(i).Count

    Result(i + 1, MaxItem + 4) = RawValue

    Result(i + 1, MaxItem + 5) = UsedValue

    Result(i + 1, MaxItem + 6) = GroupWaste(i)

    Result(i + 1, MaxItem + 7) = GapValue



    If GroupStock(i) <> 0 Then

        Result(i + 1, MaxItem + 8) = _
            Round((GapValue / GroupStock(i)) * 100, 2)

    Else

        Result(i + 1, MaxItem + 8) = ""

    End If



Next i





'=================================
' UNPACK
'=================================

Dim UnpackRow As Long

Dim c As Long



UnpackRow = StockCount + 2


Result(UnpackRow, 1) = "UNPACK"


c = 1



For i = 1 To itemCount


    If ItemUsed(i) = False Then


        Result(UnpackRow, c + 2) = Items(i)


        c = c + 1


    End If


Next i





PACK_MULTI_v2_7 = Result



End Function




'=================================
' Find Combination v2_6
'=================================

Private Sub FindCombo_v26( _
    Items() As Double, _
    ItemUsed() As Boolean, _
    itemCount As Long, _
    Stock As Double, _
    Waste As Double, _
    Allowance As Double, _
    StartIndex As Long, _
    Current As Collection, _
    CurrentSum As Double, _
    Best As Collection, _
    ByRef BestGap As Double)



Dim i As Long

Dim NewSum As Double

Dim UsedValue As Double

Dim Gap As Double




For i = StartIndex To itemCount



    If ItemUsed(i) = False Then



        NewSum = CurrentSum + Items(i)



        UsedValue = NewSum + _
                    ((Current.Count + 1) * Allowance)



        '=========================
        ' Capacity Check
        '=========================

        If UsedValue <= Stock Then



            Current.Add i



            Gap = Stock - NewSum



            '=========================
            ' Waste Check
            ' ???????????
            '=========================

            If Gap <= Waste Then



                If Gap < BestGap Then


                    BestGap = Gap


                    Set Best = New Collection



                    Dim x As Variant


                    For Each x In Current


                        Best.Add x


                    Next x



                End If


            End If





            '=========================
            ' Search ???
            '=========================

            If Current.Count < 8 Then



                Call FindCombo_v26( _
                    Items, _
                    ItemUsed, _
                    itemCount, _
                    Stock, _
                    Waste, _
                    Allowance, _
                    i + 1, _
                    Current, _
                    NewSum, _
                    Best, _
                    BestGap)



            End If





            Current.Remove Current.Count



        End If



    End If



Next i



End Sub





'=================================
' Collection Sum
'=================================

Private Function CollectionSum_v26( _
    col As Collection) As Double


Dim x As Variant



For Each x In col


    CollectionSum_v26 = _
        CollectionSum_v26 + CDbl(x)


Next x



End Function



