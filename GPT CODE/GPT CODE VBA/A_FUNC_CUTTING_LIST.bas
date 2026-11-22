Attribute VB_Name = "A_FUNC_CUTTING_LIST"
Option Explicit

' Worksheet UDF (Excel with dynamic arrays):
' =CUTTING_LIST(DataRange,StockLength,Kerf,[TrimStart],[TrimEnd],
'               [MinReusable],[MixGroups])
' Example: =CUTTING_LIST(DATA!A1:U30,6000,3,10,10,300,TRUE)
'
' MATRIX INPUT, all lengths in mm:
'   First column = cut lengths. Remaining columns = piece quantities.
'   Row immediately above the first length = material codes.
'   Row above material codes, if present = group names (P17, P18, ...).
'   Blank group cells inherit the group to the left, including merged headers.
'   A one-header matrix is supported: groups are then empty.
'   Include all headers INSIDE DataRange. No title, subtotal or footer rows.
'   Empty demand = summary and section headers only. Blank/zero quantities ignored.
'   Numeric text is accepted; negative/fractional quantities are rejected.
'   Material identity is the entire code cell (case-insensitive).
'
' OUTPUT: a variable-width report inspired by PACK_SUMMARY_v2_7:
' SUMMARY REPORT, Target used list, Item used list, CUTTING PLAN.
' Summary quantities/lengths and item Remaining display zero as blank.
' CUTTING PLAN has one row per stock bar:
' Material, Group, Bar, Stock (mm), Item1 ... ItemN, Group cuts, Pieces,
' Cut total (mm), Kerf loss (mm), Trim loss (mm), Remainder (mm),
' Used (%), Remnant. Percentages are numbers from 0 to 100 (not fractions).
' Bar numbers restart for each material/group pool.
' Each Item is one numeric cut length, including repeated lengths.
' N = most pieces in one bar across the chosen plan (minimum 1).
' Unused Item cells are blank. Group is MIXED only for a mixed-group bar.
' Group cuts retains each group/length/quantity even when MixGroups = TRUE.
'
' METHOD: try best-fit in decreasing and alternating long/short order,
' then choose fewer bars. This is not a proof of optimality.
' Each piece consumes Length + Kerf, INCLUDING the last piece of a bar.
' End trims are total allowances, including any end-trim saw loss.
' Stock = cuts + piece kerfs + end trims + remainder (within rounding).
' MinReusable only classifies remainder; it does not affect packing.
' No stock inventory limit or remnant reuse is assumed in this version.
' No cells are written and no application settings are changed by the UDF.
'
' ERRORS: #REF! = multi-area input; #VALUE! = invalid arguments/matrix;
' #NUM! = a piece cannot fit, arithmetic/resource/output limits exceeded.
' Limits: 2,000,000 source/result cells, 20,000 pieces, 20,000,000 fit checks,
'         32,767 characters per output cell. No partial plans are returned.

Private Const CL_MAX_CELLS As Long = 2000000
Private Const CL_MAX_PIECES As Long = 20000
Private Const CL_MAX_CHECKS As Long = 20000000
Private Const CL_TARGET_COLUMNS As Long = 12
Private Const CL_PLAN_FIXED_COLUMNS As Long = 12
Private Const CL_MAX_RESULT_CELLS As Long = 2000000

Private Type CLBar
    Remaining As Double
    CutTotal As Double
    PieceCount As Long
    Cuts As Object
    GroupCuts As Object
    Items As Collection
End Type

