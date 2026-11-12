Attribute VB_Name = "A_FUNC_CountUnique_V6"
Option Explicit

' Syntax:
' =COUNTUNIQUE_V6(Heading,IncludeEmpty,Range1,Sort1,Range2,Sort2,...)
' At least two Range/Sort pairs are required. More pairs add header levels.
' Range1 supplies the vertical row labels; Range2 onwards supply headers.
'
' IncludeEmpty: 1 = all horizontal header combinations, including empty ones.
'               0 = only horizontal combinations present in valid source rows.
' Sort:         1 = ascending; 0 = first-seen order, independently per range.
' Heading:      use "" to omit the optional title row.
'
' Rows containing a blank, whitespace-only value or error in any range are
' skipped. Zero is a valid value. Unmatched counts are returned as "".
' Text grouping is case-insensitive; numeric and text values stay distinct.
' All ranges must be contiguous and contain the same number of cells.
' Rectangular ranges are read in row-major order, like Range.Cells(index).
'
' #VALUE! = invalid arguments; #REF! = incompatible ranges;
' #NUM! = the result exceeds worksheet dimensions or available array memory.
'
' ARGUMENT GUIDE (V6 order; different from V5):
'   1 Heading      Text in quotes, one heading cell, or "" for no title row.
'   2 IncludeEmpty 1 = complete horizontal header combinations;
'                  0 = only combinations found in valid source rows.
'   3 Range1       Vertical row labels, e.g. L3:L101.
'   4 Sort1        1 = ascending; 0 = first-seen order for Range1.
'   5 Range2       First horizontal header level, e.g. F3:F101.
'   6 Sort2        1 = ascending; 0 = first-seen order for Range2.
'   7 Range3       Optional next horizontal header level, e.g. G3:G101.
'   8 Sort3        Required whenever Range3 is supplied.
'   ...            Add more complete Range/Sort pairs in the same order.
' Minimum: six arguments (Heading, IncludeEmpty and two Range/Sort pairs).
' IncludeEmpty controls missing header COMBINATIONS, not blank source cells.
' Every key range must have the same cell count; omit source column headings.
'
' COPYABLE EXAMPLES:
' Two ranges, complete headers, ascending rows and first-seen headers:
' =COUNTUNIQUE_V6("SS",1,L3:L101,1,F3:F101,0)
' Three ranges, with a second horizontal header level:
' =COUNTUNIQUE_V6("SS",1,L3:L101,1,F3:F101,1,G3:G101,0)
' Four ranges, with a third horizontal header level:
' =COUNTUNIQUE_V6("SS",1,L3:L101,1,F3:F101,1,G3:G101,0,H3:H101,1)
' Only observed combinations, no title row:
' =COUNTUNIQUE_V6("",0,L3:L101,1,F3:F101,0,G3:G101,0)
' Heading from a single cell:
' =COUNTUNIQUE_V6(K1,1,L3:L101,1,F3:F101,0)
'
' TROUBLESHOOTING #VALUE! (error stays an Excel error, not help text):
' - Do not use V5 argument order: Heading and IncludeEmpty come FIRST.
' - Each range needs its own Sort; do not omit the last Sort argument.
' - IncludeEmpty and every Sort accept 0 or 1; 2, -1, 0.5 or "asc" are invalid.
' - Supply real ranges: L3:L101 is valid; "L3:L101" is a text string.
' - Supply at least TWO Range/Sort pairs, even if no title is wanted.
' - Heading may refer to one cell, not a multi-cell range or array.
' - A flag cell must contain 0 or 1, not a blank/error or multi-cell range.
' Wrong (missing Sort2):
' =COUNTUNIQUE_V6("SS",1,L3:L101,1,F3:F101)
' Correct:
' =COUNTUNIQUE_V6("SS",1,L3:L101,1,F3:F101,1)
'
' OTHER ERRORS:
' #REF!  Unequal cell counts or non-contiguous/multi-area ranges.
' #NUM!  Too many result rows/columns or numeric/array-memory overflow.
' #SPILL! Clear the output area; the formula returns a spilling table.
' #NAME? Check that this module is imported and macros/UDFs are available.
' Source blank/error values are skipped; they do not normally cause #VALUE!.
' Thai guide with worked input/output: COUNT_SUM_UNIQUE_V6_GUIDE_TH.md
Public Function COUNTUNIQUE_V6( _
    ByVal Heading As Variant, _
    ByVal IncludeEmpty As Variant, _
    ParamArray RangeSortPairs() As Variant) As Variant

    Dim sourceRanges() As Range
    Dim sourceData() As Variant
    Dim sourceWidths() As Long
    Dim sortFlags() As Long
    Dim valueDictionaries() As Object
    Dim valueLists() As Collection
    Dim dimensionValues() As Variant
    Dim dimensionRanks() As Variant
    Dim dimensionIds() As Variant
    Dim dimensionSizes() As Long
    Dim sourceValues() As Variant
    Dim sourceIds() As Long
    Dim horizontalIds() As Long
    Dim currentRanks() As Long
    Dim previousRanks() As Long
    Dim strides() As Long
    Dim sortedValues() As Variant
    Dim ranksById() As Long
    Dim idsByRank() As Long
    Dim tupleRanks() As Long
    Dim result() As Variant
    Dim observedColumns As Object
    Dim counts As Object
    Dim outputColumns As Object
    Dim callerRange As Range
    Dim gridSheet As Worksheet
    Dim headingValue As Variant
    Dim observedTuples As Variant
    Dim tupleIds As Variant
    Dim countKey As Variant
    Dim valueKey As String
    Dim columnKey As String
    Dim argumentCount As Long
    Dim firstArgument As Long
    Dim dimensionCount As Long
    Dim sourceCount As Long
    Dim includeEmptyFlag As Long
    Dim headingRows As Long
    Dim headerRows As Long
    Dim maximumRows As Long
    Dim maximumColumns As Long
    Dim dataColumnCount As Long
    Dim totalRows As Long
    Dim totalColumns As Long
    Dim outputRow As Long
    Dim outputColumn As Long
    Dim separatorPosition As Long
    Dim valueId As Long
    Dim rowId As Long
    Dim sourceIndex As Long
    Dim argumentIndex As Long
    Dim dimensionIndex As Long
    Dim valueIndex As Long
    Dim columnIndex As Long
    Dim i As Long
    Dim j As Long
    Dim validRow As Boolean
    Dim prefixChanged As Boolean

    On Error GoTo InvalidArguments
    COUNTUNIQUE_V6 = CVErr(xlErrValue)

    If Not TryGetCountUniqueV6Flag(IncludeEmpty, includeEmptyFlag) Then Exit Function

    If IsObject(Heading) Then
        If Not TypeOf Heading Is Range Then Exit Function
        If Heading Is Nothing Then Exit Function
        If Heading.Cells.CountLarge <> 1 Then Exit Function
        headingValue = Heading.Value2
    Else
        headingValue = Heading
    End If

    If IsError(headingValue) Then Exit Function
    If IsArray(headingValue) Then Exit Function
    If IsNull(headingValue) Then Exit Function
    If Len(CStr(headingValue)) > 0 Then headingRows = 1

    firstArgument = LBound(RangeSortPairs)
    argumentCount = UBound(RangeSortPairs) - firstArgument + 1
    If argumentCount < 4 Then Exit Function
    If argumentCount Mod 2 <> 0 Then Exit Function
    dimensionCount = argumentCount \ 2
    headerRows = dimensionCount - 1

    ReDim sourceRanges(1 To dimensionCount)
    ReDim sourceData(1 To dimensionCount)
    ReDim sourceWidths(1 To dimensionCount)
    ReDim sortFlags(1 To dimensionCount)
    ReDim valueDictionaries(1 To dimensionCount)
    ReDim valueLists(1 To dimensionCount)
    ReDim dimensionValues(1 To dimensionCount)
    ReDim dimensionRanks(1 To dimensionCount)
    ReDim dimensionIds(1 To dimensionCount)
    ReDim dimensionSizes(1 To dimensionCount)
    ReDim sourceValues(1 To dimensionCount)
    ReDim sourceIds(1 To dimensionCount)
    ReDim horizontalIds(2 To dimensionCount)

    For dimensionIndex = 1 To dimensionCount
        argumentIndex = firstArgument + (dimensionIndex - 1) * 2
        If Not IsObject(RangeSortPairs(argumentIndex)) Then Exit Function
        If Not TypeOf RangeSortPairs(argumentIndex) Is Range Then Exit Function
        Set sourceRanges(dimensionIndex) = RangeSortPairs(argumentIndex)
        If sourceRanges(dimensionIndex) Is Nothing Then Exit Function

        If Not TryGetCountUniqueV6Flag( _
            RangeSortPairs(argumentIndex + 1), sortFlags(dimensionIndex)) Then Exit Function

        If sourceRanges(dimensionIndex).Areas.Count <> 1 Then
            COUNTUNIQUE_V6 = CVErr(xlErrRef)
            Exit Function
        End If

        If sourceRanges(dimensionIndex).Cells.CountLarge > 2147483647# Then
            COUNTUNIQUE_V6 = CVErr(xlErrRef)
            Exit Function
        End If

        If dimensionIndex = 1 Then
            sourceCount = CLng(sourceRanges(dimensionIndex).Cells.CountLarge)
        ElseIf sourceRanges(dimensionIndex).Cells.CountLarge <> sourceCount Then
            COUNTUNIQUE_V6 = CVErr(xlErrRef)
            Exit Function
        End If
    Next dimensionIndex

    Set gridSheet = sourceRanges(1).Worksheet
    On Error Resume Next
    Set callerRange = Application.Caller
    On Error GoTo InvalidArguments
    If Not callerRange Is Nothing Then Set gridSheet = callerRange.Worksheet
    maximumRows = gridSheet.Rows.Count
    maximumColumns = gridSheet.Columns.Count

    Set observedColumns = CreateObject("Scripting.Dictionary")
    Set counts = CreateObject("Scripting.Dictionary")
    Set outputColumns = CreateObject("Scripting.Dictionary")

    For dimensionIndex = 1 To dimensionCount
        sourceData(dimensionIndex) = sourceRanges(dimensionIndex).Value2
        sourceWidths(dimensionIndex) = sourceRanges(dimensionIndex).Columns.Count
        Set valueDictionaries(dimensionIndex) = CreateObject("Scripting.Dictionary")
        valueDictionaries(dimensionIndex).CompareMode = vbTextCompare
        Set valueLists(dimensionIndex) = New Collection
    Next dimensionIndex

    For sourceIndex = 1 To sourceCount
        validRow = True
        For dimensionIndex = 1 To dimensionCount
            sourceValues(dimensionIndex) = CountUniqueV6SourceValue( _
                sourceData(dimensionIndex), sourceIndex, sourceWidths(dimensionIndex))
            If Not CountUniqueV6UsableValue(sourceValues(dimensionIndex)) Then
                validRow = False
                Exit For
            End If
        Next dimensionIndex

        If validRow Then
            For dimensionIndex = 1 To dimensionCount
                valueKey = CountUniqueV6ValueKey(sourceValues(dimensionIndex))
                If Not valueDictionaries(dimensionIndex).Exists(valueKey) Then
                    valueId = valueLists(dimensionIndex).Count + 1
                    valueDictionaries(dimensionIndex).Add valueKey, valueId
                    valueLists(dimensionIndex).Add sourceValues(dimensionIndex)
                End If
                sourceIds(dimensionIndex) = valueDictionaries(dimensionIndex)(valueKey)
            Next dimensionIndex

            For dimensionIndex = 2 To dimensionCount
                horizontalIds(dimensionIndex) = sourceIds(dimensionIndex)
            Next dimensionIndex
            columnKey = CountUniqueV6TupleKey(horizontalIds)

            If includeEmptyFlag = 0 Then
                If Not observedColumns.Exists(columnKey) Then
                    observedColumns.Add columnKey, horizontalIds
                    If observedColumns.Count >= maximumColumns Then
                        COUNTUNIQUE_V6 = CVErr(xlErrNum)
                        Exit Function
                    End If
                End If
            End If

            countKey = CStr(sourceIds(1)) & "|" & columnKey
            If counts.Exists(countKey) Then
                counts(countKey) = counts(countKey) + 1
            Else
                counts.Add countKey, 1
            End If
        End If
    Next sourceIndex

    If counts.Count = 0 Then
        COUNTUNIQUE_V6 = ""
        Exit Function
    End If

    If headerRows + headingRows >= maximumRows Then
        COUNTUNIQUE_V6 = CVErr(xlErrNum)
        Exit Function
    End If
    If valueLists(1).Count > maximumRows - headerRows - headingRows Then
        COUNTUNIQUE_V6 = CVErr(xlErrNum)
        Exit Function
    End If

    For dimensionIndex = 1 To dimensionCount
        dimensionSizes(dimensionIndex) = valueLists(dimensionIndex).Count
    Next dimensionIndex

    If includeEmptyFlag = 1 Then
        dataColumnCount = 1
        For dimensionIndex = 2 To dimensionCount
            If dimensionSizes(dimensionIndex) > (maximumColumns - 1) \ dataColumnCount Then
                COUNTUNIQUE_V6 = CVErr(xlErrNum)
                Exit Function
            End If
            dataColumnCount = dataColumnCount * dimensionSizes(dimensionIndex)
        Next dimensionIndex
    Else
        dataColumnCount = observedColumns.Count
    End If

    For dimensionIndex = 1 To dimensionCount
        CountUniqueV6CollectionToArray valueLists(dimensionIndex), sortedValues
        If sortFlags(dimensionIndex) = 1 Then CountUniqueV6SortValues sortedValues
        dimensionValues(dimensionIndex) = sortedValues
        ReDim ranksById(1 To dimensionSizes(dimensionIndex))
        ReDim idsByRank(1 To dimensionSizes(dimensionIndex))

        For valueIndex = 1 To dimensionSizes(dimensionIndex)
            valueKey = CountUniqueV6ValueKey(sortedValues(valueIndex))
            valueId = valueDictionaries(dimensionIndex)(valueKey)
            ranksById(valueId) = valueIndex
            idsByRank(valueIndex) = valueId
        Next valueIndex

        dimensionRanks(dimensionIndex) = ranksById
        dimensionIds(dimensionIndex) = idsByRank
    Next dimensionIndex

    If includeEmptyFlag = 0 Then
        observedTuples = observedColumns.Items
        For i = LBound(observedTuples) To UBound(observedTuples)
            tupleIds = observedTuples(i)
            ReDim tupleRanks(2 To dimensionCount)
            For dimensionIndex = 2 To dimensionCount
                tupleRanks(dimensionIndex) = CountUniqueV6ArrayLong( _
                    dimensionRanks(dimensionIndex), CLng(tupleIds(dimensionIndex)))
            Next dimensionIndex
            observedTuples(i) = tupleRanks
        Next i
        CountUniqueV6SortTuples observedTuples, LBound(observedTuples), UBound(observedTuples)
    Else
        ReDim strides(2 To dimensionCount)
        strides(dimensionCount) = 1
        For dimensionIndex = dimensionCount - 1 To 2 Step -1
            strides(dimensionIndex) = strides(dimensionIndex + 1) _
                * dimensionSizes(dimensionIndex + 1)
        Next dimensionIndex
    End If

    totalRows = dimensionSizes(1) + headerRows + headingRows
    totalColumns = dataColumnCount + 1
    ReDim result(1 To totalRows, 1 To totalColumns)
    For i = 1 To totalRows
        For j = 1 To totalColumns
            result(i, j) = ""
        Next j
    Next i

    If headingRows = 1 Then result(1, 1) = headingValue
    For valueIndex = 1 To dimensionSizes(1)
        outputRow = headingRows + headerRows + valueIndex
        result(outputRow, 1) = CountUniqueV6ArrayValue(dimensionValues(1), valueIndex)
    Next valueIndex

    ReDim currentRanks(2 To dimensionCount)
    ReDim previousRanks(2 To dimensionCount)
    For columnIndex = 1 To dataColumnCount
        If includeEmptyFlag = 0 Then tupleRanks = observedTuples(columnIndex - 1)
        prefixChanged = False
        For dimensionIndex = 2 To dimensionCount
            If includeEmptyFlag = 1 Then
                currentRanks(dimensionIndex) = _
                    ((columnIndex - 1) \ strides(dimensionIndex)) _
                    Mod dimensionSizes(dimensionIndex) + 1
            Else
                currentRanks(dimensionIndex) = tupleRanks(dimensionIndex)
            End If

            horizontalIds(dimensionIndex) = CountUniqueV6ArrayLong( _
                dimensionIds(dimensionIndex), currentRanks(dimensionIndex))
            If currentRanks(dimensionIndex) <> previousRanks(dimensionIndex) Then
                prefixChanged = True
            End If
            If prefixChanged Then
                result(headingRows + dimensionIndex - 1, columnIndex + 1) = _
                    CountUniqueV6ArrayValue( _
                        dimensionValues(dimensionIndex), currentRanks(dimensionIndex))
            End If
            previousRanks(dimensionIndex) = currentRanks(dimensionIndex)
        Next dimensionIndex

        outputColumns.Add CountUniqueV6TupleKey(horizontalIds), columnIndex + 1
    Next columnIndex

    For Each countKey In counts.Keys
        separatorPosition = InStr(1, CStr(countKey), "|", vbBinaryCompare)
        rowId = CLng(Left$(CStr(countKey), separatorPosition - 1))
        columnKey = Mid$(CStr(countKey), separatorPosition + 1)
        outputRow = headingRows + headerRows _
            + CountUniqueV6ArrayLong(dimensionRanks(1), rowId)
        outputColumn = outputColumns(columnKey)
        result(outputRow, outputColumn) = counts(countKey)
    Next countKey

    COUNTUNIQUE_V6 = result
    Exit Function

