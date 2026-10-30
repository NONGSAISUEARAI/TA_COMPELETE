Attribute VB_Name = "A_FUNC_HeadingDetails"
Option Explicit

' Return the detail values belonging to one heading as a horizontal spill.
'
' HeadingCell: one cell containing the heading code, for example A243.
' MatchRange: one column on the detail sheet containing codes to compare.
' ReturnRange: optional one-column range containing values to return.
'              Omit it to return the matching codes themselves.
' MatchMode: "PREFIX" (default) or "EXACT".
' UniqueOnly: remove duplicate returned values (default TRUE).
' SortResult: sort returned values as text (default TRUE).
'
' Examples, entered in D243 on the heading sheet:
' =HEADINGDETAILS($A243,'Total On Hand'!$C$2:$C$3506)
' =HEADINGDETAILS($A243,'Total On Hand'!$C$2:$C$3506,'Total On Hand'!$D$2:$D$3506)
' =HEADINGDETAILS($A243,'Total On Hand'!$C$2:$C$3506,,"EXACT")
'
Public Function HEADINGDETAILS( _
    ByVal HeadingCell As Range, _
    ByVal MatchRange As Range, _
    Optional ByVal ReturnRange As Range, _
    Optional ByVal MatchMode As String = "PREFIX", _
    Optional ByVal UniqueOnly As Boolean = True, _
    Optional ByVal SortResult As Boolean = True) As Variant

    Dim outputRange As Range
    Dim headingValue As Variant
    Dim matchData As Variant
    Dim returnData As Variant
    Dim matchValue As Variant
    Dim outputValue As Variant
    Dim headingCode As String
    Dim detailCode As String
    Dim mode As String
    Dim seen As Object
    Dim values() As Variant
    Dim result() As Variant
    Dim rowCount As Long
    Dim found As Long
    Dim rowIndex As Long
    Dim itemIndex As Long
    Dim isMatch As Boolean

    On Error GoTo InvalidInput

    If HeadingCell Is Nothing Or MatchRange Is Nothing Then GoTo InvalidReference
    If HeadingCell.Cells.CountLarge <> 1 Then GoTo InvalidReference
    If MatchRange.Areas.Count <> 1 Or MatchRange.Columns.CountLarge <> 1 Then GoTo InvalidReference

    If ReturnRange Is Nothing Then
        Set outputRange = MatchRange
    Else
        Set outputRange = ReturnRange
    End If

    If outputRange.Areas.Count <> 1 Or outputRange.Columns.CountLarge <> 1 Then GoTo InvalidReference
    If outputRange.Rows.CountLarge <> MatchRange.Rows.CountLarge Then GoTo InvalidReference

    mode = UCase$(Trim$(MatchMode))
    If mode <> "PREFIX" And mode <> "EXACT" Then GoTo InvalidInput

    headingValue = HeadingCell.Value2
    If IsError(headingValue) Then GoTo InvalidInput
    If IsEmpty(headingValue) Or IsNull(headingValue) Then
        HEADINGDETAILS = vbNullString
        Exit Function
    End If
    headingCode = Trim$(CStr(headingValue))
    If Len(headingCode) = 0 Then
        HEADINGDETAILS = vbNullString
        Exit Function
    End If

    matchData = MatchRange.Value2
    If ReturnRange Is Nothing Then
        returnData = matchData
    Else
        returnData = outputRange.Value2
    End If

    rowCount = CLng(MatchRange.Rows.CountLarge)
    ReDim values(1 To rowCount)

    If UniqueOnly Then
        Set seen = CreateObject("Scripting.Dictionary")
        seen.CompareMode = vbTextCompare
    End If

    For rowIndex = 1 To rowCount
        matchValue = HeadingDetailsValueAt(matchData, rowIndex)
        If Not IsError(matchValue) Then
            If Not IsEmpty(matchValue) And Not IsNull(matchValue) Then
                detailCode = Trim$(CStr(matchValue))
                If mode = "PREFIX" Then
                    isMatch = (StrComp(Left$(detailCode, Len(headingCode)), _
                        headingCode, vbTextCompare) = 0)
                Else
                    isMatch = (StrComp(detailCode, headingCode, vbTextCompare) = 0)
                End If

                If isMatch Then
                    outputValue = HeadingDetailsValueAt(returnData, rowIndex)
                    If Not IsError(outputValue) Then
                        If Not IsEmpty(outputValue) And Not IsNull(outputValue) Then
                            If Len(CStr(outputValue)) > 0 Then
                                If UniqueOnly Then
                                    If Not seen.Exists(CStr(outputValue)) Then
                                        seen.Add CStr(outputValue), True
                                        found = found + 1
                                        values(found) = outputValue
                                    End If
                                Else
                                    found = found + 1
                                    values(found) = outputValue
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        End If
    Next rowIndex

    If found = 0 Then
        HEADINGDETAILS = vbNullString
        Exit Function
    End If

    If SortResult And found > 1 Then SortHeadingDetails values, 1, found

    ReDim result(1 To 1, 1 To found)
    For itemIndex = 1 To found
        result(1, itemIndex) = values(itemIndex)
    Next itemIndex
    HEADINGDETAILS = result
    Exit Function

InvalidReference:
    HEADINGDETAILS = CVErr(xlErrRef)
    Exit Function

InvalidInput:
    HEADINGDETAILS = CVErr(xlErrValue)
End Function

Private Function HeadingDetailsValueAt(ByRef sourceData As Variant, ByVal rowIndex As Long) As Variant
    If IsArray(sourceData) Then
        HeadingDetailsValueAt = sourceData(rowIndex, 1)
    Else
        HeadingDetailsValueAt = sourceData
    End If
End Function

Private Sub SortHeadingDetails(ByRef values() As Variant, ByVal first As Long, ByVal last As Long)
    Dim leftIndex As Long
    Dim rightIndex As Long
    Dim pivot As String
    Dim temporary As Variant

    leftIndex = first
    rightIndex = last
    pivot = CStr(values((first + last) \ 2))

    Do While leftIndex <= rightIndex
        Do While StrComp(CStr(values(leftIndex)), pivot, vbTextCompare) < 0
            leftIndex = leftIndex + 1
        Loop
        Do While StrComp(CStr(values(rightIndex)), pivot, vbTextCompare) > 0
            rightIndex = rightIndex - 1
        Loop

        If leftIndex <= rightIndex Then
            temporary = values(leftIndex)
            values(leftIndex) = values(rightIndex)
            values(rightIndex) = temporary
            leftIndex = leftIndex + 1
            rightIndex = rightIndex - 1
        End If
    Loop

    If first < rightIndex Then SortHeadingDetails values, first, rightIndex
    If leftIndex < last Then SortHeadingDetails values, leftIndex, last
End Sub