Public Function CUTTING_LIST( _
    ByVal DataRange As Range, _
    ByVal StockLength As Double, _
    ByVal Kerf As Double, _
    Optional ByVal TrimStart As Double = 0, _
    Optional ByVal TrimEnd As Double = 0, _
    Optional ByVal MinReusable As Double = 0, _
    Optional ByVal MixGroups As Boolean = False _
) As Variant

    Dim data As Variant
    Dim rowLengths() As Double, materials() As String, groups() As String
    Dim pools As Object, records As Collection, outputRows As Collection
    Dim demand As Object, targetRows As Collection
    Dim descendingPlan As Collection, alternatePlan As Collection, chosenPlan As Collection
    Dim descendingUsed As Object, alternateUsed As Object, chosenUsed As Object
    Dim row As Long, col As Long, firstData As Long, materialRow As Long
    Dim rowCount As Long, colCount As Long, totalPieces As Long
    Dim qty As Double, length As Double, usable As Double, tolerance As Double
    Dim currentGroup As String, poolKey As String, key As Variant, demandKey As Variant
    Dim record As Variant, outputRow As Variant, fitChecks As Long, requiredItem As Variant
    Dim failureCode As Long

    On Error GoTo UnexpectedError
    failureCode = xlErrValue
    CUTTING_LIST = CVErr(failureCode)
    If DataRange Is Nothing Then Exit Function
    If DataRange.Areas.Count <> 1 Then
        CUTTING_LIST = CVErr(xlErrRef)
        Exit Function
    End If
    If StockLength <= 0 Or Kerf < 0 Or TrimStart < 0 Or TrimEnd < 0 _
        Or MinReusable < 0 Then Exit Function
    If TrimStart >= StockLength Then Exit Function
    If TrimEnd >= StockLength - TrimStart Then Exit Function
    usable = StockLength - TrimStart - TrimEnd
    tolerance = 0.0000000001 * StockLength
    If tolerance > 0.000001 Then tolerance = 0.000001
    If Kerf >= usable Then Exit Function
    If DataRange.CountLarge > CL_MAX_CELLS Then
        CUTTING_LIST = CVErr(xlErrNum)
        Exit Function
    End If
    rowCount = DataRange.Rows.Count
    colCount = DataRange.Columns.Count
    If rowCount < 2 Or colCount < 2 Then Exit Function
    data = DataRange.Value2

    'The first numeric row label identifies the body, not fixed row numbers.
    For row = 1 To rowCount
        If IsError(data(row, 1)) Then Exit Function
        If CLNumber(data(row, 1), length) Then
            firstData = row
            Exit For
        End If
    Next row
    If firstData < 2 Then Exit Function
    materialRow = firstData - 1
    ReDim rowLengths(firstData To rowCount)
    ReDim materials(2 To colCount)
    ReDim groups(2 To colCount)

    For col = 2 To colCount
        If IsError(data(materialRow, col)) Then Exit Function
        If VarType(data(materialRow, col)) = vbBoolean Then Exit Function
        materials(col) = Trim$(CStr(data(materialRow, col)))
        If materialRow >= 2 Then
            If IsError(data(materialRow - 1, col)) Then Exit Function
            If VarType(data(materialRow - 1, col)) = vbBoolean Then Exit Function
            If Not CLBlank(data(materialRow - 1, col)) Then
                currentGroup = Trim$(CStr(data(materialRow - 1, col)))
            End If
            groups(col) = currentGroup
        End If
    Next col

    'Validate all body labels, including rows with no demand.
    For row = firstData To rowCount
        If Not CLBlank(data(row, 1)) Then
            If Not CLNumber(data(row, 1), length) Then Exit Function
            If length <= 0 Then Exit Function
            rowLengths(row) = length
        End If
    Next row

    Set pools = CLDictionary()
    Set demand = CLDictionary()
    Set targetRows = New Collection
    Set outputRows = New Collection
    For col = 2 To colCount
        For row = firstData To rowCount
            If Not CLBlank(data(row, col)) Then
                If Not CLNumber(data(row, col), qty) Then Exit Function
                If qty < 0 Or qty <> Fix(qty) Then Exit Function
                If rowLengths(row) = 0 Then Exit Function
                If qty > 0 Then
                    If Len(materials(col)) = 0 Then Exit Function
                    If materialRow >= 2 And Len(groups(col)) = 0 Then Exit Function
                    failureCode = xlErrNum
                    If qty > CL_MAX_PIECES - totalPieces Then GoTo InvalidResult
                    totalPieces = totalPieces + CLng(qty)
                    length = rowLengths(row)
                    If length > usable Then
                        If length - usable > tolerance Then GoTo InvalidResult
                    End If
                    If Kerf > usable - length + tolerance Then GoTo InvalidResult
                    failureCode = xlErrValue
                    poolKey = CLToken(materials(col))
                    If Not MixGroups Then poolKey = poolKey & CLToken(groups(col))
                    If Not pools.Exists(poolKey) Then
                        Set records = New Collection
                        pools.Add poolKey, records
                    End If
                    Set records = pools(poolKey)
                    records.Add Array(length, CLng(qty), groups(col), materials(col))
                    demandKey = CLDemandKey(materials(col), groups(col), length)
                    If Not demand.Exists(demandKey) Then
                        demand.Add demandKey, Array(materials(col), groups(col), length, 0&, 0&)
                    End If
                    requiredItem = demand(demandKey)
                    requiredItem(3) = CLng(requiredItem(3)) + CLng(qty)
                    demand(demandKey) = requiredItem
                End If
            End If
        Next row
    Next col

    For Each key In pools.Keys
        Set records = pools(key)
        Set descendingPlan = New Collection
        Set alternatePlan = New Collection
        Set descendingUsed = CLDictionary()
        Set alternateUsed = CLDictionary()
        If Not CLPack(records, StockLength, Kerf, TrimStart + TrimEnd, _
            MinReusable, tolerance, descendingPlan, fitChecks, False, descendingUsed) Then
            failureCode = xlErrNum
            GoTo InvalidResult
        End If
        If Not CLPack(records, StockLength, Kerf, TrimStart + TrimEnd, _
            MinReusable, tolerance, alternatePlan, fitChecks, True, alternateUsed) Then
            failureCode = xlErrNum
            GoTo InvalidResult
        End If
        Set chosenPlan = descendingPlan
        Set chosenUsed = descendingUsed
        If alternatePlan.Count < descendingPlan.Count Then
            Set chosenPlan = alternatePlan
            Set chosenUsed = alternateUsed
        End If
        For Each outputRow In chosenPlan
            outputRows.Add outputRow
        Next outputRow
        For Each demandKey In chosenUsed.Keys
            failureCode = xlErrNum
            If Not demand.Exists(demandKey) Then GoTo InvalidResult
            requiredItem = demand(demandKey)
            requiredItem(4) = CLng(requiredItem(4)) + CLng(chosenUsed(demandKey))
            demand(demandKey) = requiredItem
        Next demandKey
        targetRows.Add CLTargetRow(records, chosenPlan)
    Next key

    'Do not return a report that conceals a missing/extra piece.
    failureCode = xlErrNum
    For Each demandKey In demand.Keys
        requiredItem = demand(demandKey)
        If CLng(requiredItem(3)) <> CLng(requiredItem(4)) Then GoTo InvalidResult
    Next demandKey
    CUTTING_LIST = CLReport(outputRows, targetRows, demand)
    Exit Function

