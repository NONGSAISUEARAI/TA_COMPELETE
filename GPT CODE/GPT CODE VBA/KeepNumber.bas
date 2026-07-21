Attribute VB_Name = "KeepNumberModule"
Option Explicit

Public Function KeepNumber(ByVal s As String) As Long
    Dim i As Long
    Dim t As String
    Dim ch As String

    For i = 1 To Len(s)
        ch = Mid$(s, i, 1)

        If ch >= "0" And ch <= "9" Then
            t = t & ch
        ElseIf Len(t) > 0 Then
            Exit For
        End If
    Next i

    If Len(t) > 0 Then
        KeepNumber = CLng(t)
    Else
        KeepNumber = 0
    End If
End Function
