Attribute VB_Name = "UniqueIfsModule"
Option Explicit

' Returns a one-column unique list filtered by one or more criteria pairs.
'
' Syntax:
' =UNIQUEIFS(UniqueRange, CriteriaRange1, Criteria1, [CriteriaRange2, Criteria2], ...)
'
' Examples:
' =UNIQUEIFS(A2:A100,B2:B100,"PP17")
' =UNIQUEIFS(A2:A100,B2:B100,"PP17",C2:C100,"STD-LENGTH_1500")
' =UNIQUEIFS(A2:A100,B2:B100,E1,C2:C100,D2)
Public Function UNIQUEIFS( _
    ByVal UniqueRange As Range, _
    ParamArray CriteriaArguments() As Variant) As Variant

    Dim uniqueDict As Object
    Dim uniqueList As Collection
    Dim result() As Variant
    Dim criteriaRange As Range
    Dim criteriaValue As Variant
    Dim uniqueValue As Variant
    Dim uniqueKey As String
    Dim argumentCount As Long
    Dim includeRow As Boolean
    Dim i As Long
    Dim j As Long

    On Error Resume Next
    argumentCount = UBound(CriteriaArguments) _
        - LBound(CriteriaArguments) + 1
    On Error GoTo 0

    If argumentCount = 0 Or argumentCount Mod 2 <> 0 Then
        UNIQUEIFS = CVErr(xlErrValue)
        Exit Function
    End If

    For j = 0 To argumentCount - 1 Step 2
        If Not IsObject(CriteriaArguments(j)) Then
            UNIQUEIFS = CVErr(xlErrRef)
            Exit Function
        End If

        Set criteriaRange = CriteriaArguments(j)

        If criteriaRange.Cells.CountLarge <> UniqueRange.Cells.CountLarge Then
            UNIQUEIFS = CVErr(xlErrRef)
            Exit Function
        End If
    Next j

    Set uniqueDict = CreateObject("Scripting.Dictionary")
    Set uniqueList = New Collection
    uniqueDict.CompareMode = vbTextCompare

    For i = 1 To UniqueRange.Cells.CountLarge
        includeRow = True

        For j = 0 To argumentCount - 1 Step 2
            Set criteriaRange = CriteriaArguments(j)
            criteriaValue = CriteriaArguments(j + 1)

            If IsObject(criteriaValue) Then
                criteriaValue = criteriaValue.Cells(1, 1).Value2
            End If

            If Not UniqueIfsCellMatches( _
                criteriaRange.Cells(i), criteriaValue) Then

                includeRow = False
                Exit For
            End If
        Next j

        If includeRow Then
            uniqueValue = UniqueRange.Cells(i).Value2

            If Not IsError(uniqueValue) Then
                If Len(Trim$(CStr(uniqueValue))) > 0 Then
                    uniqueKey = TypeName(uniqueValue) & "|" & CStr(uniqueValue)

                    If Not uniqueDict.Exists(uniqueKey) Then
                        uniqueDict.Add uniqueKey, True
                        uniqueList.Add uniqueValue
                    End If
                End If
            End If
        End If
    Next i

    If uniqueList.Count = 0 Then
        UNIQUEIFS = ""
        Exit Function
    End If

    ReDim result(1 To uniqueList.Count, 1 To 1)

    For i = 1 To uniqueList.Count
        result(i, 1) = uniqueList(i)
    Next i

    UNIQUEIFS = result
End Function

Private Function UniqueIfsCellMatches( _
    ByVal targetCell As Range, _
    ByVal criteriaValue As Variant) As Boolean

    Dim matchResult As Variant

    If IsError(targetCell.Value2) Or IsError(criteriaValue) Then
        UniqueIfsCellMatches = False
        Exit Function
    End If

    matchResult = Application.CountIf(targetCell, criteriaValue)

    If IsError(matchResult) Then
        UniqueIfsCellMatches = False
    Else
        UniqueIfsCellMatches = (CLng(matchResult) > 0)
    End If
End Function
