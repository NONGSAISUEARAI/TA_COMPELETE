Attribute VB_Name = "SumUniqueModule"
Option Explicit

' Returns a two-column spill array:
' Column 1 = Unique List
' Column 2 = Total Value
'
' Examples:
' =SUMUNIQUE(A1:A20)
' =SUMUNIQUE(A1:A20,B1:B20)
Public Function SUMUNIQUE( _
    ByVal UniqueRange As Range, _
    Optional ByVal SumRange As Range) As Variant

    Dim dict As Object
    Dim uniqueValues As Collection
    Dim result() As Variant
    Dim keyValue As Variant
    Dim sumValue As Variant
    Dim dictKey As String
    Dim i As Long

    If SumRange Is Nothing Then
        Set SumRange = UniqueRange
    End If

    If UniqueRange.Cells.CountLarge <> SumRange.Cells.CountLarge Then
        SUMUNIQUE = CVErr(xlErrRef)
        Exit Function
    End If

    Set dict = CreateObject("Scripting.Dictionary")
    Set uniqueValues = New Collection
    dict.CompareMode = vbTextCompare

    For i = 1 To UniqueRange.Cells.CountLarge
        keyValue = UniqueRange.Cells(i).Value2

        If Not IsError(keyValue) Then
            If Len(Trim$(CStr(keyValue))) > 0 Then
                dictKey = TypeName(keyValue) & "|" & CStr(keyValue)

                If Not dict.Exists(dictKey) Then
                    dict.Add dictKey, uniqueValues.Count + 1
                    uniqueValues.Add keyValue
                End If
            End If
        End If
    Next i

    If uniqueValues.Count = 0 Then
        SUMUNIQUE = ""
        Exit Function
    End If

    ReDim result(1 To uniqueValues.Count + 1, 1 To 2)
    result(1, 1) = "Unique List"
    result(1, 2) = "Total Value"

    For i = 1 To uniqueValues.Count
        keyValue = uniqueValues(i)
        sumValue = Application.SumIfs(SumRange, UniqueRange, keyValue)

        result(i + 1, 1) = keyValue
        result(i + 1, 2) = sumValue
    Next i

    SUMUNIQUE = result
End Function
