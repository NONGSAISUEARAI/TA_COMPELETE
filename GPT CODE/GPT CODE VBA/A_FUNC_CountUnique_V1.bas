Attribute VB_Name = "A_FUNC_CountUnique_V1"
Option Explicit

' Returns a two-column spill array:
' Column 1 = Unique List
' Column 2 = Count
'
' Example:
' =COUNTUNIQUE(A1:A20)
Public Function COUNTUNIQUE(ByVal UniqueRange As Range) As Variant

    Dim dict As Object
    Dim uniqueValues As Collection
    Dim result() As Variant
    Dim keyValue As Variant
    Dim dictKey As String
    Dim i As Long

    Set dict = CreateObject("Scripting.Dictionary")
    Set uniqueValues = New Collection
    dict.CompareMode = vbTextCompare

    For i = 1 To UniqueRange.Cells.CountLarge
        keyValue = UniqueRange.Cells(i).Value2

        If Not IsError(keyValue) Then
            If Len(Trim$(CStr(keyValue))) > 0 Then
                dictKey = TypeName(keyValue) & "|" & CStr(keyValue)

                If Not dict.Exists(dictKey) Then
                    dict.Add dictKey, 1
                    uniqueValues.Add keyValue
                Else
                    dict(dictKey) = dict(dictKey) + 1
                End If
            End If
        End If
    Next i

    If uniqueValues.Count = 0 Then
        COUNTUNIQUE = ""
        Exit Function
    End If

    ReDim result(1 To uniqueValues.Count + 1, 1 To 2)
    result(1, 1) = "Unique List"
    result(1, 2) = "Count"

    For i = 1 To uniqueValues.Count
        keyValue = uniqueValues(i)
        dictKey = TypeName(keyValue) & "|" & CStr(keyValue)

        result(i + 1, 1) = keyValue
        result(i + 1, 2) = dict(dictKey)
    Next i

    COUNTUNIQUE = result
End Function
