;;; Compatibility entry point. The loader now lives inside TA_LAYER_TRANSFER.
(setq *MAVP-ROOT* "C:/TA/TA_COMPELETE/GPT CODE/TA_LAYER_TRANSFER")
(if (findfile (strcat *MAVP-ROOT* "/Maviewport.lsp"))
  (load (strcat *MAVP-ROOT* "/Maviewport.lsp"))
  (princ "\nOpen the Maviewport.lsp inside your TA_LAYER_TRANSFER folder.")
)
(princ)
