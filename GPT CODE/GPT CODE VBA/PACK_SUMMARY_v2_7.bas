Option Explicit


Function PACK_SUMMARY_v2_7( _
    ResultRange As Range, _
    SourceLengthRange As Range, _
    SourceQtyRange As Range)


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



    '=========================
    ' PACK_MULTI Mapping
    '=========================

    Const ColTarget As Long = 2

    Const ColUsed As Long = 45
    Const ColGap As Long = 47
    Const ColGapPercent As Long = 48

    Const ColItemStart As Long = 3
    Const ColItemEnd As Long = 42



    '=========================
    ' Dictionary
    '=========================

    Dim TargetDict As Object
    Dim TargetWasteDict As Object
    Dim ItemDict As Object
    Dim SourceDict As Object


    Set TargetDict = CreateObject("Scripting.Dictionary")
    Set TargetWasteDict = CreateObject("Scripting.Dictionary")
    Set ItemDict = CreateObject("Scripting.Dictionary")
    Set SourceDict = CreateObject("Scripting.Dictionary")



    '=========================
    ' Summary Variable
    '=========================

    Dim TotalTarget As Double
    Dim TotalUsed As Double
    Dim TotalGap As Double
    Dim RunningTotal As Double
    Dim StockUse As Double
    Dim GapPercentTotal As Double



    '=========================
    ' Read PACK Result
    '=========================

    For i = 1 To UBound(Data, 1)


        If Not IsError(Data(i, 1)) Then


            If IsNumeric(Data(i, 1)) Then


                If IsNumeric(Data(i, ColGapPercent)) Then


                    If Round(CDbl(Data(i, ColGapPercent)), 2) < 100 Then



                        '-------------------------
                        ' Summary
                        '-------------------------

                        If IsNumeric(Data(i, ColTarget)) Then

                            TotalTarget = TotalTarget + _
                                          CDbl(Data(i, ColTarget))

                        End If



                        If IsNumeric(Data(i, ColUsed)) Then

                            TotalUsed = TotalUsed + _
                                        CDbl(Data(i, ColUsed))

                        End If



                        If IsNumeric(Data(i, ColGap)) Then

                            TotalGap = TotalGap + _
                                       CDbl(Data(i, ColGap))

                        End If



                        '-------------------------
                        ' Target Usage
                        '-------------------------

                        If IsNumeric(Data(i, ColTarget)) Then


                            TargetKey = _
                                CDbl(Data(i, ColTarget))


                            If TargetDict.Exists(TargetKey) Then

                                TargetDict(TargetKey) = _
                                    TargetDict(TargetKey) + 1

                            Else

                                TargetDict.Add TargetKey, 1

                            End If



                            '-------------------------
                            ' Target Waste
                            '-------------------------

                            If Not TargetWasteDict.Exists(TargetKey) Then

                                TargetWasteDict.Add TargetKey, 0#

                            End If


                            If IsNumeric(Data(i, ColGap)) Then

                                GapValue = _
                                    CDbl(Data(i, ColGap))

                                TargetWasteDict(TargetKey) = _
                                    TargetWasteDict(TargetKey) + _
                                    GapValue

                            End If


                        End If



                        '-------------------------
                        ' Item 1 - Item 40
                        '-------------------------

                        For k = ColItemStart To ColItemEnd


                            If IsNumeric(Data(i, k)) Then


                                If CDbl(Data(i, k)) > 0 Then


                                    If ItemDict.Exists(CDbl(Data(i, k))) Then

                                        ItemDict(CDbl(Data(i, k))) = _
                                            ItemDict(CDbl(Data(i, k))) + 1

                                    Else

                                        ItemDict.Add _
                                            CDbl(Data(i, k)), 1

                                    End If


                                End If


                            End If


                        Next k



                    End If


                End If


            End If


        End If


    Next i



    '=========================
    ' Source List
    '=========================

    For i = 1 To SourceLengthRange.Rows.Count


        If IsNumeric(SourceLengthRange.Cells(i, 1).Value) And _
           IsNumeric(SourceQtyRange.Cells(i, 1).Value) Then


            SourceLength = _
                CDbl(SourceLengthRange.Cells(i, 1).Value)

            SourceQty = _
                CDbl(SourceQtyRange.Cells(i, 1).Value)



            If SourceDict.Exists(SourceLength) Then

                SourceDict(SourceLength) = _
                    SourceDict(SourceLength) + _
                    SourceQty

            Else

                SourceDict.Add _
                    SourceLength, _
                    SourceQty

            End If



            RunningTotal = RunningTotal + _
                           (SourceLength * SourceQty)


        End If


    Next i



    '=========================
    ' Gap Percent
    '=========================

    If TotalTarget <> 0 Then

        GapPercentTotal = _
            Round((TotalGap / TotalTarget) * 100, 2)

    Else

        GapPercentTotal = 0

    End If



    '=========================
    ' Calculate Stock Use
    '=========================

    For Each Key In TargetDict

        StockUse = StockUse + _
                   (CDbl(Key) * TargetDict(Key))

    Next Key



    '=========================
    ' Output
    '=========================

    Dim result() As Variant
    Dim RowCount As Long


    RowCount = _
        20 + TargetDict.Count + SourceDict.Count


    ReDim result( _
        1 To RowCount, _
        1 To 5)


    For i = 1 To RowCount

        For k = 1 To 5

            result(i, k) = ""

        Next k

    Next i



    '=========================
    ' Summary Report
    '=========================

    result(1, 1) = "SUMMARY REPORT"


    result(2, 1) = "Target Total"
    result(2, 2) = ZeroBlank(TotalTarget)


    result(3, 1) = "Used Total"
    result(3, 2) = ZeroBlank(TotalUsed)


    result(4, 1) = "Running Total"
    result(4, 2) = ZeroBlank(RunningTotal)


    result(5, 1) = "Stock Use"
    result(5, 2) = ZeroBlank(StockUse)


    result(6, 1) = "Gap Total"
    result(6, 2) = ZeroBlank(TotalGap)


    result(7, 1) = "Gap Total %"
    result(7, 2) = ZeroBlank(GapPercentTotal)



    '=========================
    ' Target Used List
    '=========================

    result(9, 1) = "Target used list"


    result(10, 1) = "Target"
    result(10, 2) = "Used Qty"
    result(10, 3) = "Total Length"
    result(10, 4) = "Total Waste"
    result(10, 5) = "Total Waste %"


    j = 11


    For Each Key In TargetDict


        result(j, 1) = Key


        result(j, 2) = _
            ZeroBlank(TargetDict(Key))


        result(j, 3) = _
            ZeroBlank( _
                CDbl(Key) * TargetDict(Key) _
            )


        If TargetWasteDict.Exists(Key) Then

            result(j, 4) = _
                ZeroBlank(TargetWasteDict(Key))

            If (CDbl(Key) * TargetDict(Key)) <> 0 Then

                result(j, 5) = _
                    ZeroBlank( _
                        Round( _
                            (TargetWasteDict(Key) / _
                                (CDbl(Key) * TargetDict(Key))) * 100, _
                            2 _
                        ) _
                    )

            Else

                result(j, 5) = ""

            End If

        Else

            result(j, 4) = ""
            result(j, 5) = ""

        End If


        j = j + 1


    Next Key



    '=========================
    ' Item Compare
    '=========================

    j = j + 2


    result(j, 1) = "Item used list"


    j = j + 1


    result(j, 1) = "Length"
    result(j, 2) = "Source Qty"
    result(j, 3) = "Used Qty"
    result(j, 4) = "Remaining"


    j = j + 1


    For Each Key In SourceDict


        result(j, 1) = Key


        result(j, 2) = _
            ZeroBlank(SourceDict(Key))


        If ItemDict.Exists(Key) Then

            result(j, 3) = _
                ZeroBlank(ItemDict(Key))

        Else

            result(j, 3) = ""

        End If


        result(j, 4) = _
            ZeroBlank( _
                SourceDict(Key) - _
                Val(result(j, 3)) _
            )


        j = j + 1


    Next Key



    '=========================
    ' Return Result
    '=========================

    PACK_SUMMARY_v2_7 = result


End Function



'=========================
' Zero To Blank
'=========================

Private Function ZeroBlank(ByVal x As Double)


    If x = 0 Then

        ZeroBlank = ""

    Else

        ZeroBlank = x

    End If


End Function


