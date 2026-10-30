Attribute VB_Name = "A_FUNC_HeadingDetailTable"
Option Explicit

' Return selected detail columns for one or more heading codes.
' Pass output ranges in the order they should appear in the result.
'
' HeadingRange: one or more heading rows. The first column contains codes.
'               Include every column to display on the heading row, such as
'               Item Category columns A:C (Code, Level, Category Name).
'               ROWS outputs each numbered heading once, then its detail rows.
'               COLUMNS outputs one numbered row per heading, then its details.
' DetailKeyRange: one column on the detail sheet containing item numbers.
' Output arguments: one or more ranges from the detail sheet. Each range must
'                   have the same number and order of rows as DetailKeyRange.
'                   A range may contain one or several adjacent columns.
'                   Duplicate source rows are preserved.
' Text options: "PREFIX" (default) or "EXACT" for matching; "ROWS" (default)
'               or "COLUMNS" for the spill direction. All headings appear
'               by default. "MATCHEDONLY" hides headings without details
'               in ROWS mode.
'               Options may be supplied after the output ranges in any order.
'
' Heading followed by detail rows:
' =HEADINGDETAILTABLE('Item Category'!$A$237:$C$250,'Total On Hand'!$C$2:$C$3506,'Total On Hand'!$A$2:$J$3506)
' Selected columns C, D, F and I, in that order:
' =HEADINGDETAILTABLE($A$2,'Total On Hand'!$C$2:$C$3506,'Total On Hand'!$C$2:$D$3506,'Total On Hand'!$F$2:$F$3506,'Total On Hand'!$I$2:$I$3506)
' One output row per heading, entered in a blank result area:
' =HEADINGDETAILTABLE('Item Category'!$A$237:$C$250,'Total On Hand'!$C$2:$C$3506,'Total On Hand'!$C$2:$C$3506,"COLUMNS")
'
Public Function HEADINGDETAILTABLE( _
    ByVal HeadingRange As Range, _
    ByVal DetailKeyRange As Range, _
    ParamArray OutputArguments() As Variant) As Variant

    Dim headingData As Variant
    Dim headingValue As Variant
    Dim keyData As Variant
    Dim rangeData As Variant
    Dim argument As Variant
    Dim selectedRange As Range
    Dim outputRanges As Collection
    Dim outputData As Collection
    Dim result() As Variant
    Dim headingCodes() As String
    Dim matchCounts() As Long
    Dim mode As String
    Dim direction As String
    Dim optionText As String
    Dim matchedOnly As Boolean
    Dim rowCount As Long
    Dim headingRowCount As Long
    Dim headingColumnCount As Long
    Dim outputColumnCount As Long
    Dim resultColumnCount As Long
    Dim resultRowCount As Long
    Dim maxMatchCount As Long
    Dim matchedOrdinal As Long
    Dim headingNumber As Long
    Dim headingRow As Long
    Dim sourceRow As Long
    Dim outputRow As Long
    Dim outputColumn As Long
    Dim columnIndex As Long
    Dim rangeIndex As Long

    On Error GoTo InvalidInput

    If HeadingRange Is Nothing Or DetailKeyRange Is Nothing Then GoTo InvalidReference
    If HeadingRange.Areas.Count <> 1 Then GoTo InvalidReference
    If DetailKeyRange.Areas.Count <> 1 Then GoTo InvalidReference
    If DetailKeyRange.Columns.CountLarge <> 1 Then GoTo InvalidReference

    Set outputRanges = New Collection
    Set outputData = New Collection
    mode = "PREFIX"
    direction = "ROWS"

    For Each argument In OutputArguments
        If IsObject(argument) Then
            Set selectedRange = Nothing
            Set selectedRange = argument
            If selectedRange Is Nothing Then GoTo InvalidInput
            If selectedRange.Areas.Count <> 1 Then GoTo InvalidReference
            If selectedRange.Rows.CountLarge <> DetailKeyRange.Rows.CountLarge Then GoTo InvalidReference
            outputRanges.Add selectedRange
            outputData.Add selectedRange.Value2
            outputColumnCount = outputColumnCount + CLng(selectedRange.Columns.CountLarge)
        ElseIf VarType(argument) = vbString Then
            optionText = UCase$(Trim$(CStr(argument)))
            Select Case optionText
                Case "PREFIX", "EXACT"
                    mode = optionText
                Case "ROWS", "COLUMNS"
                    direction = optionText
                Case "KEEPALL"
                    matchedOnly = False
                Case "MATCHEDONLY"
                    matchedOnly = True
                Case Else
                    GoTo InvalidInput
            End Select
        Else
            GoTo InvalidInput
        End If
    Next argument

    If outputRanges.Count = 0 Then
        outputRanges.Add DetailKeyRange
        outputData.Add DetailKeyRange.Value2
        outputColumnCount = 1
    End If

    headingData = HeadingRange.Value2
    keyData = DetailKeyRange.Value2
    rowCount = CLng(DetailKeyRange.Rows.CountLarge)
    headingRowCount = CLng(HeadingRange.Rows.CountLarge)
    headingColumnCount = CLng(HeadingRange.Columns.CountLarge)
    ReDim headingCodes(1 To headingRowCount)
    ReDim matchCounts(1 To headingRowCount)

    For headingRow = 1 To headingRowCount
        headingValue = DetailTableValueAt(headingData, headingRow, 1)
        If Not IsError(headingValue) Then
            headingCodes(headingRow) = Trim$(CStr(headingValue))
            If Len(headingCodes(headingRow)) > 0 Then
                For sourceRow = 1 To rowCount
                    If DetailTableRowMatches(keyData, sourceRow, _
                        headingCodes(headingRow), mode) Then
                        matchCounts(headingRow) = matchCounts(headingRow) + 1
                    End If
                Next sourceRow
            End If
        End If
        If matchCounts(headingRow) > maxMatchCount Then
            maxMatchCount = matchCounts(headingRow)
        End If
        If direction = "ROWS" Then
            resultRowCount = resultRowCount + matchCounts(headingRow)
            If Not matchedOnly Or matchCounts(headingRow) > 0 Then
                resultRowCount = resultRowCount + 1
            End If
        End If
    Next headingRow

    If direction = "COLUMNS" Then
        resultRowCount = headingRowCount
        resultColumnCount = 1 + headingColumnCount _
            + maxMatchCount * outputColumnCount
    Else
        If resultRowCount = 0 Then GoTo NoMatches
        resultColumnCount = 2 + outputColumnCount
        If 1 + headingColumnCount > resultColumnCount Then
            resultColumnCount = 1 + headingColumnCount
        End If
    End If

    ReDim result(1 To resultRowCount, 1 To resultColumnCount)
    For outputRow = 1 To resultRowCount
        For outputColumn = 1 To resultColumnCount
            result(outputRow, outputColumn) = vbNullString
        Next outputColumn
    Next outputRow

    outputRow = 0
    For headingRow = 1 To headingRowCount
        If direction = "COLUMNS" Then
            outputRow = headingRow
            headingNumber = headingRow
        ElseIf Not matchedOnly Or matchCounts(headingRow) > 0 Then
            outputRow = outputRow + 1
            headingNumber = headingNumber + 1
        End If

        If direction = "COLUMNS" Or Not matchedOnly _
            Or matchCounts(headingRow) > 0 Then
            result(outputRow, 1) = headingNumber
            For columnIndex = 1 To headingColumnCount
                result(outputRow, columnIndex + 1) = DetailTableValueAt( _
                    headingData, headingRow, columnIndex)
            Next columnIndex
        End If

        If matchCounts(headingRow) > 0 Then
            matchedOrdinal = 0
            For sourceRow = 1 To rowCount
                If DetailTableRowMatches(keyData, sourceRow, _
                    headingCodes(headingRow), mode) Then
                    matchedOrdinal = matchedOrdinal + 1
                    If direction = "COLUMNS" Then
                        outputRow = headingRow
                        outputColumn = 1 + headingColumnCount _
                            + (matchedOrdinal - 1) * outputColumnCount
                    Else
                        outputRow = outputRow + 1
                        outputColumn = 2
                    End If

                    For rangeIndex = 1 To outputRanges.Count
                        Set selectedRange = outputRanges(rangeIndex)
                        rangeData = outputData(rangeIndex)
                        For columnIndex = 1 To selectedRange.Columns.CountLarge
                            outputColumn = outputColumn + 1
                            result(outputRow, outputColumn) = DetailTableValueAt( _
                                rangeData, sourceRow, columnIndex)
                        Next columnIndex
                    Next rangeIndex
                End If
            Next sourceRow
        End If
    Next headingRow

    HEADINGDETAILTABLE = result
    Exit Function