InvalidResult:
    CUTTING_LIST = CVErr(failureCode)
    Exit Function
UnexpectedError:
    If Err.Number = 6 Or Err.Number = 7 Or Err.Number = 14 Then
        failureCode = xlErrNum
    End If
    CUTTING_LIST = CVErr(failureCode)
End Function

Private Function CLPack(ByVal records As Collection, ByVal stock As Double, _
    ByVal kerfSize As Double, ByVal trimLoss As Double, _
    ByVal minReusable As Double, ByVal tolerance As Double, _
    ByVal outputRows As Collection, ByRef fitChecks As Long, _
    ByVal alternate As Boolean, ByVal usedDemand As Object) As Boolean

    Dim lengths() As Double, groupNames() As String, bars() As CLBar
    Dim record As Variant, cut As Variant, detail As Variant
    Dim pieceCount As Long, index As Long, i As Long, j As Long
    Dim barCount As Long, chosen As Long, q As Long, pieceIndex As Long
    Dim required As Double, remaining As Double, bestSpace As Double
    Dim cutKey As String, detailKey As String, material As String
    Dim cutsText As String, groupsText As String, remnant As String, key As Variant
    Dim itemValues() As Double, itemRecord As Variant, groupLabel As String

    For Each record In records
        pieceCount = pieceCount + CLng(record(1))
    Next record
    ReDim lengths(1 To pieceCount)
    ReDim groupNames(1 To pieceCount)
    ReDim bars(1 To pieceCount)
    record = records(1)
    material = CStr(record(3))
    For Each record In records
        For q = 1 To CLng(record(1))
            index = index + 1
            lengths(index) = CDbl(record(0))
            groupNames(index) = CStr(record(2))
        Next q
    Next record
    CLSort lengths, groupNames, 1, pieceCount

    For i = 1 To pieceCount
        pieceIndex = i
        If alternate Then
            If i Mod 2 = 1 Then
                pieceIndex = (i + 1) \ 2
            Else
                pieceIndex = pieceCount - i \ 2 + 1
            End If
        End If
        required = lengths(pieceIndex) + kerfSize
        chosen = 0
        bestSpace = stock
        For j = 1 To barCount
            fitChecks = fitChecks + 1
            If fitChecks > CL_MAX_CHECKS Then Exit Function
            remaining = bars(j).Remaining - required
            If remaining >= -tolerance Then
                If remaining < bestSpace Then
                    chosen = j
                    bestSpace = remaining
                    If remaining <= tolerance Then Exit For
                End If
            End If
        Next j
        If chosen = 0 Then
            barCount = barCount + 1
            chosen = barCount
            bars(chosen).Remaining = stock - trimLoss
            Set bars(chosen).Cuts = CLDictionary()
            Set bars(chosen).GroupCuts = CLDictionary()
            Set bars(chosen).Items = New Collection
        End If
        With bars(chosen)
            .Remaining = .Remaining - required
            If .Remaining < -tolerance Then Exit Function
            'Keep unrounded residuals during packing, to avoid accumulating
            'tolerance and admitting too many tiny pieces into the same bar.
            .CutTotal = .CutTotal + lengths(pieceIndex)
            .PieceCount = .PieceCount + 1
            .Items.Add Array(lengths(pieceIndex), groupNames(pieceIndex))
            cutKey = CStr(lengths(pieceIndex))
            If .Cuts.Exists(cutKey) Then
                cut = .Cuts(cutKey)
                cut(1) = CLng(cut(1)) + 1
                .Cuts(cutKey) = cut
            Else
                .Cuts.Add cutKey, Array(lengths(pieceIndex), 1&)
            End If
            detailKey = CLToken(groupNames(pieceIndex)) & CLToken(cutKey)
            If .GroupCuts.Exists(detailKey) Then
                detail = .GroupCuts(detailKey)
                detail(2) = CLng(detail(2)) + 1
                .GroupCuts(detailKey) = detail
            Else
                .GroupCuts.Add detailKey, Array(groupNames(pieceIndex), lengths(pieceIndex), 1&)
            End If
        End With
    Next i

    For j = 1 To barCount
        cutsText = CLDescribe(bars(j).Cuts, False)
        groupsText = CLDescribe(bars(j).GroupCuts, True)
        If Len(cutsText) > 32767 Or Len(groupsText) > 32767 Then Exit Function
        remaining = bars(j).Remaining
        If Abs(remaining) <= tolerance Then remaining = 0
        If remaining = 0 Then
            remnant = "NONE"
        ElseIf remaining >= minReusable Then
            remnant = "REUSABLE"
        Else
            remnant = "SCRAP"
        End If
        ReDim itemValues(1 To bars(j).PieceCount)
        itemRecord = bars(j).Items(1)
        groupLabel = CStr(itemRecord(1))
        For i = 1 To bars(j).PieceCount
            itemRecord = bars(j).Items(i)
            itemValues(i) = CDbl(itemRecord(0))
            If StrComp(groupLabel, CStr(itemRecord(1)), vbTextCompare) <> 0 Then
                groupLabel = "MIXED"
            End If
        Next i
        outputRows.Add Array(material, j, cutsText, groupsText, _
            bars(j).PieceCount, stock, bars(j).CutTotal, _
            bars(j).PieceCount * kerfSize, trimLoss, remaining, _
            100 * (bars(j).CutTotal / stock), remnant, itemValues, groupLabel)
        For Each key In bars(j).GroupCuts.Keys
            detail = bars(j).GroupCuts(key)
            detailKey = CLDemandKey(material, CStr(detail(0)), CDbl(detail(1)))
            If Not usedDemand.Exists(detailKey) Then usedDemand.Add detailKey, 0&
            usedDemand(detailKey) = CLng(usedDemand(detailKey)) + CLng(detail(2))
        Next key
    Next j
    CLPack = True