InvalidArguments:
    If Err.Number = 6 Or Err.Number = 7 Then
        COUNTUNIQUE_V6 = CVErr(xlErrNum)
    Else
        COUNTUNIQUE_V6 = CVErr(xlErrValue)
    End If
End Function

Private Function TryGetCountUniqueV6Flag( _
    ByVal flagValue As Variant, _
    ByRef resultFlag As Long) As Boolean

    Dim scalarValue As Variant
    Dim numericValue As Double

    On Error GoTo InvalidFlag
    If IsObject(flagValue) Then
        If Not TypeOf flagValue Is Range Then Exit Function
        If flagValue Is Nothing Then Exit Function
        If flagValue.Cells.CountLarge <> 1 Then Exit Function
        scalarValue = flagValue.Value2
    Else
        scalarValue = flagValue
    End If

    If IsError(scalarValue) Then Exit Function
    If IsArray(scalarValue) Then Exit Function
    If IsEmpty(scalarValue) Then Exit Function
    If IsNull(scalarValue) Then Exit Function
    If Not IsNumeric(scalarValue) Then Exit Function
    numericValue = CDbl(scalarValue)
    If numericValue <> 0 And numericValue <> 1 Then Exit Function
    resultFlag = CLng(numericValue)
    TryGetCountUniqueV6Flag = True