NoMatches:
    HEADINGDETAILTABLE = vbNullString
    Exit Function

InvalidReference:
    HEADINGDETAILTABLE = CVErr(xlErrRef)
    Exit Function

InvalidInput:
    HEADINGDETAILTABLE = CVErr(xlErrValue)
End Function

Private Function DetailTableRowMatches( _
    ByRef keyData As Variant, _
    ByVal rowIndex As Long, _
    ByVal headingCode As String, _
    ByVal mode As String) As Boolean

    Dim itemValue As Variant
    Dim itemCode As String

    itemValue = DetailTableValueAt(keyData, rowIndex, 1)
    If IsError(itemValue) Then Exit Function
    If IsEmpty(itemValue) Or IsNull(itemValue) Then Exit Function

    itemCode = Trim$(CStr(itemValue))
    If mode = "PREFIX" Then
        DetailTableRowMatches = (StrComp(Left$(itemCode, Len(headingCode)), _
            headingCode, vbTextCompare) = 0)
    Else
        DetailTableRowMatches = (StrComp(itemCode, headingCode, vbTextCompare) = 0)
    End If
End Function

Private Function DetailTableValueAt( _
    ByRef sourceData As Variant, _
    ByVal rowIndex As Long, _
    ByVal columnIndex As Long) As Variant

    Dim cellValue As Variant

    If IsArray(sourceData) Then
        cellValue = sourceData(rowIndex, columnIndex)
    Else
        cellValue = sourceData
    End If

    If IsEmpty(cellValue) Or IsNull(cellValue) Then
        DetailTableValueAt = vbNullString
    Else
        DetailTableValueAt = cellValue
    End If
End Function
