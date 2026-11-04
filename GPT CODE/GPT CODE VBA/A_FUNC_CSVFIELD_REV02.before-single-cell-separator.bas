Attribute VB_Name = "A_FUNC_CSVFIELD"
Option Explicit

' Return one or more fields from comma-separated text.
' Field numbers start at 1 and may be repeated.
' Multiple fields spill horizontally in the requested order.
' If the final argument is TRUE/FALSE, it controls trimming.
' Default TrimSpaces = TRUE.
'
' Examples:
' =CSVFIELD(W2, 4)
' =CSVFIELD(W2, 3, 1, 3, TRUE)
' =CSVFIELD(W2, 3, 1, 3, FALSE)
Public Function CSVFIELD( _
    ByVal CsvText As Variant, _
    ParamArray Arguments() As Variant) As Variant

    Dim sourceValue As Variant
    Dim sourceRange As Range
    Dim fields As Collection
    Dim requestedFields() As Long
    Dim result() As Variant
    Dim firstArgument As Long
    Dim lastArgument As Long
    Dim lastFieldArgument As Long
    Dim fieldCount As Long
    Dim fieldIndex As Double
    Dim trimSpaces As Boolean
    Dim i As Long

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

    On Error Resume Next
    firstArgument = LBound(Arguments)
    lastArgument = UBound(Arguments)
    If Err.Number <> 0 Then
        Err.Clear
        On Error GoTo 0
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If
    On Error GoTo 0

    trimSpaces = True
    lastFieldArgument = lastArgument

    If VarType(Arguments(lastArgument)) = vbBoolean Then
        trimSpaces = CBool(Arguments(lastArgument))
        lastFieldArgument = lastArgument - 1
    End If

    If lastFieldArgument < firstArgument Then
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If

    fieldCount = lastFieldArgument - firstArgument + 1
    ReDim requestedFields(1 To fieldCount)

    For i = firstArgument To lastFieldArgument
        If IsError(Arguments(i)) Or Not IsNumeric(Arguments(i)) Then
            CSVFIELD = CVErr(xlErrValue)
            Exit Function
        End If

        fieldIndex = CDbl(Arguments(i))
        If fieldIndex < 1 Or fieldIndex <> Fix(fieldIndex) Then
            CSVFIELD = CVErr(xlErrValue)
            Exit Function
        End If

        requestedFields(i - firstArgument + 1) = CLng(fieldIndex)
    Next i

    Set fields = ParseCsvFields(CStr(sourceValue), trimSpaces)
    If fields Is Nothing Then
        CSVFIELD = CVErr(xlErrValue)
        Exit Function
    End If

    If fieldCount = 1 Then
        CSVFIELD = CsvFieldValue(fields, requestedFields(1))
        Exit Function
    End If

    ReDim result(1 To 1, 1 To fieldCount)

    For i = 1 To fieldCount
        result(1, i) = CsvFieldValue(fields, requestedFields(i))
    Next i

    CSVFIELD = result
End Function

Private Function ParseCsvFields( _
    ByVal sourceText As String, _
    ByVal trimSpaces As Boolean) As Collection

    Dim fields As Collection
    Dim fieldText As String
    Dim position As Long
    Dim parenthesisDepth As Long
    Dim character As String
    Dim inQuotes As Boolean

    Set fields = New Collection

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
            If trimSpaces Then fieldText = Trim$(fieldText)
            fields.Add fieldText
            fieldText = ""
        Else
            fieldText = fieldText & character
        End If
    Next position

    If inQuotes Or parenthesisDepth <> 0 Then Exit Function

    If trimSpaces Then fieldText = Trim$(fieldText)
    fields.Add fieldText
    Set ParseCsvFields = fields
End Function

Private Function CsvFieldValue( _
    ByVal fields As Collection, _
    ByVal fieldNumber As Long) As Variant

    If fieldNumber <= fields.Count Then
        CsvFieldValue = fields(fieldNumber)
    Else
        CsvFieldValue = ""
    End If
End Function
