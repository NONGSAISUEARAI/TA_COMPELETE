Attribute VB_Name = "A_PUB_ToggleFormulaPrefix"
Option Explicit

Public Sub ToggleFormulaPrefix()

    Dim targetCell As Range
    Dim formulaText As String

    Set targetCell = ActiveSheet.Range("AM2")

    With targetCell

        '¶éÒà»ç¹ÊÙµÃ ãËéà¾ÔèÁ Prefix à¾×èÍà»ÅÕèÂ¹à»ç¹¢éÍ¤ÇÒÁ
        If .HasFormula Then
            formulaText = .Formula2
            .Value2 = "'" & formulaText

        '¶éÒà»ç¹¢éÍ¤ÇÒÁ·Õè¢Öé¹µé¹´éÇÂ = ãËéà»ÅÕèÂ¹¡ÅÑºà»ç¹ÊÙµÃ
        ElseIf Left$(CStr(.Value2), 1) = "=" Then
            formulaText = CStr(.Value2)
            .Formula2 = formulaText

        End If

    End With

End Sub
