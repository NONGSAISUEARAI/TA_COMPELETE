Attribute VB_Name = "S_FUNC_Pack_Summary_v3_1"
Option Explicit

' Compatibility wrapper. PACK_SUMMARY_v3_2 is the standalone implementation.
Public Function PACK_SUMMARY_v3_1( _
    ByVal ResultRange As Range, _
    ByVal SourceLengthRange As Range, _
    ByVal SourceQtyRange As Range, _
    Optional ByVal ItemListRowOffset As Long = 18) As Variant

    PACK_SUMMARY_v3_1 = PACK_SUMMARY_v3_2( _
        ResultRange, SourceLengthRange, SourceQtyRange, ItemListRowOffset)
End Function
