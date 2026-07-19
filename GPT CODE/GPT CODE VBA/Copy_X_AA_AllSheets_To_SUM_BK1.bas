Attribute VB_Name = "Copy_X_AA_AllSheets"
Option Explicit

Sub Copy_X_AA_AllSheets_To_SUM_BK1()

    Dim ws As Worksheet
    Dim wsSum As Worksheet
    Dim LastRow As Long
    Dim PasteRow As Long
    Dim StartRow As Long
    Dim r As Long
    Dim f As Range

    Set wsSum = ThisWorkbook.Worksheets("SUM BK1")

    wsSum.Range("A:E").UnMerge
    wsSum.Range("A:E").ClearContents

    PasteRow = 1

    For Each ws In ThisWorkbook.Worksheets

        If ws.Name <> wsSum.Name Then

            Set f = ws.Range("X:AA").Find( _
                What:="*", _
                LookIn:=xlFormulas, _
                SearchOrder:=xlByRows, _
                SearchDirection:=xlPrevious)

            If Not f Is Nothing Then

                LastRow = f.Row
                StartRow = PasteRow

                For r = 1 To LastRow

                    If Application.WorksheetFunction.CountA(ws.Range("X" & r & ":AA" & r)) > 0 Then

                        wsSum.Cells(PasteRow, "B").Resize(1, 4).Value = _
                            ws.Range("X" & r & ":AA" & r).Value

                        PasteRow = PasteRow + 1

                    End If

                Next r

                If PasteRow > StartRow Then

                    With wsSum.Range("A" & StartRow & ":A" & PasteRow - 1)
                        .Merge
                        .Value = ws.Name
                        .HorizontalAlignment = xlCenter
                        .VerticalAlignment = xlCenter
                    End With

                End If

            End If

            Set f = Nothing

        End If

    Next ws

End Sub
