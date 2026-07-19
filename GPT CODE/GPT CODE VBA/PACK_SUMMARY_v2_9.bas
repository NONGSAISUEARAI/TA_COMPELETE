Attribute VB_Name = "modPackSummary_v2_90"
Option Explicit

Function PACK_SUMMARY_v2_9( _
    ResultRange As Range, _
    SourceLengthRange As Range, _
    SourceQtyRange As Range, _
    Optional ItemListRowOffset As Long = 18)

    Dim Data As Variant

    Dim i As Long
    Dim j As Long
    Dim k As Long

    Dim Key As Variant

    Dim TargetKey As Double
    Dim SourceLength As Double
    Dim SourceQty As Double
    Dim GapValue As Double

    Data = ResultRange.Value

    Const ColTarget As Long = 2
    Const ColUsed As Long = 45
    Const ColGap As Long = 47
    Const ColGapPercent As Long = 48
    Const ColItemStart As Long = 3
    Const ColItemEnd As Long = 42

    Dim TargetDict As Object
    Dim TargetWasteDict As Object
    Dim ItemDict As Object
    Dim SourceDict As Object

    Set TargetDict = CreateObject("Scripting.Dictionary")
    Set TargetWasteDict = CreateObject("Scripting.Dictionary")
    Set ItemDict = CreateObject("Scripting.Dictionary")
    Set SourceDict = CreateObject("Scripting.Dictionary")

    Dim TotalTarget As Double
    Dim TotalUsed As Double
    Dim TotalGap As Double
    Dim RunningTotal As Double
    Dim StockUse As Double
    Dim GapPercentTotal As Double

    For i = 1 To UBound(Data, 1)
        If Not IsError(Data(i, 1)) Then
            If IsNumeric(Data(i, 1)) Then
                If IsNumeric(Data(i, ColGapPercent)) Then
                    If Round(CDbl(Data(i, ColGapPercent)), 2) < 100 Then
                        If IsNumeric(Data(i, ColTarget)) Then
                            TotalTarget = TotalTarget + CDbl(Data(i, ColTarget))
                        End If

                        If IsNumeric(Data(i, ColUsed)) Then
                            TotalUsed = TotalUsed + CDbl(Data(i, ColUsed))
                        End If

                        If IsNumeric(Data(i, ColGap)) Then
                            TotalGap = TotalGap + CDbl(Data(i, ColGap))
                        End If

                        If IsNumeric(Data(i, ColTarget)) Then
                            TargetKey = CDbl(Data(i, ColTarget))

                            If TargetDict.Exists(TargetKey) Then
                                TargetDict(TargetKey) = TargetDict(TargetKey) + 1
                            Else
                                TargetDict.Add TargetKey, 1
                            End If

                            If Not TargetWasteDict.Exists(TargetKey) Then
                                TargetWasteDict.Add TargetKey, 0#
                            End If

                            If IsNumeric(Data(i, ColGap)) Then
                                GapValue = CDbl(Data(i, ColGap))
                                TargetWasteDict(TargetKey) = TargetWasteDict(TargetKey) + GapValue
                            End If
                        End If

                        For k = ColItemStart To ColItemEnd
                            If IsNumeric(Data(i, k)) Then
                                If CDbl(Data(i, k)) > 0 Then
                                    If ItemDict.Exists(CDbl(Data(i, k))) Then
                                        ItemDict(CDbl(Data(i, k))) = ItemDict(CDbl(Data(i, k))) + 1
                                    Else
                                        ItemDict.Add CDbl(Data(i, k)), 1
                                    End If
                                End If
                            End If
                        Next k
                    End If
                End If
            End If
        End If
    Next i

    For i = 1 To SourceLengthRange.Rows.Count
        If IsNumeric(SourceLengthRange.Cells(i, 1).Value) And _
           IsNumeric(SourceQtyRange.Cells(i, 1).Value) Then

            SourceLength = CDbl(SourceLengthRange.Cells(i, 1).Value)
            SourceQty = CDbl(SourceQtyRange.Cells(i, 1).Value)

            If SourceDict.Exists(SourceLength) Then
                SourceDict(SourceLength) = SourceDict(SourceLength) + SourceQty
            Else
                SourceDict.Add SourceLength, SourceQty
            End If

            RunningTotal = RunningTotal + (SourceLength * SourceQty)
        End If
    Next i

    If TotalTarget <> 0 Then
        GapPercentTotal = Round((TotalGap / TotalTarget) * 100, 2)
    Else
        GapPercentTotal = 0
    End If

    For Each Key In TargetDict
        StockUse = StockUse + (CDbl(Key) * TargetDict(Key))
    Next Key

    ' At least one row is required so Item used list cannot overwrite
    ' the final row of Target used list.
    If ItemListRowOffset < 1 Then ItemListRowOffset = 1

    Dim Result() As Variant
    Dim RowCount As Long

    ' Includes the selected offset and keeps the original six trailing rows.
    RowCount = 17 + TargetDict.Count + SourceDict.Count + ItemListRowOffset

    ReDim Result(1 To RowCount, 1 To 5)

    For i = 1 To RowCount
        For k = 1 To 5
            Result(i, k) = ""
        Next k
    Next i

    Result(1, 1) = "SUMMARY REPORT"
    Result(2, 1) = "Target Total"
    Result(2, 2) = ZeroBlank(TotalTarget)
    Result(3, 1) = "Used Total"
    Result(3, 2) = ZeroBlank(TotalUsed)
    Result(4, 1) = "Running Total"
    Result(4, 2) = ZeroBlank(RunningTotal)
    Result(5, 1) = "Stock Use"
    Result(5, 2) = ZeroBlank(StockUse)
    Result(6, 1) = "Gap Total"
    Result(6, 2) = ZeroBlank(TotalGap)
    Result(7, 1) = "Gap Total %"
    Result(7, 2) = ZeroBlank(GapPercentTotal)

    Result(9, 1) = "Target used list"
    Result(10, 1) = "Target"
    Result(10, 2) = "Used Qty"
    Result(10, 3) = "Total Length"
    Result(10, 4) = "Total Waste"
    Result(10, 5) = "Total Waste %"

    j = 11

    For Each Key In TargetDict
        Result(j, 1) = Key
        Result(j, 2) = ZeroBlank(TargetDict(Key))
        Result(j, 3) = ZeroBlank(CDbl(Key) * TargetDict(Key))

        If TargetWasteDict.Exists(Key) Then
            Result(j, 4) = ZeroBlank(TargetWasteDict(Key))

            If (CDbl(Key) * TargetDict(Key)) <> 0 Then
                Result(j, 5) = _
                    ZeroBlank(Round((TargetWasteDict(Key) / _
                    (CDbl(Key) * TargetDict(Key))) * 100, 2))
            Else
                Result(j, 5) = ""
            End If
        Else
            Result(j, 4) = ""
            Result(j, 5) = ""
        End If

        j = j + 1
    Next Key

    ' j is one row below the final Target row. Subtract one so the offset
    ' is measured from that final Target row itself.
    j = j + ItemListRowOffset - 1

    Result(j, 1) = "Item used list"
    j = j + 1

    Result(j, 1) = "Length"
    Result(j, 2) = "Source Qty"
    Result(j, 3) = "Used Qty"
    Result(j, 4) = "Remaining"
    j = j + 1

    For Each Key In SourceDict
        Result(j, 1) = Key
        Result(j, 2) = ZeroBlank(SourceDict(Key))

        If ItemDict.Exists(Key) Then
            Result(j, 3) = ZeroBlank(ItemDict(Key))
        Else
            Result(j, 3) = ""
        End If

        Result(j, 4) = ZeroBlank(SourceDict(Key) - Val(Result(j, 3)))
        j = j + 1
    Next Key

    PACK_SUMMARY_v2_9 = Result

End Function

Private Function ZeroBlank(ByVal x As Double)
    If x = 0 Then
        ZeroBlank = ""
    Else
        ZeroBlank = x
    End If
End Function
