;;; TA_HATCH_FROM_BOUNDARY.lsp
;;; LISP entry point for the managed hatch command.
;;;
;;; Commands:
;;;   TAHB / TAHATCHBOUNDARY - create associative hatch from closed boundaries
;;;   TAHATCHPRESETS         - list annotation-scale presets and config path

(vl-load-com)

;;; ================================================================
;;; PRESET MEMORY SETTINGS
;;;
;;; Current remembered values:
;;;   *TA-HB-LAST-PRESET-INDEX*   = main Preset number (0..N)
;;;   *TA-HB-LAST-FILTER-PATTERN* = Pattern Preset label for Preset 0
;;;
;;; The DEFAULT values are used only when no remembered value exists.
;;; The ENV names store the values in the AutoCAD profile so they remain
;;; available after AutoCAD is closed and opened again.
;;; ================================================================
(setq *TA-HB-DEFAULT-PRESET-INDEX* 1)
(setq *TA-HB-DEFAULT-FILTER-PATTERN* "ANSI35 x25")
(setq *TA-HB-PRESET-MEMORY-ENV* "TA_HB_LAST_PRESET_INDEX")
(setq *TA-HB-PATTERN-MEMORY-ENV* "TA_HB_LAST_FILTER_PATTERN")

;;; ================================================================
;;; USER PRESETS - edit this list to match your CAD standard.
;;;
;;; PATTERN-TYPE: "PreDefined", "CustomDefined" or "UserDefined"
;;; PATTERN     : (PATTERN "name" scale) keeps each pattern with its scale
;;; PATTERN-PRESETS item: ("label" "type" "name" scale angle-degrees)
;;; COLOR       : "BYLAYER", "BYBLOCK", "ACI:1" or "RGB:255,0,0"
;;; ANGLE       : degrees
;;; SCALES      : ("scale name" paper-units drawing-units)
;;; One preset may contain more than one annotation scale.
;;; ================================================================

;;; PRESET 0 - Uses the Layer Filter folder currently selected in Layer
;;; Properties Manager. It does not search for an existing Hatch. Pattern,
;;; annotation scales and color come from this preset; only Layer is resolved
;;; automatically from the Current Filter.
(setq *TA-HB-CURRENT-FILTER-PRESET*
  '("CURRENT FILTER - ANSI35"
    (SOURCE . "CURRENT-FILTER")
    (ANNOTATIVE . T)
    (SCALES
      ("1:1"  1.0 1.0)
      ("1:2"  1.0 2.0)
      ("1:5"  1.0 5.0)
      ("1:10" 1.0 10.0)
      ("1:15" 1.0 15.0)
      ("1:20" 1.0 20.0)
      ("1:25" 1.0 25.0)
      ("1:50" 1.0 50.0)
      ("1:75" 1.0 75.0)
      ("1:100" 1.0 100.0)
    )
    (PATTERN-PRESETS
      ("DOTS" "PreDefined" "DOTS" 0.10 0.0)
      ("ANSI31 x10" "PreDefined" "ANSI31" 0.10 0.0)
      ("ANSI32 x10" "PreDefined" "ANSI31" 0.10 0.0)
      ("C06 CUSTOM x1" "CustomDefined" "000_C06" 1.0 0.0)
      ("SOLID x1" "PreDefined" "SOLID" 1.0 0.0)
    )
    (LAYER . "CURRENT-FILTER")
    (COLOR . "BYLAYER")
  )
)

