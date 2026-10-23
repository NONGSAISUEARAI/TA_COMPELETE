;;; Layer / viewport CSV transfer loader -- AutoCAD 2025+ on Windows.
;;; Package: Maviewport.lsp alongside bin/TA_LAYER_TRANSFER_v4.dll.
;;; *MAVP-ROOT* may be supplied by an external loader when relocating.

(defun TA:MAVP-FindDll (folder / candidate)
  (if (and folder (= (type folder) 'STR))
    (progn
      (setq candidate (findfile (strcat folder "/bin/TA_LAYER_TRANSFER_v4.dll")))
      (if (not candidate)
        (setq candidate (findfile (strcat folder "/TA_LAYER_TRANSFER_v4.dll")))
      )
      candidate
    )
  )
)

(defun TA:MAVP-Load (/ dll loader root fallback parent)
  (setq fallback "C:/TA/TA_COMPELETE/GPT CODE/TA_LAYER_TRANSFER")
  (cond
    ((< (atof (getvar "ACADVER")) 25.0)
      (princ "\nRequires AutoCAD 2025 or later.")
    )
    (T
      ;; 1. An explicitly supplied package directory.
      (if (and (boundp '*MAVP-ROOT*) (TA:MAVP-FindDll *MAVP-ROOT*))
        (setq root *MAVP-ROOT* dll (TA:MAVP-FindDll root))
      )
      ;; 2. The LSP found on AutoCAD's search paths, if available.
      (if (and (not dll) (setq loader (findfile "Maviewport.lsp")))
        (setq root (vl-filename-directory loader)
              dll (TA:MAVP-FindDll root))
      )
      ;; 3. The package directory explicitly supplied for this installation.
      ;; APPLOAD alone does not make an arbitrary folder searchable by findfile.
      (if (not dll)
        (setq root fallback dll (TA:MAVP-FindDll root))
      )
      (if (not dll)
        (setq dll (getfiled "Locate TA_LAYER_TRANSFER_v4.dll"
                           (strcat root "/bin/") "dll" 0))
      )
      (if dll
        (progn
          (setq parent (vl-filename-directory dll))
          (if (= (strcase (vl-filename-base parent)) "BIN")
            (setq root (vl-filename-directory parent))
            (setq root parent)
          )
          (setq *MAVP-ROOT* root *MAVP-DLL* dll)
          (command "_.NETLOAD" dll)
          (princ (strcat "\nLayer transfer DLL: " dll))
          (princ "\nLayer CSV commands: MAVPEXPORT / MAVPIMPORT")
        )
        (princ "\nTA_LAYER_TRANSFER_v4.dll not found. Load cancelled.")
      )
    )
  )
  (princ)
)

(TA:MAVP-Load)
(princ)
