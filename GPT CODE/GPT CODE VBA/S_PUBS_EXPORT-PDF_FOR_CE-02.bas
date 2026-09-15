Attribute VB_Name = "S_PUBS_EXPORT_PDF_FOR_CE_02"
Option Explicit

' Export ActiveSheet using the original workbook name.
' Example: Project Name.xlsm -> Project Name.pdf
Public Sub TA_T_PDFActiveSheet()
    ExportActiveSheetToPDF ""
End Sub

' Export ActiveSheet with _OVL appended to the original workbook name.
' Example: Project Name.xlsm -> Project Name_OVL.pdf
Public Sub TA_T_OVL_PDFActiveSheet()
    ExportActiveSheetToPDF "_OVL"
End Sub

' Export selected sheet(s) with a file name built from T1, D1, and C4.
' Example: T1 = PP20, D1 = ใบขอตัวอย่างโครงการ, C4 = SAMPLE-01
' Result: PP20_ใบขอตัวอย่างโครงการ_SAMPLE-01.pdf
Public Sub TA_T_PROJECT_SAMPLE_PDFActiveSheet()
    Dim wsA As Worksheet
    Dim wbA As Workbook
    Dim strPath As String
    Dim strFile As String
    Dim strPathFile As String
    Dim value_prefix_1 As String, value_prefix_2 As String, value_prefix_3 As String
    Dim myFile As Variant

    On Error GoTo errHandler

    Set wbA = ActiveWorkbook
    Set wsA = ActiveSheet

    value_prefix_1 = Trim$(CStr(wsA.Range("T1").Value2))
    value_prefix_2 = "_" & Trim$(CStr(wsA.Range("D1").Value2)) & "_"
    value_prefix_3 = Trim$(CStr(wsA.Range("C4").Value2))

    If Len(value_prefix_1) = 0 _
        Or Len(Trim$(CStr(wsA.Range("D1").Value2))) = 0 _
        Or Len(value_prefix_3) = 0 Then

        MsgBox _
            "ไม่สามารถสร้างชื่อไฟล์ได้ เพราะ T1, D1 หรือ C4 ไม่มีข้อมูล", _
            vbExclamation, _
            "Export PDF"
        Exit Sub
    End If

    strFile = CleanPDFFileName( _
        value_prefix_1 & value_prefix_2 & value_prefix_3) & ".pdf"

    strPath = wbA.Path
    If Len(strPath) = 0 Then
        strPath = Application.DefaultFilePath
    End If

    strPathFile = strPath & Application.PathSeparator & strFile

    myFile = Application.GetSaveAsFilename( _
        InitialFileName:=strPathFile, _
        FileFilter:="PDF Files (*.pdf), *.pdf", _
        Title:="Select Folder and File Name to Save")

    If VarType(myFile) = vbBoolean Then
        If myFile = False Then GoTo exitHandler
    End If

    ExportSelectedSheetsAsPDF wbA, CStr(myFile)

    MsgBox _
        "TA & T : PDF file has been created:" & vbCrLf & CStr(myFile), _
        vbInformation, _
        "Export PDF"

exitHandler:
    Exit Sub

errHandler:
    MsgBox _
        "Could not create PDF file." & vbCrLf & _
        "Error " & Err.Number & ": " & Err.Description, _
        vbExclamation, _
        "Export PDF"
    Resume exitHandler
End Sub