End Function

Private Function CLTargetRow(ByVal records As Collection, ByVal plan As Collection) As Variant
    Dim first As Variant, firstBar As Variant, record As Variant, bar As Variant
    Dim groupLabel As String, stockTotal As Double, cutTotal As Double
    Dim kerfTotal As Double, trimTotal As Double, gapTotal As Double
    Dim reusable As Double, scrap As Double
    first = records(1)
    firstBar = plan(1)
    groupLabel = CStr(first(2))
    For Each record In records
        If StrComp(groupLabel, CStr(record(2)), vbTextCompare) <> 0 Then
            groupLabel = "MIXED"
            Exit For
        End If
    Next record
    For Each bar In plan
        stockTotal = stockTotal + CDbl(bar(5))
        cutTotal = cutTotal + CDbl(bar(6))
        kerfTotal = kerfTotal + CDbl(bar(7))
        trimTotal = trimTotal + CDbl(bar(8))
        gapTotal = gapTotal + CDbl(bar(9))
        If CStr(bar(11)) = "REUSABLE" Then reusable = reusable + CDbl(bar(9))
        If CStr(bar(11)) = "SCRAP" Then scrap = scrap + CDbl(bar(9))
    Next bar
    CLTargetRow = Array(CStr(first(3)), groupLabel, CDbl(firstBar(5)), plan.Count, _
        stockTotal, cutTotal, CLZeroBlank(kerfTotal), CLZeroBlank(trimTotal), _
        CLZeroBlank(gapTotal), CLZeroBlank(Round(100 * (gapTotal / stockTotal), 2)), _
        CLZeroBlank(reusable), CLZeroBlank(scrap))
