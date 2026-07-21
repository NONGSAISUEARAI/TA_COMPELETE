Attribute VB_Name = "FormatBlankNonBlankModule"
Option Explicit

' Adds two Conditional Formatting rules to the active worksheet:
' 1. Non-blank cells = solid bottom border
' 2. Blank cells     = dotted light-gray bottom border
' Applies to every cell in the worksheet, as shown in Rules Manager.
Public Sub ApplyBlankNonBlankFormatting()

    Dim ws As Worksheet
    Dim targetRange As Range
    Dim nonBlankRule As FormatCondition
    Dim blankRule As FormatCondition

    Set ws = ActiveSheet
    Set targetRange = ws.Cells

    Set nonBlankRule = targetRange.FormatConditions.Add( _
        Type:=xlNoBlanksCondition)

    With nonBlankRule
        .SetFirstPriority
        .StopIfTrue = False

        With .Borders(xlBottom)
            .LineStyle = xlContinuous
            .Weight = xlThin
            .Color = RGB(0, 0, 0)
        End With
    End With

    Set blankRule = targetRange.FormatConditions.Add( _
        Type:=xlBlanksCondition)

    With blankRule
        .SetLastPriority
        .StopIfTrue = False

        With .Borders(xlBottom)
            .LineStyle = xlDot
            .Weight = xlThin
            .Color = RGB(191, 191, 191)
        End With
    End With

    MsgBox _
        "เพิ่ม Conditional Formatting เรียบร้อยแล้ว" & vbCrLf & _
        "Applies to: " & targetRange.Address, _
        vbInformation, _
        "Blank / Non-Blank Formatting"

End Sub

' Optional cleanup macro.
' Run this only when you intentionally want to remove every Conditional
' Formatting rule from the active worksheet.
Public Sub DeleteAllConditionalFormattingFromActiveSheet()

    If MsgBox( _
        "ต้องการลบ Conditional Formatting ทั้งหมดใน Sheet นี้หรือไม่?", _
        vbQuestion + vbYesNo + vbDefaultButton2, _
        "Confirm") <> vbYes Then Exit Sub

    ActiveSheet.Cells.FormatConditions.Delete

End Sub
