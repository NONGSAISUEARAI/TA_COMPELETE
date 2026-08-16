Attribute VB_Name = "S_FUNC_PACK_MULTI_v3_1"
Option Explicit

' Compatibility wrapper. PACK_MULTI_v3_2 is the standalone implementation.
Public Function PACK_MULTI_v3_1( _
    ByVal ValueRange As Range, _
    ByVal QtyRange As Range, _
    ByVal targetRange As Range, _
    ByVal TargetQtyRange As Range, _
    ByVal TargetWasteRange As Range, _
    Optional ByVal MaxItemsPerStock As Long = 8, _
    Optional ByVal Allowance As Double = 5, _
    Optional ByVal MaxSearchNodes As Long = 50000) As Variant

    PACK_MULTI_v3_1 = PACK_MULTI_v3_2( _
        ValueRange, QtyRange, targetRange, TargetQtyRange, _
        TargetWasteRange, MaxItemsPerStock, Allowance, MaxSearchNodes)
End Function