End Function

Private Function CLReport(ByVal plan As Collection, ByVal targets As Collection, _
    ByVal demand As Object) As Variant

    Dim result() As Variant, labels As Variant, values As Variant, headers As Variant
    Dim row As Long, col As Long, itemTitle As Long, planTitle As Long, rowCount As Long
    Dim entry As Variant, key As Variant, sourceQty As Long, usedQty As Long
    Dim stockTotal As Double, usedTotal As Double, requiredTotal As Double
    Dim kerfTotal As Double, trimTotal As Double, gapTotal As Double
    Dim reusable As Double, scrap As Double, gapPercent As Double
    Dim maxItems As Long, columnCount As Long, suffixColumn As Long
    Dim itemValues As Variant, itemIndex As Long

    maxItems = 1
    For Each entry In plan
        If CLng(entry(4)) > maxItems Then maxItems = CLng(entry(4))
    Next entry
    columnCount = CL_PLAN_FIXED_COLUMNS + maxItems
    suffixColumn = 5 + maxItems
    itemTitle = 19 + targets.Count
    planTitle = 22 + targets.Count + demand.Count
    rowCount = planTitle + 1 + plan.Count
    If Not CLFitsCaller(rowCount, columnCount) Then
        CLReport = CVErr(xlErrNum)
        Exit Function
    End If
    If CDbl(rowCount) * columnCount > CL_MAX_RESULT_CELLS Then
        CLReport = CVErr(xlErrNum)
        Exit Function
    End If
    ReDim result(1 To rowCount, 1 To columnCount)
    For row = 1 To rowCount
        For col = 1 To columnCount
            result(row, col) = ""
        Next col
    Next row
    For Each entry In plan
        stockTotal = stockTotal + CDbl(entry(5))
        usedTotal = usedTotal + CDbl(entry(6))
        usedQty = usedQty + CLng(entry(4))
        kerfTotal = kerfTotal + CDbl(entry(7))
        trimTotal = trimTotal + CDbl(entry(8))
        gapTotal = gapTotal + CDbl(entry(9))
        If CStr(entry(11)) = "REUSABLE" Then reusable = reusable + CDbl(entry(9))
        If CStr(entry(11)) = "SCRAP" Then scrap = scrap + CDbl(entry(9))
    Next entry
    For Each key In demand.Keys
        entry = demand(key)
        sourceQty = sourceQty + CLng(entry(3))
        requiredTotal = requiredTotal + CDbl(entry(2)) * CLng(entry(3))
    Next key
    If stockTotal > 0 Then gapPercent = Round(100 * (gapTotal / stockTotal), 2)
    result(1, 1) = "SUMMARY REPORT"
    labels = Array("Stock Total (mm)", "Used Total (mm)", "Required Total (mm)", _
        "Bars Used", "Source Qty", "Used Qty", "Remaining Qty", "Kerf Total (mm)", _
        "Trim Total (mm)", "Gap Total (mm)", "Gap Total (%)", _
        "Reusable Total (mm)", "Scrap Total (mm)")
    values = Array(stockTotal, usedTotal, requiredTotal, plan.Count, sourceQty, usedQty, _
        sourceQty - usedQty, kerfTotal, trimTotal, gapTotal, gapPercent, reusable, scrap)
    For row = 2 To 14
        result(row, 1) = labels(row - 2)
        result(row, 2) = CLZeroBlank(CDbl(values(row - 2)))
    Next row

    result(16, 1) = "Target used list"
    headers = Array("Material", "Group", "Target (mm)", "Used Qty", "Total Length (mm)", _
        "Used Length (mm)", "Kerf (mm)", "Trim (mm)", "Total Waste (mm)", _
        "Total Waste (%)", "Reusable (mm)", "Scrap (mm)")
    CLWriteHeaders result, 17, headers
    row = 18
    For Each entry In targets
        For col = 1 To CL_TARGET_COLUMNS
            result(row, col) = entry(col - 1)
        Next col
        row = row + 1
    Next entry

    result(itemTitle, 1) = "Item used list"
    headers = Array("Material", "Group", "Length (mm)", "Source Qty", "Used Qty", _
        "Remaining", "Source Length (mm)", "Used Length (mm)")
    CLWriteHeaders result, itemTitle + 1, headers
    row = itemTitle + 2
    For Each key In demand.Keys
        entry = demand(key)
        result(row, 1) = entry(0)
        result(row, 2) = entry(1)
        result(row, 3) = entry(2)
        result(row, 4) = CLZeroBlank(CDbl(entry(3)))
        result(row, 5) = CLZeroBlank(CDbl(entry(4)))
        result(row, 6) = CLZeroBlank(CDbl(entry(3)) - CDbl(entry(4)))
        result(row, 7) = CDbl(entry(2)) * CLng(entry(3))
        result(row, 8) = CDbl(entry(2)) * CLng(entry(4))
        row = row + 1
    Next key

    result(planTitle, 1) = "CUTTING PLAN"
    headers = Array("Material", "Group", "Bar", "Stock (mm)")
    CLWriteHeaders result, planTitle + 1, headers
    For itemIndex = 1 To maxItems
        result(planTitle + 1, 4 + itemIndex) = "Item" & itemIndex
    Next itemIndex
    headers = Array("Group cuts", "Pieces", "Cut total (mm)", "Kerf loss (mm)", _
        "Trim loss (mm)", "Remainder (mm)", "Used (%)", "Remnant")
    For col = 0 To UBound(headers)
        result(planTitle + 1, suffixColumn + col) = headers(col)
    Next col
    row = planTitle + 2
    For Each entry In plan
        result(row, 1) = entry(0)
        result(row, 2) = entry(13)
        result(row, 3) = entry(1)
        result(row, 4) = entry(5)
        itemValues = entry(12)
        For itemIndex = 1 To CLng(entry(4))
            result(row, 4 + itemIndex) = itemValues(itemIndex)
        Next itemIndex
        result(row, suffixColumn) = entry(3)
        result(row, suffixColumn + 1) = entry(4)
        For col = 6 To 11
            result(row, suffixColumn + col - 4) = entry(col)
        Next col
        row = row + 1
    Next entry
    CLReport = result
