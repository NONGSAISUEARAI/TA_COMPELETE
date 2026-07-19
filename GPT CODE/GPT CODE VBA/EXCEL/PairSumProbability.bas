Attribute VB_Name = "PairSumProbabilityModule"
Option Explicit

Public Function PairSumProbability(ByVal DataRange As Range) As Variant
    Dim cell As Range
    Dim values() As Double
    Dim itemCount As Long
    Dim i As Long, j As Long
    Dim pairCount As Long
    Dim sumValue As Double
    Dim dict As Object
    Dim keys As Variant
    Dim result() As Variant

    Set dict = CreateObject("Scripting.Dictionary")

    For Each cell In DataRange.Cells
        If Not IsError(cell.Value2) Then
            If Len(Trim$(CStr(cell.Value2))) > 0 Then
                If GetFirstNumber(CStr(cell.Value2), sumValue) Then
                    itemCount = itemCount + 1
                    ReDim Preserve values(1 To itemCount)
                    values(itemCount) = sumValue
                End If
            End If
        End If
    Next cell

    If itemCount < 2 Then
        PairSumProbability = CVErr(xlErrNA)
        Exit Function
    End If

    For i = 1 To itemCount - 1
        For j = i + 1 To itemCount
            sumValue = values(i) + values(j)
            pairCount = pairCount + 1

            If dict.Exists(CStr(sumValue)) Then
                dict(CStr(sumValue)) = dict(CStr(sumValue)) + 1
            Else
                dict.Add CStr(sumValue), 1
            End If
        Next j
    Next i

    keys = dict.Keys
    SortNumericArray keys

    ReDim result(1 To dict.Count + 1, 1 To 3)
    result(1, 1) = "ผลบวก"
    result(1, 2) = "จำนวนคู่"
    result(1, 3) = "ความน่าจะเป็น"

    For i = 0 To UBound(keys)
        result(i + 2, 1) = CDbl(keys(i))
        result(i + 2, 2) = dict(keys(i))
        result(i + 2, 3) = dict(keys(i)) / pairCount
    Next i

    PairSumProbability = result
End Function

Private Function GetFirstNumber( _
    ByVal Text As String, _
    ByRef NumberResult As Double) As Boolean

    Dim regex As Object
    Dim matches As Object
    Dim numberText As String

    Set regex = CreateObject("VBScript.RegExp")

    With regex
        .Pattern = "[-+]?[0-9]+([.,][0-9]+)?"
        .Global = False
    End With

    If regex.Test(Text) Then
        Set matches = regex.Execute(Text)
        numberText = matches(0).Value
        numberText = Replace(numberText, ".", Application.DecimalSeparator)
        numberText = Replace(numberText, ",", Application.DecimalSeparator)
        NumberResult = CDbl(numberText)
        GetFirstNumber = True
    End If
End Function

Private Sub SortNumericArray(ByRef arr As Variant)
    Dim i As Long, j As Long
    Dim temp As Variant

    For i = LBound(arr) To UBound(arr) - 1
        For j = i + 1 To UBound(arr)
            If CDbl(arr(j)) < CDbl(arr(i)) Then
                temp = arr(i)
                arr(i) = arr(j)
                arr(j) = temp
            End If
        Next j
    Next i
End Sub
