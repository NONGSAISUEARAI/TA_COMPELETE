Attribute VB_Name = "A_FUNC_CSVFIELD"
Option Explicit

' REV03: invalid arguments and malformed CSV return in-cell usage help
' instead of #VALUE!. Other source-cell errors are propagated unchanged.
' Keep the function name CSVFIELD; replace the old A_FUNC_CSVFIELD module
' when importing this revision to avoid duplicate public function names.

' Return one or more fields from comma-separated text.
' Field numbers start at 1 and may be repeated.
' Multiple fields are joined into one cell in the requested order.
' A TRUE/FALSE argument after the field numbers controls trimming.
' The final text argument is the separator. The default separator is comma.
'
' Examples:
' =CSVFIELD(W2, 4)
' =CSVFIELD(W2, 3, 1, 3, TRUE, " | ")
' =CSVFIELD(W2, 3, 1, 3, FALSE, "-")
Public Function CSVFIELD( _
    ByVal CsvText As Variant, _
    ParamArray Arguments() As Variant) As Variant

    Dim sourceValue As Variant
    Dim sourceRange As Range
    Dim fields As Collection
    Dim requestedFields() As Long
    Dim combinedText As String
    Dim firstArgument As Long
    Dim lastArgument As Long
    Dim lastFieldArgument As Long
    Dim fieldCount As Long
    Dim fieldIndex As Double
    Dim trimSpaces As Boolean
    Dim separator As String
    Dim i As Long

    On Error GoTo InvalidArguments

    If IsObject(CsvText) Then
        If TypeName(CsvText) <> "Range" Then
            CSVFIELD = CsvFieldUsageRev03("Source must be text or one cell.")
            Exit Function
        End If

        Set sourceRange = CsvText
        If sourceRange Is Nothing Then GoTo InvalidArguments
        If sourceRange.Cells.CountLarge <> 1 Then
            CSVFIELD = CsvFieldUsageRev03("Source must reference one cell, not a range of cells.")
            Exit Function
        End If

        sourceValue = sourceRange.Value2
    Else
        sourceValue = CsvText
    End If

    If IsError(sourceValue) Then
        If CStr(sourceValue) = CStr(CVErr(xlErrValue)) Then
            CSVFIELD = CsvFieldUsageRev03("The source cell already contains #VALUE!; fix the source first.")
        Else
            CSVFIELD = sourceValue
        End If
        Exit Function
    End If

    If IsNull(sourceValue) Or IsEmpty(sourceValue) Then
        CSVFIELD = ""
        Exit Function
    End If

    If IsArray(sourceValue) Then
        CSVFIELD = CsvFieldUsageRev03("Source must be text or one cell, not an array.")
        Exit Function
    End If

    firstArgument = LBound(Arguments)
    lastArgument = UBound(Arguments)
    If lastArgument < firstArgument Then
        CSVFIELD = CsvFieldUsageRev03("Supply at least one field number after the source.")
        Exit Function
    End If

    trimSpaces = True
    separator = ","
    lastFieldArgument = lastArgument

    If VarType(Arguments(lastFieldArgument)) = vbString Then
        separator = CStr(Arguments(lastFieldArgument))
        lastFieldArgument = lastFieldArgument - 1
    End If

    If lastFieldArgument >= firstArgument Then
        If VarType(Arguments(lastFieldArgument)) = vbBoolean Then
            trimSpaces = CBool(Arguments(lastFieldArgument))
            lastFieldArgument = lastFieldArgument - 1
        End If
    End If

    If lastFieldArgument < firstArgument Then
        CSVFIELD = CsvFieldUsageRev03("Supply at least one field number before Trim/Separator.")
        Exit Function
    End If

    fieldCount = lastFieldArgument - firstArgument + 1
    ReDim requestedFields(1 To fieldCount)

    For i = firstArgument To lastFieldArgument
        If IsError(Arguments(i)) Or Not IsNumeric(Arguments(i)) Then
            CSVFIELD = CsvFieldUsageRev03("Field numbers must be integers starting at 1.")
            Exit Function
        End If

        fieldIndex = CDbl(Arguments(i))
        If fieldIndex < 1 Or fieldIndex > 2147483647# Or fieldIndex <> Fix(fieldIndex) Then
            CSVFIELD = CsvFieldUsageRev03("Field numbers must be whole numbers from 1 to 2147483647.")
            Exit Function
        End If

        requestedFields(i - firstArgument + 1) = CLng(fieldIndex)
    Next i

    Set fields = ParseCsvFields(CStr(sourceValue), trimSpaces)
    If fields Is Nothing Then
        CSVFIELD = CsvFieldUsageRev03("CSV has an unclosed quote or parenthesis.")
        Exit Function
    End If

    For i = 1 To fieldCount
        If i > 1 Then combinedText = combinedText & separator
        combinedText = combinedText & CStr(CsvFieldValue(fields, requestedFields(i)))
        If Len(combinedText) > 32767 Then
            CSVFIELD = CsvFieldUsageRev03("Result exceeds Excel's 32767-character cell limit; select fewer fields.")
            Exit Function
        End If
    Next i

    CSVFIELD = combinedText
    Exit Function

InvalidArguments:
    CSVFIELD = CsvFieldUsageRev03("Check the source, field numbers and optional argument order.")
End Function

Private Function CsvFieldUsageRev03(ByVal reason As String) As String
    CsvFieldUsageRev03 = "CSVFIELD argument help: " & reason & vbLf _
        & "Syntax: =CSVFIELD(CsvText, Field1, [Field2...], [Trim], [Separator])" & vbLf _
        & "CsvText: text or ONE source cell, e.g. W2. Input delimiter is comma." & vbLf _
        & "Field1, Field2...: integers >= 1; repetitions and any order are allowed." & vbLf _
        & "Trim: TRUE removes outer spaces (default); FALSE preserves them." & vbLf _
        & "Separator: optional final text; default is comma. It joins the OUTPUT." & vbLf _
        & "Example: =CSVFIELD(W2,4)" & vbLf _
        & "Example: =CSVFIELD(W2,3,1,3,TRUE,"" | "")" & vbLf _
        & "Example: =CSVFIELD(W2,3,1,3,FALSE,""-"")" & vbLf _
        & "Use numeric field arguments such as 4, not quoted text such as ""4""."
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