InvalidFlag:
End Function

Private Function CountUniqueV6SourceValue( _
    ByRef sourceData As Variant, _
    ByVal sourceIndex As Long, _
    ByVal sourceWidth As Long) As Variant

    If IsArray(sourceData) Then
        CountUniqueV6SourceValue = sourceData( _
            (sourceIndex - 1) \ sourceWidth + 1, (sourceIndex - 1) Mod sourceWidth + 1)
    Else
        CountUniqueV6SourceValue = sourceData
    End If
End Function

Private Function CountUniqueV6UsableValue(ByVal value As Variant) As Boolean
    If IsError(value) Then Exit Function
    If IsNull(value) Then Exit Function
    If IsEmpty(value) Then Exit Function
    CountUniqueV6UsableValue = (Len(Trim$(CStr(value))) > 0)
End Function

Private Function CountUniqueV6ValueKey(ByVal value As Variant) As String
    CountUniqueV6ValueKey = TypeName(value) & "|" & CStr(value)
End Function

Private Function CountUniqueV6TupleKey(ByRef ids() As Long) As String
    Dim i As Long
    Dim key As String

    For i = LBound(ids) To UBound(ids)
        If i > LBound(ids) Then key = key & "|"
        key = key & CStr(ids(i))
    Next i
    CountUniqueV6TupleKey = key