End Function

Private Sub CLWriteHeaders(ByRef result() As Variant, ByVal row As Long, ByVal headers As Variant)
    Dim col As Long
    For col = LBound(headers) To UBound(headers)
        result(row, col + 1) = headers(col)
    Next col
End Sub

Private Function CLZeroBlank(ByVal value As Double) As Variant
    If value = 0 Then
        CLZeroBlank = ""
    Else
        CLZeroBlank = value
    End If
End Function

Private Function CLDemandKey(ByVal material As String, ByVal group As String, _
    ByVal length As Double) As String
    CLDemandKey = CLToken(material) & CLToken(group) & CLToken(CStr(length))
End Function

Private Sub CLSort(ByRef lengths() As Double, ByRef names() As String, _
    ByVal low As Long, ByVal high As Long)

    Dim i As Long, j As Long, pivotLength As Double, pivotName As String
    Dim tempLength As Double, tempName As String
    i = low
    j = high
    pivotLength = lengths((low + high) \ 2)
    pivotName = names((low + high) \ 2)
    Do While i <= j
        Do While CLBefore(lengths(i), names(i), pivotLength, pivotName)
            i = i + 1
        Loop
        Do While CLBefore(pivotLength, pivotName, lengths(j), names(j))
            j = j - 1
        Loop
        If i <= j Then
            tempLength = lengths(i): lengths(i) = lengths(j): lengths(j) = tempLength
            tempName = names(i): names(i) = names(j): names(j) = tempName
            i = i + 1
            j = j - 1
        End If
    Loop
    If low < j Then CLSort lengths, names, low, j
    If i < high Then CLSort lengths, names, i, high
