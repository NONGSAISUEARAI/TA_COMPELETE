Attribute VB_Name = "A_FUNC_CSVFIELD"
Option Explicit

' Return one field from comma-separated text. Field numbers start at 1.
' Commas inside double quotes or parentheses do not separate fields.
' Double quotes around a field are removed; doubled quotes become one quote.
' Leading and trailing spaces are removed by default.
'
' Examples:
' =CSVFIELD(W2, 4)          ' NS-1S-E0114
' =CSVFIELD(W2, 4, FALSE)   ' Preserve spaces around the field
' =CSVFIELD("A,(1,2),C", 2) ' (1,2)
Public Function CSVFIELD( _
    ByVal CsvText As Variant, _
    ByVal FieldNumber As Variant, _
    Optional ByVal TrimSpaces As Boolean = True) As Variant

    Dim sourceValue As Variant
    Dim sourceRange As Range
    Dim sourceText As String
    Dim fieldText As String
    Dim fieldIndex As Double
    Dim currentField As Double
    Dim position As Long
    Dim parenthesisDepth As Long
    Dim character As String
    Dim inQuotes As Boolean

    If IsObject(CsvText) Then
        If TypeName(CsvText) <> "Range" Then
            CSVFIELD = CVErr(xlErrValue)
            Exit Function
        End If
        Set sourceRange = CsvText
        If sourceRange.Cells.CountLarge <> 1 Then
            CSVFIELD = CVErr(xlErrValue)
            Exit Function
        End If
        sourceValue = sourceRange.Value2
    Else
        sourceValue = CsvText
    End If

    If IsError(sourceValue) Then
        CSVFIELD = sourceValue
        Exit Function
    End If
    If IsNull(sourceValue) Or IsEmpty(sourceValue) Then
        CSVFIELD = ""
        Exit Function
    End If
    If IsArray(sourceValue) Then
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If

    If IsError(FieldNumber) Then
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If
    If Not IsNumeric(FieldNumber) Then
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If
    fieldIndex = CDbl(FieldNumber)
    If fieldIndex < 1 Or fieldIndex <> Fix(fieldIndex) Then
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If

    sourceText = CStr(sourceValue)
    currentField = 1

    For position = 1 To Len(sourceText)
        character = Mid$(sourceText, position, 1)

        If character = """" Then
            If inQuotes And position < Len(sourceText) Then
                If Mid$(sourceText, position + 1, 1) = """" Then
                    fieldText = fieldText & """"
                    position = position + 1
                Else
                    inQuotes = False
                End If
            Else
                inQuotes = Not inQuotes
            End If
        ElseIf Not inQuotes And character = "(" Then
            parenthesisDepth = parenthesisDepth + 1
            fieldText = fieldText & character
        ElseIf Not inQuotes And character = ")" And parenthesisDepth > 0 Then
            parenthesisDepth = parenthesisDepth - 1
            fieldText = fieldText & character
        ElseIf Not inQuotes And parenthesisDepth = 0 And character = "," Then
            If currentField = fieldIndex Then
                If TrimSpaces Then fieldText = Trim$(fieldText)
                CSVFIELD = fieldText
                Exit Function
            End If
            currentField = currentField + 1
            fieldText = ""
        Else
            fieldText = fieldText & character
        End If
    Next position

    If inQuotes Or parenthesisDepth <> 0 Then
        CSVFIELD = CVErr(xlErrValue)
    ElseIf currentField = fieldIndex Then
        If TrimSpaces Then fieldText = Trim$(fieldText)
        CSVFIELD = fieldText
    Else
        CSVFIELD = ""
    End If
End Function