End Function

Private Function CountUniqueV6ArrayLong( _
    ByRef values As Variant, _
    ByVal index As Long) As Long

    CountUniqueV6ArrayLong = values(index)
End Function

Private Function CountUniqueV6ArrayValue( _
    ByRef values As Variant, _
    ByVal index As Long) As Variant

    CountUniqueV6ArrayValue = values(index)
End Function

Private Sub CountUniqueV6CollectionToArray( _
    ByVal source As Collection, _
    ByRef values() As Variant)

    Dim i As Long

    ReDim values(1 To source.Count)
    For i = 1 To source.Count
        values(i) = source(i)
    Next i
End Sub

Private Sub CountUniqueV6SortValues(ByRef values() As Variant)
    Dim i As Long
    Dim j As Long
    Dim temporaryValue As Variant

    ' Keep the same numeric/text comparison and sorting behavior as V5.
    For i = LBound(values) To UBound(values) - 1
        For j = i + 1 To UBound(values)
            If CountUniqueV6ValueComesAfter(values(i), values(j)) Then
                temporaryValue = values(i)
                values(i) = values(j)
                values(j) = temporaryValue
            End If
        Next j
    Next i
End Sub

Private Function CountUniqueV6ValueComesAfter( _
    ByVal firstValue As Variant, _
    ByVal secondValue As Variant) As Boolean

    If IsNumeric(firstValue) And IsNumeric(secondValue) Then
        CountUniqueV6ValueComesAfter = (CDbl(firstValue) > CDbl(secondValue))
    Else
        CountUniqueV6ValueComesAfter = _
            (StrComp(CStr(firstValue), CStr(secondValue), vbTextCompare) > 0)
    End If