;;; Retains the last Pattern Preset while this AutoCAD session is open and
;;; persists it in the AutoCAD profile for the next session.
(if (not (boundp '*TA-HB-LAST-FILTER-PATTERN*))
  (setq *TA-HB-LAST-FILTER-PATTERN*
    (cond
      ((getenv *TA-HB-PATTERN-MEMORY-ENV*))
      (T *TA-HB-DEFAULT-FILTER-PATTERN*))))

;;; Retains the last main Preset number (0..N) and persists it in the
;;; AutoCAD profile. exchoice is also updated for compatibility with the
;;; user's earlier preset-memory code.
(if (not (boundp '*TA-HB-LAST-PRESET-INDEX*))
  (setq *TA-HB-LAST-PRESET-INDEX*
    (cond
      ((and (boundp 'exchoice)
            (member (type exchoice) '(INT REAL)))
        (fix exchoice))
      ((getenv *TA-HB-PRESET-MEMORY-ENV*)
        (atoi (getenv *TA-HB-PRESET-MEMORY-ENV*)))
      (T *TA-HB-DEFAULT-PRESET-INDEX*))))
(setq exchoice *TA-HB-LAST-PRESET-INDEX*)

(setq *TA-HB-PRESETS*
  '(
    ("C06 PANEL - 1:50"
      (ANNOTATIVE . T)
      (SCALES ("1:50" 1.0 50.0))
      (PATTERN-TYPE . "PreDefined")
      (PATTERN "ANSI35" 25.0)
      (PATTERN-ANGLE . 0.0)
      (LAYER . "009 - AHP_06_PANEL_HATCH_")
      (COLOR . "BYLAYER")
    )
    ("C06 CUSTOM - 1:50"
      (ANNOTATIVE . T)
      (SCALES ("1:50" 1.0 50.0))
      (PATTERN-TYPE . "CustomDefined")
      (PATTERN "000_C06" 1.0)
      (PATTERN-ANGLE . 0.0)
      (LAYER . "009 - AHP_06_PANEL_HATCH_")
      (COLOR . "BYLAYER")
    )
    ("GENERAL ANSI31 - 1:100"
      (ANNOTATIVE . T)
      (SCALES ("1:100" 1.0 100.0))
      (PATTERN-TYPE . "PreDefined")
      (PATTERN "ANSI31" 25.0)
      (PATTERN-ANGLE . 0.0)
      (LAYER . "HATCH")
      (COLOR . "ACI:8")
    )
    ("SOLID - NON ANNOTATIVE"
      (ANNOTATIVE . nil)
      (SCALES)
      (PATTERN-TYPE . "PreDefined")
      (PATTERN "SOLID" 1.0)
      (PATTERN-ANGLE . 0.0)
      (LAYER . "HATCH")
      (COLOR . "BYLAYER")
    )
    ("DETAIL ANSI31 - 1:20 + 1:50"
      (ANNOTATIVE . T)
      (SCALES ("1:20" 1.0 20.0) ("1:50" 1.0 50.0))
      (PATTERN-TYPE . "PreDefined")
      (PATTERN "ANSI31" 10.0)
      (PATTERN-ANGLE . 45.0)
      (LAYER . "HATCH-DETAIL")
      (COLOR . "RGB:255,0,0")
    )
  )
)

(defun TA-HB:get (key preset)
  (cdr (assoc key (cdr preset)))
)

;;; Preferred format: (PATTERN "name" scale)
;;; Legacy format remains supported:
;;;   (PATTERN . "name") (PATTERN-SCALE . scale)
(defun TA-HB:pattern-name (preset / data value)
  (setq data (assoc 'PATTERN (cdr preset))
        value (cdr data))
  (if (listp value) (car value) value)
)

(defun TA-HB:pattern-scale (preset / data value legacy)
  (setq data (assoc 'PATTERN (cdr preset))
        value (cdr data)
        legacy (TA-HB:get 'PATTERN-SCALE preset))
  (if (and (listp value) (cadr value))
    (cadr value)
    legacy)
)

(defun TA-HB:join (items separator / result item)
  (setq result "")
  (foreach item items
    (setq result
      (strcat result (if (= result "") "" separator) item))
  )
  result
)

(defun TA-HB:scale-names (preset / result scale)
  (setq result nil)
  (foreach scale (TA-HB:get 'SCALES preset)
    (setq result (append result (list (car scale)))))
  (if result (TA-HB:join result ", ") "Non-annotative")
)

(defun TA-HB:pack-scales (preset / result scale)
  (setq result nil)
  (foreach scale (TA-HB:get 'SCALES preset)
    (setq result
      (append result
        (list
          (strcat
            (car scale) "|"
            (rtos (cadr scale) 2 8) "|"
            (rtos (caddr scale) 2 8))))))
  (if result (TA-HB:join result ";") "")
)

(defun TA-HB:pack-pattern-presets (preset / result item)
  (setq result nil)
  (foreach item (TA-HB:get 'PATTERN-PRESETS preset)
    (setq result
      (append result
        (list
          (strcat
            (car item) "|"
            (cadr item) "|"
            (caddr item) "|"
            (rtos (cadddr item) 2 8) "|"
            (rtos (nth 4 item) 2 8))))))
  (if result (TA-HB:join result ";") "")
)

(defun TA-HB:pack-pattern-item (item)
  (strcat
    (nth 0 item) "|"
    (nth 1 item) "|"
    (nth 2 item) "|"
    (rtos (nth 3 item) 2 8) "|"
    (rtos (nth 4 item) 2 8))
)

(defun TA-HB:pattern-number-from-label (items label / index result item)
  (setq index 1
        result nil)
  (foreach item items
    (if (= (strcase (car item)) (strcase label))
      (setq result index))
    (setq index (1+ index)))
  result
)

;;; run_no is intentionally global. It retains the Hatch list number while
;;; AutoCAD is open. The selected label is also saved in the AutoCAD profile.
(defun TA-HB:choose-pattern-preset (/ items maximum index item selected)
  (setq items
    (TA-HB:get 'PATTERN-PRESETS *TA-HB-CURRENT-FILTER-PRESET*)
        maximum (length items))
  (if (or (not (boundp 'run_no))
          (not (member (type run_no) '(INT REAL)))
          (< run_no 1)
          (> run_no maximum))
    (setq run_no
      (cond
        ((TA-HB:pattern-number-from-label
           items *TA-HB-LAST-FILTER-PATTERN*))
        (1.0))))

  (princ "\nHatch presets:")
  (setq index 1)
  (foreach item items
    (princ
      (strcat
        "\n  " (itoa index)
        " = " (nth 0 item)
        " | Pattern: " (nth 2 item)
        " | Scale: " (rtos (nth 3 item) 2 8)
        " | Angle: " (rtos (nth 4 item) 2 8)))
    (setq index (1+ index)))

  (initget 6)
  (setq run_no
    (cond
      ((getint
         (strcat
           "\nspecify Hatch NUMBER\n<"
           (rtos (setq run_no (cond (run_no) (1.0))) 2 0)
           "> : ")))
      (run_no)))

  (if (and run_no (<= 1 run_no) (<= run_no maximum))
    (progn
      (setq selected (nth (1- (fix run_no)) items)
            *TA-HB-LAST-FILTER-PATTERN* (car selected))
      (setenv *TA-HB-PATTERN-MEMORY-ENV*
              *TA-HB-LAST-FILTER-PATTERN*)
      selected)
    (progn
      (princ "\nTAHB: หมายเลข Hatch ไม่ถูกต้อง.")
      nil))
)

(defun TA-HB:select-boundaries (/ filter selection)
  (setq filter
    '((0 . "LWPOLYLINE,POLYLINE,CIRCLE,ELLIPSE,SPLINE")))
  (setq selection (ssget "_I" filter))
  (if (not selection)
    (progn
      (princ "\nเลือก closed boundary: ")
      (setq selection (ssget filter))))
  selection
)

(defun TA-HB:print-preset (index preset)
  (princ
    (strcat
      "\n  " (itoa index) " = " (car preset)
      " | SC: " (TA-HB:scale-names preset)
      " | Hatch: " (TA-HB:pattern-name preset)
      " | Layer: " (TA-HB:get 'LAYER preset)
      " | Color: " (TA-HB:get 'COLOR preset)))
)

(defun TA-HB:list-presets (/ index preset)
  (princ "\nTA Hatch LISP presets:")
  (princ
    (strcat
      "\n  0 = " (car *TA-HB-CURRENT-FILTER-PRESET*)
      " | SC: " (TA-HB:scale-names *TA-HB-CURRENT-FILTER-PRESET*)
      " | Pattern presets: "
        (itoa (length (TA-HB:get 'PATTERN-PRESETS *TA-HB-CURRENT-FILTER-PRESET*)))
      " | Last: " *TA-HB-LAST-FILTER-PATTERN*
      " | Layer: CURRENT-FILTER"
      " | Color: " (TA-HB:get 'COLOR *TA-HB-CURRENT-FILTER-PRESET*)))
  (setq index 1)
  (foreach preset *TA-HB-PRESETS*
    (TA-HB:print-preset index preset)
    (setq index (1+ index)))
  (princ)
)

(defun TA-HB:choose-preset (/ index input choice maximum)
  (setq maximum (length *TA-HB-PRESETS*))
  (if (or (< *TA-HB-LAST-PRESET-INDEX* 0)
          (> *TA-HB-LAST-PRESET-INDEX* maximum))
    (setq *TA-HB-LAST-PRESET-INDEX* *TA-HB-DEFAULT-PRESET-INDEX*))
  (princ
    (strcat
      "\n  0 = " (car *TA-HB-CURRENT-FILTER-PRESET*)
      " | SC: " (TA-HB:scale-names *TA-HB-CURRENT-FILTER-PRESET*)
      " | Pattern presets: "
        (itoa (length (TA-HB:get 'PATTERN-PRESETS *TA-HB-CURRENT-FILTER-PRESET*)))
      " | Last: " *TA-HB-LAST-FILTER-PATTERN*
      " | Layer: CURRENT-FILTER"
      " | Color: " (TA-HB:get 'COLOR *TA-HB-CURRENT-FILTER-PRESET*)))
  (setq index 1)
  (foreach preset *TA-HB-PRESETS*
    (TA-HB:print-preset index preset)
    (setq index (1+ index)))
  (initget 4)
  (setq input
    (getint
      (strcat "\nspecify Hatch Preset <"
              (itoa *TA-HB-LAST-PRESET-INDEX*) "> : ")))
  (setq choice
    (if input input *TA-HB-LAST-PRESET-INDEX*))
  (cond
    ((= choice 0)
      (setq *TA-HB-LAST-PRESET-INDEX* choice
            exchoice choice)
      (setenv *TA-HB-PRESET-MEMORY-ENV* (itoa choice))
      'CURRENT-FILTER)
    ((and (<= 1 choice) (<= choice (length *TA-HB-PRESETS*)))
      (setq *TA-HB-LAST-PRESET-INDEX* choice
            exchoice choice)
      (setenv *TA-HB-PRESET-MEMORY-ENV* (itoa choice))
      (nth (1- choice) *TA-HB-PRESETS*))
    (T
      (princ "\nTAHB: หมายเลข preset ไม่ถูกต้อง.")
      nil)
  )
)

(defun TA-HB:send-preset (preset / result)
  (setq result
    (TA_HATCH_SET_LISP_PRESET_V6
      (car preset)
      (TA-HB:pattern-name preset)
      (TA-HB:get 'PATTERN-TYPE preset)
      (TA-HB:pattern-scale preset)
      (TA-HB:get 'PATTERN-ANGLE preset)
      (TA-HB:get 'LAYER preset)
      (TA-HB:get 'COLOR preset)
      (if (TA-HB:get 'ANNOTATIVE preset) 1 0)
      (TA-HB:pack-scales preset)))
  result
)

(defun TA-HB:send-current-filter-preset (pattern-item / preset result)
  (setq preset *TA-HB-CURRENT-FILTER-PRESET*)
  (setq result
    (TA_HATCH_SET_FILTER_PRESET_V6
      (car preset)
      (TA-HB:get 'COLOR preset)
      (if (TA-HB:get 'ANNOTATIVE preset) 1 0)
      (TA-HB:pack-scales preset)
      (TA-HB:pack-pattern-item pattern-item)
      (car pattern-item)))
  result
)

(defun TA-HB:remember-last-pattern (/ result)
  (setq result
    (vl-catch-all-apply 'TA_HATCH_GET_LAST_PATTERN_V6 '()))
  (if (and (not (vl-catch-all-error-p result))
           (eq (type result) 'STR))
    (progn
      (setq *TA-HB-LAST-FILTER-PATTERN* result)
      (setenv *TA-HB-PATTERN-MEMORY-ENV* result)))
  result
)

(defun TA-HB:root (/ here)
  (cond
    ((and (boundp '*TA-HB-ROOT*) *TA-HB-ROOT*) *TA-HB-ROOT*)
    ((setq here (findfile "TA_HATCH_FROM_BOUNDARY.lsp"))
      (vl-filename-directory here))
    ((findfile "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/GPT CODE/TA_HATCH_FROM_BOUNDARY/TA_HATCH_FROM_BOUNDARY.lsp")
      "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/GPT CODE/TA_HATCH_FROM_BOUNDARY")
    (T nil)
  )
)

(defun TA-HB:dll-path (/ root candidate)
  (setq root (TA-HB:root))
  (cond
    ((and root
          (setq candidate (strcat root "\\bin\\TA_HATCH_FROM_BOUNDARY_v6.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\bin\\TA_HATCH_FROM_BOUNDARY_v5.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\bin\\TA_HATCH_FROM_BOUNDARY_v4.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\bin\\TA_HATCH_FROM_BOUNDARY_v3.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\bin\\TA_HATCH_FROM_BOUNDARY_v2.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\bin\\TA_HATCH_FROM_BOUNDARY.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\TA_HATCH_FROM_BOUNDARY_v6.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\TA_HATCH_FROM_BOUNDARY_v5.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\TA_HATCH_FROM_BOUNDARY_v4.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\TA_HATCH_FROM_BOUNDARY_v3.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\TA_HATCH_FROM_BOUNDARY_v2.dll"))
          (findfile candidate))
      candidate)
    ((and root
          (setq candidate (strcat root "\\TA_HATCH_FROM_BOUNDARY.dll"))
          (findfile candidate))
      candidate)
    ((findfile "TA_HATCH_FROM_BOUNDARY_v6.dll"))
    ((findfile "TA_HATCH_FROM_BOUNDARY_v5.dll"))
    ((findfile "TA_HATCH_FROM_BOUNDARY_v4.dll"))
    ((findfile "TA_HATCH_FROM_BOUNDARY_v3.dll"))
    ((findfile "TA_HATCH_FROM_BOUNDARY_v2.dll"))
    ((findfile "TA_HATCH_FROM_BOUNDARY.dll"))
  )
)

(defun TA-HB:net-api-ready-p (/ result)
  ;; An older DLL may expose an earlier command but not the v6 command and
  ;; its matching LispFunction entry points.
  (and
    (getcname "TAHATCHBOUNDARYNET6")
    (not
      (vl-catch-all-error-p
        (setq result
          (vl-catch-all-apply 'TA_HATCH_CLEAR_LISP_PRESET_V6 '()))))
    result
  )
)

(defun TA-HB:ensure-net (/ path result old-dll-loaded)
  (cond
    ((TA-HB:net-api-ready-p) T)
    (T
      (setq old-dll-loaded
        (or (getcname "TAHATCHBOUNDARYNET5")
            (getcname "TAHATCHBOUNDARYNET4")
            (getcname "TAHATCHBOUNDARYNET3")
            (getcname "TAHATCHBOUNDARYNET2")
            (getcname "TAHATCHBOUNDARYNET")))
      (setq path (TA-HB:dll-path))
      (if (not path)
        (setq path
          (getfiled "Select TA_HATCH_FROM_BOUNDARY_v6.dll"
                    "TA_HATCH_FROM_BOUNDARY_v6.dll" "dll" 0)))
      (if path
        (setq result
          (vl-catch-all-apply 'vl-cmdf (list "_.NETLOAD" path))))
      (cond
        ((TA-HB:net-api-ready-p) T)
        (old-dll-loaded
          (princ
            "\nTAHB: AutoCAD is still using the old DLL. Close and restart AutoCAD, APPLOAD this LISP again, then run TAHB." )
          nil)
        (T
          (princ
            "\nTAHB: updated DLL was not loaded. Check TRUSTEDPATHS and the DLL path.")
          nil)
      )
    )
  )
)

(defun c:TAHATCHBOUNDARY (/ preset boundary-selection pattern-item)
  (if (TA-HB:ensure-net)
    (progn
      (TA_HATCH_CLEAR_LISP_PRESET_V6)
      (if (setq preset (TA-HB:choose-preset))
        (cond
          ((eq preset 'CURRENT-FILTER)
            (if (setq boundary-selection (TA-HB:select-boundaries))
              (if (setq pattern-item (TA-HB:choose-pattern-preset))
                (if (TA-HB:send-current-filter-preset pattern-item)
              (progn
                    (sssetfirst nil boundary-selection)
                    (vl-cmdf "_.TAHATCHBOUNDARYNET6")
                    (TA-HB:remember-last-pattern))))))
          ((TA-HB:send-preset preset)
            (vl-cmdf "_.TAHATCHBOUNDARYNET6"))
        )
      )
    )
    (princ "\nTAHB: TA Hatch .NET API is not ready."))
  (princ)
)

(defun c:TAHB ()
  (c:TAHATCHBOUNDARY)
)

(defun c:TAHATCHPRESETS ()
  (TA-HB:list-presets)
  (princ)
)

(princ "\nTA Hatch loaded. Type TAHB to create hatch. TAHATCHPRESETS lists presets.")
(princ)