Private Sub ExportActiveSheetToPDF(ByVal FileSuffix As String)
    Dim wsA As Worksheet
    Dim wbA As Workbook
    Dim strPath As String
    Dim strBaseName As String
    Dim strFile As String
    Dim strPathFile As String
    Dim myFile As Variant

    On Error GoTo errHandler

    Set wbA = ActiveWorkbook
    Set wsA = ActiveSheet

    ' Use the workbook folder when saved; otherwise use Excel's default folder.
    strPath = wbA.Path
    If Len(strPath) = 0 Then
        strPath = Application.DefaultFilePath
    End If

    ' Remove only the final workbook extension.
    ' Spaces and periods inside the original file name are preserved.
    strBaseName = FileNameWithoutExtension(wbA.Name)
    strFile = strBaseName & FileSuffix & ".pdf"
    strPathFile = strPath & Application.PathSeparator & strFile

    myFile = Application.GetSaveAsFilename( _
        InitialFileName:=strPathFile, _
        FileFilter:="PDF Files (*.pdf), *.pdf", _
        Title:="Select Folder and File Name to Save")

    ' GetSaveAsFilename returns Boolean False when the user presses Cancel.
    If VarType(myFile) = vbBoolean Then
        If myFile = False Then GoTo exitHandler
    End If

    ExportSelectedSheetsAsPDF wbA, CStr(myFile)

    MsgBox _
        "TA & T : PDF file has been created:" & vbCrLf & CStr(myFile), _
        vbInformation, _
        "Export PDF"

exitHandler:
    Exit Sub

errHandler:
    MsgBox _
        "Could not create PDF file." & vbCrLf & _
        "Error " & Err.Number & ": " & Err.Description, _
        vbExclamation, _
        "Export PDF"
    Resume exitHandler
End Sub

Private Sub ExportSelectedSheetsAsPDF( _
    ByVal SourceWorkbook As Workbook, _
    ByVal PDFFileName As String)

    Dim temporaryWorkbook As Workbook
    Dim selectedSheetCount As Long
    Dim savedErrorNumber As Long
    Dim savedErrorDescription As String

    On Error GoTo exportError

    selectedSheetCount = ActiveWindow.SelectedSheets.Count

    If selectedSheetCount = 1 Then
        ActiveSheet.ExportAsFixedFormat _
            Type:=xlTypePDF, _
            Filename:=PDFFileName, _
            Quality:=xlQualityStandard, _
            IncludeDocProperties:=True, _
            IgnorePrintAreas:=False, _
            OpenAfterPublish:=False
    Else
        ' Copy all grouped sheets to a temporary workbook so that Excel
        ' exports them into one PDF in workbook-tab order.
        ActiveWindow.SelectedSheets.Copy
        Set temporaryWorkbook = ActiveWorkbook

        temporaryWorkbook.ExportAsFixedFormat _
            Type:=xlTypePDF, _
            Filename:=PDFFileName, _
            Quality:=xlQualityStandard, _
            IncludeDocProperties:=True, _
            IgnorePrintAreas:=False, _
            OpenAfterPublish:=False

        Application.DisplayAlerts = False
        temporaryWorkbook.Close SaveChanges:=False
        Application.DisplayAlerts = True
        SourceWorkbook.Activate
    End If

    Exit Sub

exportError:
    savedErrorNumber = Err.Number
    savedErrorDescription = Err.Description

    On Error Resume Next
    Application.DisplayAlerts = False

    If Not temporaryWorkbook Is Nothing Then
        temporaryWorkbook.Close SaveChanges:=False
    End If

    Application.DisplayAlerts = True
    SourceWorkbook.Activate
    On Error GoTo 0

    Err.Raise savedErrorNumber, _
        "ExportSelectedSheetsAsPDF", savedErrorDescription
End Sub

Private Function FileNameWithoutExtension( _
    ByVal FullFileName As String) As String

    Dim dotPosition As Long

    dotPosition = InStrRev(FullFileName, ".")

    If dotPosition > 1 Then
        FileNameWithoutExtension = Left$(FullFileName, dotPosition - 1)
    Else
        FileNameWithoutExtension = FullFileName
    End If
End Function

Private Function CleanPDFFileName(ByVal FileName As String) As String
    Dim invalidCharacters As Variant
    Dim character As Variant

    invalidCharacters = Array("\", "/", ":", "*", "?", """", "<", ">", "|")

    For Each character In invalidCharacters
        FileName = Replace(FileName, CStr(character), "_")
    Next character

    CleanPDFFileName = Trim$(FileName)
End Function