End Sub

Private Function CLBefore(ByVal a As Double, ByVal aName As String, _
    ByVal b As Double, ByVal bName As String) As Boolean
    If a <> b Then
        CLBefore = (a > b)
    Else
        CLBefore = (StrComp(aName, bName, vbTextCompare) < 0)
    End If
End Function

Private Function CLDescribe(ByVal dictionary As Object, _
    ByVal includeGroup As Boolean) As String

    Dim key As Variant, entry As Variant, text As String, item As String
    For Each key In dictionary.Keys
        entry = dictionary(key)
        If includeGroup Then
            item = CStr(entry(0))
            If Len(item) > 0 Then item = item & ": "
            item = item & CStr(entry(1)) & " x " & CStr(entry(2))
        Else
            item = CStr(entry(0)) & " x " & CStr(entry(1))
        End If
        If Len(text) > 0 Then text = text & " + "
        text = text & item
        If Len(text) > 32767 Then Exit For
    Next key
    CLDescribe = text
End Function

Private Function CLDictionary() As Object
    Set CLDictionary = CreateObject("Scripting.Dictionary")
    CLDictionary.CompareMode = vbTextCompare
End Function

Private Function CLToken(ByVal text As String) As String
    CLToken = CStr(Len(text)) & ":" & text
End Function

Private Function CLBlank(ByVal value As Variant) As Boolean
    If IsError(value) Then Exit Function
    If IsEmpty(value) Then
        CLBlank = True
    ElseIf VarType(value) = vbString Then
        CLBlank = (Len(Trim$(CStr(value))) = 0)
    End If
End Function

Private Function CLNumber(ByVal value As Variant, ByRef number As Double) As Boolean
    If IsError(value) Or IsEmpty(value) Then Exit Function
    If VarType(value) = vbBoolean Then Exit Function
    If Not IsNumeric(value) Then Exit Function
    number = CDbl(value)
    CLNumber = True
End Function

Private Function CLFitsCaller(ByVal resultRows As Long, ByVal resultColumns As Long) As Boolean
    Dim callerCell As Range
    CLFitsCaller = (resultRows <= 1048576 And resultColumns <= 16384)
    If Not CLFitsCaller Then Exit Function
    'Application.Caller is not a Range when called from VBA/tests.
    On Error GoTo NoWorksheetCaller
    If TypeName(Application.Caller) <> "Range" Then Exit Function
    Set callerCell = Application.Caller
    CLFitsCaller = (resultRows <= callerCell.Worksheet.Rows.Count - callerCell.Row + 1 _
        And resultColumns <= callerCell.Worksheet.Columns.Count - callerCell.Column + 1)
NoWorksheetCaller:
End Function
