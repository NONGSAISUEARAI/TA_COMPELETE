Attribute VB_Name = "SET_PRINT_A4_LANDSCAPE"
Option Explicit

Public Sub SetPrintA4Landscape_ActiveSheet()
    With ActiveSheet.PageSetup
        .PrintArea = "$A$1:$V$45"
        .PaperSize = xlPaperA4
        .Orientation = xlLandscape

        .LeftMargin = Application.InchesToPoints(0.25)
        .RightMargin = Application.InchesToPoints(0.25)
        .TopMargin = Application.InchesToPoints(0.25)
        .BottomMargin = Application.InchesToPoints(0.25)
        .HeaderMargin = Application.InchesToPoints(0.1)
        .FooterMargin = Application.InchesToPoints(0.1)

        .Zoom = False
        .FitToPagesWide = 1
        .FitToPagesTall = 1
    End With
End Sub

Public Sub SetPrintA4Landscape_AllSheets()
    Dim ws As Worksheet

    Application.ScreenUpdating = False
    For Each ws In ThisWorkbook.Worksheets
        With ws.PageSetup
            .PrintArea = "$A$1:$V$45"
            .PaperSize = xlPaperA4
            .Orientation = xlLandscape

            .LeftMargin = Application.InchesToPoints(0.25)
            .RightMargin = Application.InchesToPoints(0.25)
            .TopMargin = Application.InchesToPoints(0.25)
            .BottomMargin = Application.InchesToPoints(0.25)
            .HeaderMargin = Application.InchesToPoints(0.1)
            .FooterMargin = Application.InchesToPoints(0.1)

            .Zoom = False
            .FitToPagesWide = 1
            .FitToPagesTall = 1
        End With
    Next ws
    Application.ScreenUpdating = True
End Sub
