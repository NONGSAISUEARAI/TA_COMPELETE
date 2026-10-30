;;; TA_FILTER_FROM_OBJECT.lsp
;;; Pick a nested object, read its layer, and select its matching Layer Filter
;;; folder in AutoCAD's Layer Properties Manager. The companion .NET DLL does
;;; the LayerFilterTree.Current update; this LISP supplies the nentsel pick.
;;;
;;; Commands: TAHF (or TAFILTERFROMOBJECT), TAFILTERLAYERS
;;; (TA-FFO:current-filter-layers) returns a Lisp list of direct member names.
;;; TAFILTERLAYERS also stores that list in TA-FFO:last-filter-layers.

(vl-load-com)

(defun TA-FFO:ensure-net (/ path result)
  (if (getcname "TAFILTERFROMOBJECTNET")
    T
    (progn
      (setq path
        (or
          (findfile "TA_FILTER_FROM_OBJECT.dll")
          (getfiled "Select TA_FILTER_FROM_OBJECT.dll"
                    "TA_FILTER_FROM_OBJECT.dll" "dll" 0)
        )
      )
      (if path
        (progn
          (setq result
            (vl-catch-all-apply 'vl-cmdf (list "_.NETLOAD" path))
          )
          (and (not (vl-catch-all-error-p result))
               (getcname "TAFILTERFROMOBJECTNET"))
        )
      )
    )
  )
)

(defun TA-FFO:picked-layer (pick / data layer parent candidate)
  (setq data (entget (car pick)))
  (setq layer (cdr (assoc 8 data)))
  ;; A nested entity on Layer 0 inherits the first non-zero INSERT layer.
  ;; nentsel returns container INSERTs from the innermost to the outermost.
  (if (and layer (= (strcase layer) "0") (cadddr pick))
    (foreach parent (cadddr pick)
      (if (= (strcase layer) "0")
        (progn
          (setq candidate (cdr (assoc 8 (entget parent))))
          (if (and candidate (/= (strcase candidate) "0"))
            (setq layer candidate)
          )
        )
      )
    )
  )
  layer
)

(defun c:TAFILTERFROMOBJECT (/ pick data raw layer)
  (if (setq pick (nentsel "\nPick object to find its Layer Filter folder: "))
    (progn
      (setq data (entget (car pick))
            raw (cdr (assoc 8 data))
            layer (TA-FFO:picked-layer pick))
      (if layer
        (progn
          (princ (strcat "\nObject layer: " raw))
          (if (/= (strcase raw) (strcase layer))
            (princ (strcat "\nInherited block layer: " layer))
          )
          (if (TA-FFO:ensure-net)
            (vl-cmdf "TAFILTERFROMOBJECTNET" layer)
            (princ "\nTAHF: .NET command unavailable. Load TA_FILTER_FROM_OBJECT.dll from a trusted location.")
          )
        )
        (princ "\nTAHF: the picked entity has no readable layer.")
      )
    )
  )
  (princ)
)

(defun c:TAHF ()
  (c:TAFILTERFROMOBJECT)
)

(defun TA-FFO:current-filter-layers ()
  (if (and (TA-FFO:ensure-net)
           (getcname "TAFILTERLAYERSNET"))
    (TA_GET_CURRENT_FILTER_LAYERS)
  )
)

(defun c:TAFILTERLAYERS ()
  (if (and (TA-FFO:ensure-net)
           (getcname "TAFILTERLAYERSNET"))
    (progn
      (setq TA-FFO:last-filter-layers
        (TA_GET_CURRENT_FILTER_LAYERS))
      (vl-cmdf "TAFILTERLAYERSNET")
    )
    (princ "\nTAHF: updated .NET command unavailable. Restart AutoCAD, then load the new TA_FILTER_FROM_OBJECT.dll.")
  )
  (princ)
)

(princ "\nTA_FILTER_FROM_OBJECT loaded. TAHF picks an object; TAFILTERLAYERS lists the current Group Filter's layers.")
(princ)