End Function

Private Sub CountUniqueV6SortTuples( _
    ByRef tuples As Variant, _
    ByVal first As Long, _
    ByVal last As Long)

    Dim low As Long
    Dim high As Long
    Dim pivot As Variant
    Dim temporaryTuple As Variant

    If first >= last Then Exit Sub
    low = first
    high = last
    pivot = tuples(first + (last - first) \ 2)

    Do While low <= high
        Do While CountUniqueV6CompareTuples(tuples(low), pivot) < 0
            low = low + 1
        Loop
        Do While CountUniqueV6CompareTuples(tuples(high), pivot) > 0
            high = high - 1
        Loop
        If low <= high Then
            temporaryTuple = tuples(low)
            tuples(low) = tuples(high)
            tuples(high) = temporaryTuple
            low = low + 1
            high = high - 1
        End If
    Loop

    If first < high Then CountUniqueV6SortTuples tuples, first, high
    If low < last Then CountUniqueV6SortTuples tuples, low, last
End Sub

Private Function CountUniqueV6CompareTuples( _
    ByRef first As Variant, _
    ByRef second As Variant) As Long

    Dim i As Long

    For i = LBound(first) To UBound(first)
        If first(i) < second(i) Then
            CountUniqueV6CompareTuples = -1
            Exit Function
        End If
        If first(i) > second(i) Then
            CountUniqueV6CompareTuples = 1
            Exit Function
        End If
    Next i
End Function
